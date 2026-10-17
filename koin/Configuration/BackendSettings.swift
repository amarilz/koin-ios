import Foundation

enum BackendSettings {

    static let defaultHost = "192.168.179.12"
    static let hostKey = "backendHost"

    static func baseURL(for host: String) -> URL? {
        let trimmedHost = host.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let parts = trimmedHost.split(
            separator: ".",
            omittingEmptySubsequences: false
        )

        guard parts.count == 4 else {
            return nil
        }

        for part in parts {
            guard !part.isEmpty,
                  part.allSatisfy({ $0.isASCII && $0.isNumber }),
                  part.count <= 3,
                  let number = Int(part),
                  (0...255).contains(number) else {
                return nil
            }
        }

        return URL(string: "http://\(trimmedHost):8080")
    }
}
