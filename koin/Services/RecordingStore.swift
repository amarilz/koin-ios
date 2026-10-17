import Foundation
import AVFoundation
import Combine

@MainActor
final class RecordingStore: ObservableObject {

    @Published private(set) var recordings: [Recording] = []

    private let fileManager = FileManager.default

    var documentsDirectory: URL {
        fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    func loadRecordings() async throws {
        let urls = try fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )

        var loaded: [Recording] = []

        for url in urls where url.pathExtension.lowercased() == "m4a" {
            let attributes = try fileManager.attributesOfItem(
                atPath: url.path
            )

            let createdAt = attributes[.creationDate] as? Date
                ?? .distantPast

            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)

            let seconds = CMTimeGetSeconds(duration)

            loaded.append(
                Recording(
                    url: url,
                    createdAt: createdAt,
                    duration: seconds.isFinite ? seconds : 0
                )
            )
        }

        recordings = loaded.sorted {
            $0.createdAt > $1.createdAt
        }
    }

    func delete(_ recording: Recording) throws {
        try fileManager.removeItem(at: recording.url)

        recordings.removeAll {
            $0.id == recording.id
        }
    }
}
