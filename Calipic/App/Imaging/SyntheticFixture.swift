#if DEBUG
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Generated geometry fixture; contains no photograph or personal data.
enum SyntheticFixture {
    static let defaultPalette: [CGColor] = [CGColor(red: 1, green: 0, blue: 0, alpha: 1),
        CGColor(red: 0, green: 1, blue: 0, alpha: 1),
        CGColor(red: 0, green: 0, blue: 1, alpha: 1),
        CGColor(red: 1, green: 1, blue: 0, alpha: 1)]

    /// `palette` colours the four quadrants (top-left, top-right, bottom-left, bottom-right).
    @concurrent
    static func staged(width: Int = 800, height: Int = 1_000, orientation: Int = 1,
                       encoding: UTType = .jpeg, wideGamut: Bool = false,
                       palette: [CGColor] = defaultPalette) async throws -> StagedPhoto {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IDPhotoIncoming").appendingPathComponent(UUID().uuidString)
        try PhotoFiles.createPrivateDirectory(directory)
        let result = StagedPhoto(directory: directory)
        guard let space = CGColorSpace(name: wideGamut ? CGColorSpace.displayP3 : CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                  bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw PhotoError.renderFailed
        }
        let colors = palette.count == 4 ? palette : defaultPalette
        for index in 0..<4 {
            context.setFillColor(colors[index])
            context.fill(CGRect(x: (index % 2) * width / 2, y: (index / 2) * height / 2,
                                width: width / 2, height: height / 2))
        }
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(result.url as CFURL,
                  encoding.identifier as CFString, 1, nil) else { throw PhotoError.renderFailed }
        CGImageDestinationAddImage(destination, image, [
            kCGImagePropertyOrientation: orientation,
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 1, kCGImagePropertyGPSLatitudeRef: "N"],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "Synthetic test metadata"],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: "Synthetic fixture"]
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoError.renderFailed }
        try PhotoFiles.protect(result.url)
        return result
    }
}

/// A real portrait kept outside git (`test_data/local/`, ignored), so looks can be judged with a face on a simulator.
/// Simulator builds on the developer's Mac only: nothing here reaches a device or a release build.
enum LocalPortrait {
    /// Face landmarks for the portrait, read from `portrait.json` beside it, because Vision cannot run on a simulator.
    /// Points are normalized with a top-left origin. `leftEye` is the subject's left, on the image's right.
    struct Face: Decodable, Sendable {
        let leftEye: [Double]
        let rightEye: [Double]
        let chin: [Double]
        let crown: [Double]
    }

    private static var folder: URL? {
        #if targetEnvironment(simulator)
        // .../Calipic/App/Imaging/SyntheticFixture.swift -> the repository root.
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<4 { root.deleteLastPathComponent() }
        return root.appendingPathComponent("test_data/local")
        #else
        return nil
        #endif
    }

    static var url: URL? {
        guard !ProcessInfo.processInfo.arguments.contains("--uitesting-synthetic-only"),
              let url = folder?.appendingPathComponent("portrait.jpg"),
              FileManager.default.isReadableFile(atPath: url.path) else { return nil }
        return url
    }

    static var face: Face? {
        guard url != nil, let file = folder?.appendingPathComponent("portrait.json"),
              let data = try? Data(contentsOf: file),
              let face = try? JSONDecoder().decode(Face.self, from: data),
              [face.leftEye, face.rightEye, face.chin, face.crown].allSatisfy({ $0.count == 2 }) else { return nil }
        return face
    }
}
#endif
