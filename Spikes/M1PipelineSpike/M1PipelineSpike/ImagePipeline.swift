import CoreGraphics
import CoreImage
import Darwin
import Foundation
import ImageIO
import Vision

actor ImagePipeline {
    static let outputWidth = 900
    static let outputHeight = 1200
    static let analysisMaximumPixelSize = 2048

    private let context = CIContext(options: [.cacheIntermediates: true])

    func process(
        _ captured: CapturedPhoto,
        cameraEntryToPreviewMilliseconds: Double?
    ) async throws -> PipelineResult {
        let pipelineStart = ContinuousClock.now

        guard let sourceImage = CIImage(
            data: captured.data,
            options: [.applyOrientationProperty: true]
        ) else {
            throw PipelineError.cannotDecodeCapture
        }

        let translatedSource = sourceImage.transformed(by: CGAffineTransform(
            translationX: -sourceImage.extent.minX,
            y: -sourceImage.extent.minY
        ))
        let normalizedExtent = CGRect(
            x: 0,
            y: 0,
            width: translatedSource.extent.width.rounded(.down),
            height: translatedSource.extent.height.rounded(.down)
        )
        let normalizedSource = translatedSource.cropped(to: normalizedExtent)
        let analysisCGImage = try makeAnalysisImage(from: captured.data)
        let handler = ImageRequestHandler(analysisCGImage, orientation: .up)

        let faceStart = ContinuousClock.now
        let faces = try await handler.perform(DetectFaceRectanglesRequest())
        let faceMilliseconds = milliseconds(since: faceStart)
        guard let primaryFace = faces.max(by: {
            area($0.boundingBox.cgRect) < area($1.boundingBox.cgRect)
        }) else {
            throw PipelineError.noFace
        }

        let primaryFaceRect = primaryFace.boundingBox.cgRect
        let faceCenter = NormalizedPoint(x: primaryFaceRect.midX, y: primaryFaceRect.midY)

        let segmentationStart = ContinuousClock.now
        guard let personObservation = try await handler.perform(GeneratePersonInstanceMaskRequest()) else {
            throw PipelineError.noPersonMask
        }
        let selectedInstances = personObservation.instanceAtPoint(faceCenter)
        let instances = selectedInstances.isEmpty ? personObservation.allInstances : selectedInstances
        guard !instances.isEmpty else {
            throw PipelineError.noPersonMask
        }
        let scaledMaskBuffer = try personObservation.generateScaledMask(
            for: instances,
            scaledToImageFrom: handler
        )
        let segmentationMilliseconds = milliseconds(since: segmentationStart)

        let iterativeEvidence = await probeIterativeSegmentation(
            handler: handler,
            seedPoint: faceCenter
        )

        let renderStart = ContinuousClock.now
        let maskForRender = fittedMask(
            CIImage(cvPixelBuffer: scaledMaskBuffer),
            to: normalizedSource.extent
        )

        let whiteBackground = CIImage(
            color: CIColor(red: 1, green: 1, blue: 1, alpha: 1)
        ).cropped(to: normalizedSource.extent)
        let composited = normalizedSource.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: whiteBackground,
                kCIInputMaskImageKey: maskForRender
            ]
        )

        let crop = SpikeCropSolver.cropRect(
            sourceExtent: normalizedSource.extent,
            normalizedFaceBoundingBox: primaryFaceRect,
            targetAspectRatio: CGFloat(Self.outputWidth) / CGFloat(Self.outputHeight)
        )
        let exactOutput = exactRender(
            image: composited,
            crop: crop,
            outputWidth: Self.outputWidth,
            outputHeight: Self.outputHeight
        )

        let outputDirectory = try resetOutputDirectory()
        let runID = UUID().uuidString.lowercased()
        let exportURL = outputDirectory.appendingPathComponent("m1-\(runID).jpg")
        let reportURL = outputDirectory.appendingPathComponent("m1-\(runID)-evidence.json")

        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw PipelineError.cannotCreateSRGB
        }
        let qualityKey = kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption
        try context.writeJPEGRepresentation(
            of: exactOutput,
            to: exportURL,
            colorSpace: sRGB,
            options: [qualityKey: 0.95]
        )
        try protectFile(at: exportURL)

        let verification = try ExportVerifier.verifyJPEG(
            at: exportURL,
            expectedWidth: Self.outputWidth,
            expectedHeight: Self.outputHeight
        )
        let renderAndExportMilliseconds = milliseconds(since: renderStart)

        let report = SpikeRunReport(
            schemaVersion: 1,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            hardwareIdentifier: Self.hardwareIdentifier(),
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
            requestedCaptureWidth: captured.requestedWidth,
            requestedCaptureHeight: captured.requestedHeight,
            resolvedCaptureWidth: captured.resolvedWidth,
            resolvedCaptureHeight: captured.resolvedHeight,
            cameraEntryToPreviewMilliseconds: cameraEntryToPreviewMilliseconds,
            captureMilliseconds: captured.captureMilliseconds,
            normalizedSourceWidth: Int(normalizedExtent.width),
            normalizedSourceHeight: Int(normalizedExtent.height),
            analysisWidth: analysisCGImage.width,
            analysisHeight: analysisCGImage.height,
            analysisMaximumPixelSize: Self.analysisMaximumPixelSize,
            faceCount: faces.count,
            primaryFaceBoundingBox: [
                Double(primaryFaceRect.origin.x),
                Double(primaryFaceRect.origin.y),
                Double(primaryFaceRect.width),
                Double(primaryFaceRect.height)
            ],
            faceDetectionMilliseconds: faceMilliseconds,
            personSegmentationMilliseconds: segmentationMilliseconds,
            iterativeSegmentationStatus: iterativeEvidence.status,
            iterativeSegmentationMilliseconds: iterativeEvidence.milliseconds,
            renderAndExportMilliseconds: renderAndExportMilliseconds,
            totalPipelineMilliseconds: milliseconds(since: pipelineStart),
            exportVerification: verification,
            notes: [
                "M1 spike crop is intentionally non-official and exists only to prove deterministic render/export.",
                "Vision analysis is ImageIO-downsampled to a maximum 2048 px edge; the final Core Image render uses the orientation-normalized full source.",
                "Automatic person segmentation is the core path. iOS 27 iterative segmentation is recorded as an availability/refinement probe.",
                "No source photo is persisted by the app; only the newest rendered JPEG and JSON evidence are retained in the protected temporary directory."
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(report).write(to: reportURL, options: .atomic)
        try protectFile(at: reportURL)

        return PipelineResult(exportURL: exportURL, reportURL: reportURL, report: report)
    }

    private func makeAnalysisImage(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw PipelineError.cannotDecodeCapture
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.analysisMaximumPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PipelineError.cannotCreateAnalysisImage
        }
        return image
    }

    private func probeIterativeSegmentation(
        handler: ImageRequestHandler,
        seedPoint: NormalizedPoint
    ) async -> (status: String, milliseconds: Double?) {
        guard #available(iOS 27.0, *) else {
            return ("not available below iOS 27", nil)
        }

        let start = ContinuousClock.now
        let request = GenerateIterativeSegmentationRequest(seedPoint: seedPoint)
        do {
            switch await request.assetStatus {
            case .ready:
                break
            case .notReady, .downloading:
                try await request.downloadAssets()
            case .error(let error):
                throw error
            @unknown default:
                try await request.downloadAssets()
            }

            let result = try await handler.perform(request)
            return (
                result == nil ? "iOS 27 request completed with no mask" : "iOS 27 iterative mask generated",
                milliseconds(since: start)
            )
        } catch {
            return ("iOS 27 iterative probe failed: \(String(describing: error))", milliseconds(since: start))
        }
    }

    private func fittedMask(_ mask: CIImage, to extent: CGRect) -> CIImage {
        guard mask.extent.width > 0, mask.extent.height > 0 else { return mask }
        let normalized = mask.transformed(by: CGAffineTransform(
            translationX: -mask.extent.minX,
            y: -mask.extent.minY
        ))
        let scaled = normalized.transformed(by: CGAffineTransform(
            scaleX: extent.width / normalized.extent.width,
            y: extent.height / normalized.extent.height
        ))
        return scaled.cropped(to: extent)
    }

    private func exactRender(
        image: CIImage,
        crop: CGRect,
        outputWidth: Int,
        outputHeight: Int
    ) -> CIImage {
        let cropped = image.cropped(to: crop)
        let originNormalized = cropped.transformed(by: CGAffineTransform(
            translationX: -crop.minX,
            y: -crop.minY
        ))
        let scaled = originNormalized.transformed(by: CGAffineTransform(
            scaleX: CGFloat(outputWidth) / crop.width,
            y: CGFloat(outputHeight) / crop.height
        ))
        return scaled.cropped(to: CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))
    }

    private func resetOutputDirectory() throws -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("M1PipelineSpike", isDirectory: true)

        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUnlessOpen],
            ofItemAtPath: directory.path
        )
        return directory
    }

    private func protectFile(at url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUnlessOpen],
            ofItemAtPath: url.path
        )
    }

    private static func hardwareIdentifier() -> String {
        var size = 0
        guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0, size > 0 else {
            return "unknown"
        }

        var machine = [CChar](repeating: 0, count: size)
        let result = machine.withUnsafeMutableBufferPointer { buffer in
            sysctlbyname("hw.machine", buffer.baseAddress, &size, nil, 0)
        }
        guard result == 0 else { return "unknown" }
        return String(cString: machine)
    }
}

enum SpikeCropSolver {
    static func cropRect(
        sourceExtent: CGRect,
        normalizedFaceBoundingBox: CGRect,
        targetAspectRatio: CGFloat
    ) -> CGRect {
        precondition(targetAspectRatio > 0)

        var cropWidth = sourceExtent.width
        var cropHeight = cropWidth / targetAspectRatio
        if cropHeight > sourceExtent.height {
            cropHeight = sourceExtent.height
            cropWidth = cropHeight * targetAspectRatio
        }

        let faceCenterX = sourceExtent.minX + normalizedFaceBoundingBox.midX * sourceExtent.width
        let faceCenterY = sourceExtent.minY + normalizedFaceBoundingBox.midY * sourceExtent.height

        let idealX = faceCenterX - cropWidth / 2
        let idealY = faceCenterY - cropHeight / 2
        let x = min(max(idealX, sourceExtent.minX), sourceExtent.maxX - cropWidth)
        let y = min(max(idealY, sourceExtent.minY), sourceExtent.maxY - cropHeight)

        return CGRect(x: x, y: y, width: cropWidth, height: cropHeight).integral
    }
}

private func area(_ rect: CGRect) -> CGFloat {
    rect.width * rect.height
}
