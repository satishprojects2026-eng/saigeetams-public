import SwiftUI

struct AppSettings {
    static let appName = "SAI GEETAMs"
    static let tagline = "Learn. Play. Grow."
    static let subjectName = "Carnatic Music"
    static let teacherLabel = "Teacher"
    static let studentLabel = "Student"
    static let parentLabel = "Parent"

    // MARK: - Colors
    struct Colors {
        static let teacherBg = Color(hex: "1a0800")
        static let teacherAccent = Color(hex: "f5a623")
        static let teacherPrimary = Color(hex: "d4521a")

        static let studentBg = Color(hex: "0d1f3c")
        static let studentAccent = Color(hex: "ffd54f")
        static let studentPrimary = Color(hex: "42a5f5")

        static let parentBg = Color(hex: "0a1628")
        static let parentAccent = Color(hex: "81c784")
        static let parentPrimary = Color(hex: "388e3c")

        static let cancelled = Color(hex: "808080")
        static let atRisk = Color(hex: "f44336")
        static let success = Color(hex: "4caf50")
    }

    // MARK: - Sounds
    static let navigationSounds = true
    static let announcementSounds = true
    static let swaraSequence = ["Sa", "Re", "Ga", "Ma", "Pa", "Dha", "Ni", "Sa"]
    static let swaraAudioFiles: [String: String] = [
        "Sa": "sa", "Re": "re", "Ga": "ga", "Ma": "ma",
        "Pa": "pa", "Dha": "dha", "Ni": "ni"
    ]
    static let announcementMelody = ["Sa", "Re", "Ga", "Ma", "Pa"]

    // MARK: - Features
    static let consentFormRequired = true
    static let parentDetailsRequired = true
    static let offlineDownloadsEnabled = true
    static let maxFileUploadMB = 50
    static let allowedStudentSubmissions = ["image", "pdf", "voice_recording"]
    static let duplicateCheckFields = ["firstName", "lastName", "phone", "email"]
    static let inviteLinkExpiryHours = 72
    static let inviteLinkMaxUses = 50
    static let pinLength = 4
    static let biometricsEnabled = true
    static let classReminderMinutes = [1440, 60]

    // MARK: - Badges
    static let badgeDefinitions: [BadgeDefinition] = [
        BadgeDefinition(id: "first_class", icon: "🎵", title: "First Class!", threshold: 1, metric: .attendance),
        BadgeDefinition(id: "streak_5", icon: "🔥", title: "On Fire!", threshold: 5, metric: .streak),
        BadgeDefinition(id: "attend_10", icon: "⭐", title: "Star Student", threshold: 10, metric: .attendance),
        BadgeDefinition(id: "attend_25", icon: "🏆", title: "Champion", threshold: 25, metric: .attendance),
        BadgeDefinition(id: "attend_50", icon: "🎶", title: "Music Master", threshold: 50, metric: .attendance),
        BadgeDefinition(id: "perfect_month", icon: "💫", title: "Perfect Month", threshold: 1, metric: .perfectMonth),
    ]

    static let skillLevels = ["Not Started", "Started", "In Progress", "Near Complete", "Complete"]
    static let levelNames = ["Beginner", "Intermediate", "Advanced"]

    // MARK: - App Store Update
    static let appStoreId = "YOUR_APP_STORE_ID"

    // MARK: - Legal
    static let privacyPolicyUrl = "https://saigeetams.com/privacy"
    static let termsUrl = "https://saigeetams.com/terms"
    static let coppaCompliant = true
    static let gdprCompliant = true
    static let minAgeForDirectConsent = 13
    static let annualPrivacyReviewEnabled = true
}

// MARK: - Badge Definition
struct BadgeDefinition: Identifiable {
    let id: String
    let icon: String
    let title: String
    let threshold: Int
    let metric: BadgeMetric
}

enum BadgeMetric {
    case attendance, streak, perfectMonth
}

// MARK: - Color hex extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
