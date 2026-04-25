import SwiftUI

@Observable
final class UIStore {
    var pendingAckMessage: AppMessage?
    var badgeToast: (icon: String, title: String)?
    var isOnboarding = false
    var onboardingStep = 0

    func showBadgeToast(icon: String, title: String) {
        badgeToast = (icon, title)
        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run { badgeToast = nil }
        }
    }
}
