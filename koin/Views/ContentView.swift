
import SwiftUI

struct ContentView: View {

    @StateObject private var store = RecordingStore()
    @StateObject private var audio = AudioRecorder()

    @State private var recordingToDelete: Recording?
    @State private var isStartingRecording = false

    @StateObject private var syncManager = RecordingSyncManager(
        uploadService: RecordingUploadService()
    )

    @State private var syncMessage = ""
    @State private var showSyncResult = false

    var body: some View {
        NavigationStack {
            Group {
                if store.recordings.isEmpty {
                    ContentUnavailableView(
                        "Nessuna registrazione",
                        systemImage: "waveform",
                        description: Text(
                            "Premi il pulsante in basso per registrare."
                        )
                    )
                } else {
                    recordingsList
                }
            }
            .navigationTitle("Koin")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Impostazioni")
                    .disabled(syncManager.isSyncing)
                }
            }
            .alert(
                "Sincronizzazione",
                isPresented: $showSyncResult
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(syncMessage)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                recordingBar
            }
            .task {
                await loadRecordings()
            }
            .confirmationDialog(
                "Eliminare questa registrazione?",
                isPresented: Binding(
                    get: { recordingToDelete != nil },
                    set: {
                        if !$0 {
                            recordingToDelete = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button(
                    "Elimina registrazione",
                    role: .destructive
                ) {
                    deleteSelectedRecording()
                }

                Button("Annulla", role: .cancel) {
                    recordingToDelete = nil
                }
            } message: {
                Text("Questa operazione è irreversibile.")
            }
            .alert(
                "Errore",
                isPresented: Binding(
                    get: { audio.errorMessage != nil },
                    set: {
                        if !$0 {
                            audio.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    audio.errorMessage = nil
                }
            } message: {
                Text(audio.errorMessage ?? "")
            }
        }
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        List {
            Section {
                ForEach(store.recordings) { recording in
                    RecordingRow(
                        recording: recording,
                        isSyncing: syncManager.isSyncing,
                        audio: audio,
                        onDelete: {
                            recordingToDelete = recording
                        }
                    )
                }
            } header: {
                Text("\(store.recordings.count) registrazioni")
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Bottom Recording Bar

    private var recordingBar: some View {
        VStack(spacing: 0) {

            Divider()

            RecordingGuideView()
                .padding(.horizontal, 16)
                .padding(.top, 12)

            HStack(spacing: 12) {

                Button {
                    Task {
                        await toggleRecording()
                    }
                } label: {
                    Label(
                        audio.isRecording
                            ? "Ferma"
                            : "Registra",
                        systemImage: audio.isRecording
                            ? "stop.fill"
                            : "mic.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(
                    isStartingRecording ||
                    syncManager.isSyncing
                )

                Button {
                    Task {
                        await synchronizeRecordings()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if syncManager.isSyncing {
                            ProgressView()
                                .tint(.white)

                            Text(
                                "\(syncManager.completed)/\(syncManager.total)"
                            )
                        } else {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Invia tutti")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(
                    audio.isRecording ||
                    isStartingRecording ||
                    syncManager.isSyncing ||
                    store.recordings.isEmpty
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }

    // MARK: - Actions

    private func toggleRecording() async {
        if audio.isRecording {
            audio.stopRecording()
            await loadRecordings()
            return
        }

        guard !isStartingRecording else { return }

        isStartingRecording = true
        defer { isStartingRecording = false }

        let filename = "Registrazione_\(UUID().uuidString).m4a"

        let url = store.documentsDirectory
            .appendingPathComponent(filename)

        _ = await audio.startRecording(to: url)
    }

    private func loadRecordings() async {
        do {
            try await store.loadRecordings()
        } catch {
            audio.errorMessage = error.localizedDescription
        }
    }

    private func deleteSelectedRecording() {
        guard let recording = recordingToDelete else {
            return
        }

        do {
            if audio.selectedURL == recording.url {
                audio.stopPlayback()
            }

            try store.delete(recording)
            recordingToDelete = nil

        } catch {
            audio.errorMessage = error.localizedDescription
        }
    }
    
    private func synchronizeRecordings() async {
        guard !audio.isRecording,
              !isStartingRecording,
              !syncManager.isSyncing else {
            return
        }

        syncMessage = await syncManager.sync(
            recordings: store.recordings,
            store: store,
            audio: audio
        )

        showSyncResult = true
    }
}

// MARK: - Recording Row

private struct RecordingRow: View {

    let recording: Recording
    let isSyncing: Bool

    @ObservedObject var audio: AudioRecorder

    let onDelete: () -> Void

    private var isSelected: Bool {
        audio.selectedURL == recording.url
    }

    private var isPlaying: Bool {
        isSelected && audio.isPlaying
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 12) {

                Image(systemName: "waveform")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.subheadline)
                        .lineLimit(2)

                    Text(recording.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button {
                    audio.togglePlayback(for: recording)
                } label: {
                    Image(
                        systemName: isPlaying
                            ? "pause.fill"
                            : "play.fill"
                    )
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(audio.isRecording)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                        .frame(width: 40, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(audio.isRecording)
            }

            if isSelected {
                playbackProgress
            }
        }
        .padding(.vertical, 5)
    }

    // MARK: - Playback Progress

    private var playbackProgress: some View {
        VStack(spacing: 2) {

            Slider(
                value: Binding(
                    get: { audio.currentTime },
                    set: { audio.seek(to: $0) }
                ),
                in: 0...max(audio.duration, 0.01)
            )
            .tint(.blue)

            HStack {
                Text(
                    Recording.formatTime(audio.currentTime)
                )

                Spacer()

                Text(
                    Recording.formatTime(audio.duration)
                )
            }
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
