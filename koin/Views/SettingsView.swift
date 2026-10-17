import SwiftUI

struct SettingsView: View {

    @AppStorage(BackendSettings.hostKey)
    private var savedHost = BackendSettings.defaultHost

    @Environment(\.dismiss) private var dismiss

    @State private var editedHost = ""
    @State private var isChecking = false
    @State private var connectionResult: ConnectionResult?
    @State private var showInvalidHost = false

    private enum ConnectionResult {
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            Section {
                TextField(
                    "Indirizzo IP",
                    text: $editedHost
                )
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onChange(of: editedHost) { _, _ in
                    connectionResult = nil
                }
            } header: {
                Text("Backend")
            } footer: {
                Text(
                    "Inserisci soltanto l'indirizzo IP. " +
                    "La connessione utilizza HTTP sulla porta 8080."
                )
            }

            Section {
                Button {
                    Task {
                        await checkConnection()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isChecking {
                            ProgressView()
                        } else {
                            Image(systemName: "wifi")
                        }

                        Text(
                            isChecking
                                ? "Verifica in corso..."
                                : "Verifica connessione"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isChecking)

                if let connectionResult {
                    switch connectionResult {
                    case .success:
                        Label(
                            "Backend raggiungibile",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)

                    case .failure(let message):
                        Label {
                            Text(message)
                        } icon: {
                            Image(
                                systemName: "xmark.circle.fill"
                            )
                        }
                        .foregroundStyle(.red)
                    }
                }
            } footer: {
                Text(
                    "La verifica controlla che il server HTTP " +
                    "risponda all'indirizzo indicato."
                )
            }
            Section {
                LabeledContent("Versione", value: appVersion)
            } header: {
                Text("Informazioni")
            }
        }
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Salva") {
                    save()
                }
                .disabled(isChecking)
            }
        }
        .onAppear {
            editedHost = savedHost
        }
        .alert(
            "Indirizzo non valido",
            isPresented: $showInvalidHost
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Inserisci un indirizzo IP valido, " +
                "senza http:// e senza porta."
            )
        }
    }

    private func save() {
        let host = editedHost.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard BackendSettings.baseURL(for: host) != nil else {
            showInvalidHost = true
            return
        }

        savedHost = host
        dismiss()
    }

    @MainActor
    private func checkConnection() async {
        guard !isChecking else {
            return
        }

        guard let baseURL = BackendSettings.baseURL(
            for: editedHost
        ) else {
            connectionResult = .failure(
                "Indirizzo IP non valido."
            )
            return
        }

        isChecking = true
        connectionResult = nil

        defer {
            isChecking = false
        }

        // Check the existing recordings page.
        // This request does not upload or modify anything.
        let url = baseURL
            .appendingPathComponent("health")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8

        do {
            let (_, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                connectionResult = .failure(
                    "Risposta non valida dal server."
                )
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                connectionResult = .success
            } else {
                connectionResult = .failure(
                    "Il server ha risposto con HTTP " +
                    "\(httpResponse.statusCode)."
                )
            }
        } catch {
            connectionResult = .failure(
                "Connessione non riuscita: " +
                error.localizedDescription
            )
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"

        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "—"

        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
