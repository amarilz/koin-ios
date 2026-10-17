import Foundation
import Combine

@MainActor
final class RecordingSyncManager: ObservableObject {

    @Published private(set) var isSyncing = false
    @Published private(set) var completed = 0
    @Published private(set) var total = 0

    private let uploadService: RecordingUploadService

    init(uploadService: RecordingUploadService) {
        self.uploadService = uploadService
    }

    func sync(
        recordings: [Recording],
        store: RecordingStore,
        audio: AudioRecorder
    ) async -> String {

        guard !isSyncing else {
            return "Sincronizzazione già in corso."
        }

        guard !recordings.isEmpty else {
            return "Nessuna registrazione da inviare."
        }

        isSyncing = true
        completed = 0
        total = recordings.count

        defer {
            isSyncing = false
        }

        for recording in recordings {
            do {
                if audio.selectedURL == recording.url {
                    audio.stopPlayback()
                }

                let response = try await uploadService.upload(recording)

                // A valid backend confirmation is required before deletion.
                guard response.id > 0 else {
                    throw UploadError.invalidResponse
                }

                try store.delete(recording)
                completed += 1

            } catch {
                return """
                Sincronizzazione interrotta.

                Inviate: \(completed) di \(total).

                Errore: \(error.localizedDescription)
                """
            }
        }

        return """
        Sincronizzazione completata.

        \(completed) registrazioni inviate ed eliminate dal dispositivo.
        """
    }
}
