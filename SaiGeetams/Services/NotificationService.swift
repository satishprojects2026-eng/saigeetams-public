import UserNotifications
import UIKit

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func registerForPush() async {
        guard await requestPermission() else { return }
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func savePushToken(_ token: Data, userId: UUID) async {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        struct TokenInsert: Encodable {
            let user_id: UUID
            let token: String
            let platform: String
        }
        try? await SupabaseService.shared.upsert(
            "push_tokens",
            value: TokenInsert(user_id: userId, token: tokenString, platform: "ios")
        )
    }

    func scheduleLocalReminder(title: String, body: String, date: Date, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
