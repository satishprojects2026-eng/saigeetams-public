import Foundation

final class BadgeEngine {
    static let shared = BadgeEngine()
    private let supa = SupabaseService.shared

    private init() {}

    struct StudentStats {
        var totalAttendance: Int
        var currentStreak: Int
        var perfectMonths: Int
    }

    func checkAndAwardBadges(studentId: UUID, stats: StudentStats) async -> [String] {
        var newBadges: [String] = []
        let existing: [StudentBadge] = (try? await supa.fetch("student_badges", eq: "student_id", value: studentId.uuidString)) ?? []
        let earned = Set(existing.map(\.badgeId))

        for badge in AppSettings.badgeDefinitions {
            guard !earned.contains(badge.id) else { continue }
            let value: Int
            switch badge.metric {
            case .attendance: value = stats.totalAttendance
            case .streak: value = stats.currentStreak
            case .perfectMonth: value = stats.perfectMonths
            }
            guard value >= badge.threshold else { continue }

            struct InsertBadge: Encodable {
                let student_id: UUID
                let badge_id: String
            }
            do {
                try await supa.insert("student_badges", value: InsertBadge(student_id: studentId, badge_id: badge.id))
                newBadges.append(badge.id)
            } catch {}
        }
        return newBadges
    }
}
