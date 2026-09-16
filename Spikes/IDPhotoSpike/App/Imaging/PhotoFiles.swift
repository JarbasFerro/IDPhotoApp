import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Owns a file copy because the picker provider's URL is valid only during transfer.
struct StagedPhoto: Transferable, Sendable {
    let directory: URL
    var url: URL { directory.appendingPathComponent("source") }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            try await stage(received.file)
        }
    }

    @concurrent
    static func stage(_ source: URL) async throws -> StagedPhoto {
        try Task.checkCancellation()
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("IDPhotoIncoming")
        let directory = root.appendingPathComponent(UUID().uuidString)
        try PhotoFiles.createPrivateDirectory(directory)
        do {
            let result = StagedPhoto(directory: directory)
            // Request only size; do not read a general dictionary containing file timestamps.
            let values = try source.resourceValues(forKeys: [.fileSizeKey])
            guard let size = values.fileSize else { throw PhotoError.unreadable }
            guard size <= 150_000_000 else {
                throw PhotoError.tooLarge
            }
            try FileManager.default.copyItem(at: source, to: result.url)
            try PhotoFiles.protect(result.url)
            try Task.checkCancellation()
            return result
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }
}

extension StagedPhoto {
    /// Stages captured photo data (HEIF or JPEG) exactly like an imported file.
    @concurrent
    static func stage(data: Data) async throws -> StagedPhoto {
        try Task.checkCancellation()
        guard !data.isEmpty, data.count <= 150_000_000 else { throw PhotoError.tooLarge }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("IDPhotoIncoming")
        let directory = root.appendingPathComponent(UUID().uuidString)
        try PhotoFiles.createPrivateDirectory(directory)
        do {
            let result = StagedPhoto(directory: directory)
            try data.write(to: result.url, options: [.atomic, .completeFileProtection])
            try Task.checkCancellation()
            return result
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }
}

enum PhotoFiles {
    static func createPrivateDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete])
        var directory = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
    }

    static func protect(_ url: URL) throws {
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
}
