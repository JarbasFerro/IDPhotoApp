import CoreGraphics
import CoreImage
import Darwin
import Foundation
import ImageIO
import Vision

actor ImagePipeline {
    static let outputWidth = 900
    static let outputHeight = 1200

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

        guard let sourceCGImage = context.createCGImage(normalizedSource, from: normalizedExtent) else {
            throw PipelineError.cannotCreateCGImage
        }

        let handler = ImageRequestHandler(sourceCGImage, orientation: .up)

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
        let sourceForRender = CIImage(cgImage: sourceCGImage)
        let maskForRender = fittedMask(
            CIImage(cvPixelBuffer: scaledMaskBuffer),
            to: sourceForRender.extent
        )

        let whiteBackground = CIImage(
            color: CIColor(red: 1, green: 1, blue: 1, alpha: 1)
        ).cropped(to: sourceForRender.extent)
        let composited = sourceForRender.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: whiteBackground,
                kCIInputMaskImageKey: maskForRender
            ]
        )

        let crop = SpikeCropSolver.cropRect(
            sourceExtent: sourceForRender.extent,
            normalizedFaceBoundingBox: primaryFaceRect,
            targetAspectRatio: CGFloat(Self.outputWidth) / CGFloat(Self.outputHeight)
        )
        let exactOutput = exactRender(
            image: composited,
            crop: crop,
            outputWidth: Self.outputWidth,
            outputHeight: Self.outputHeight
        )

        let outputDirectory = try makeOutputDirectory()
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
            normalizedSourceWidth: sourceCGImage.width,
            normalizedSourceHeight: sourceCGImage.height,
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
                "Automatic person segmentation is the core path. iOS 27 iterative segmentation is recorded as an availability/refinement probe.",
                "No source photo is persisted by the app; only the rendered JPEG and JSON evidence are written to the temporary directory."
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(report).write(to: reportURL, options: .atomic)

        return PipelineResult(exportURL: exportURL, reportURL: reportURL, report: report)
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
            try await request.downloadAssets()
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

    private func makeOutputDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("M1PipelineSpike", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
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
