import SwiftUI

struct RecordingGuideView: View {

    @State private var showExamples = false

    private let reminders: [(String, String)] = [
        ("arrow.left.arrow.right", "Tipo operazione"),
        ("wallet.bifold", "Account"),
        ("tag", "Categoria"),
        ("eurosign.circle", "Importo"),
        ("calendar", "Data"),
        ("text.alignleft", "Descrizione")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Label(
                "Cosa dire nell'audio",
                systemImage: "lightbulb"
            )
            .font(.subheadline.weight(.semibold))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading)
                ],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(reminders, id: \.1) { reminder in
                    Label {
                        Text(reminder.1)
                            .font(.caption)
                    } icon: {
                        Image(systemName: reminder.0)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(
                "Parla in modo naturale, specificando i dettagli importanti."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showExamples.toggle()
                }
            } label: {
                HStack {
                    Text("Esempi di registrazione")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Image(
                        systemName: showExamples
                            ? "chevron.up"
                            : "chevron.down"
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showExamples {
                VStack(alignment: .leading, spacing: 12) {

                    example(
                        title: "Spesa",
                        text: """
                        Spesa di 12 euro e 50 al supermercato, \
                        categoria alimentari, pagata con account \
                        Contanti, oggi. Descrizione: spesa settimanale.
                        """
                    )

                    example(
                        title: "Trasferimento",
                        text: """
                        Trasferimento di 100 euro oggi \
                        dall'account Conto corrente \
                        all'account Risparmi.
                        """
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func example(
        title: String,
        text: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    RecordingGuideView()
        .padding()
}
