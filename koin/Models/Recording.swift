
import Foundation

struct Recording: Identifiable, Equatable {

    let url: URL
    let createdAt: Date
    let duration: TimeInterval

    var id: URL { url }

    var title: String {
        createdAt.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .hour()
                .minute()
                .locale(Locale(identifier: "it_IT"))
        )
    }

    var formattedDuration: String {
        Self.formatTime(duration)
    }

    static func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else {
            return "00:00"
        }

        let seconds = Int(time)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(
                format: "%02d:%02d:%02d",
                hours, minutes, remainingSeconds
            )
        }

        return String(
            format: "%02d:%02d",
            minutes, remainingSeconds
        )
    }
}
