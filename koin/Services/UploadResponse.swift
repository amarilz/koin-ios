import Foundation

struct UploadResponse: Decodable {
    let id: Int64
}

enum UploadError: LocalizedError {
    case invalidResponse
    case serverError(Int, String)
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Risposta non valida dal backend."
        case .serverError(let status, let message):
            return "Errore HTTP \(status): \(message)"
        case .fileTooLarge:
            return "La registrazione supera il limite di 25 MB."
        }
    }
}

struct RecordingUploadService {

    func upload(_ recording: Recording) async throws -> UploadResponse {

        let host = UserDefaults.standard.string(
            forKey: BackendSettings.hostKey
        ) ?? BackendSettings.defaultHost

        guard let baseURL = BackendSettings.baseURL(for: host) else {
            throw UploadError.invalidResponse
        }

        let endpoint = baseURL
            .appendingPathComponent("forms")
            .appendingPathComponent("recordings")
        let audioData = try Data(contentsOf: recording.url)

        guard audioData.count <= 25 * 1024 * 1024 else {
            throw UploadError.fileTooLarge
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        func append(_ string: String) {
            body.append(Data(string.utf8))
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"durationMs\"\r\n")
        append("\r\n")
        append("\(Int64((recording.duration * 1000).rounded()))\r\n")

        append("--\(boundary)\r\n")
        append(
            "Content-Disposition: form-data; name=\"audio\"; " +
            "filename=\"\(recording.url.lastPathComponent)\"\r\n"
        )
        append("Content-Type: audio/mp4\r\n")
        append("\r\n")

        body.append(audioData)
        append("\r\n")
        append("--\(boundary)--\r\n")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = body
        request.timeoutInterval = 180

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 240

        let session = URLSession(configuration: configuration)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            let message = String(
                data: data,
                encoding: .utf8
            ) ?? "Errore sconosciuto"

            throw UploadError.serverError(
                httpResponse.statusCode,
                message
            )
        }

        let result = try JSONDecoder().decode(
            UploadResponse.self,
            from: data
        )

        guard result.id > 0 else {
            throw UploadError.invalidResponse
        }

        return result
    }
}
