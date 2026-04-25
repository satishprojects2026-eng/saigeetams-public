import SwiftUI

struct OnboardingView: View {
    @Environment(AuthStore.self) private var authStore
    let role: UserRole
    @State private var currentStep = 0

    private var steps: [(title: String, desc: String)] {
        if role == .teacher {
            return [
                ("Welcome to \(AppSettings.appName)", "Manage classes, students, and schedules in one place."),
                ("Create Classes & Terms", "Set up groups, define terms, copy sessions across dates."),
                ("Add Your Students", "Invite by link, add manually. You approve all registrations."),
                ("Track Everything", "Analytics, at-risk alerts, practice logs, report cards."),
                ("You Are All Set!", "Tap the ? on any screen for help."),
            ]
        } else {
            return [
                ("Hi! Welcome to \(AppSettings.appName)", "This is your special music learning app!"),
                ("Your Music Calendar", "Gold dots mean you have class that day!"),
                ("Practice Log", "Log your daily practice so your teacher can see!"),
                ("Earn Badges", "Attend and practice to earn cool badges!"),
                ("You Are a Music Star!", "Tap the ? any time for help."),
            ]
        }
    }

    private var colors: (bg: Color, accent: Color, primary: Color) {
        role == .teacher
        ? (AppSettings.Colors.teacherBg, AppSettings.Colors.teacherAccent, AppSettings.Colors.teacherPrimary)
        : (AppSettings.Colors.studentBg, AppSettings.Colors.studentAccent, AppSettings.Colors.studentPrimary)
    }

    var body: some View {
        ZStack {
            colors.bg.ignoresSafeArea()
            VStack {
                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? colors.accent : Color.white.opacity(0.2))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 60)

                Spacer()

                VStack(spacing: 16) {
                    Text("\(currentStep + 1) of \(steps.count)")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(colors.accent)
                    Text(steps[currentStep].title)
                        .font(.title).bold()
                        .foregroundStyle(colors.accent)
                        .multilineTextAlignment(.center)
                    Text(steps[currentStep].desc)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                ThemedButton(currentStep < steps.count - 1 ? "Next" : "Let's Go!", color: colors.primary) {
                    if currentStep < steps.count - 1 {
                        withAnimation { currentStep += 1 }
                    } else {
                        authStore.isOnboarded = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .navigationBarBackButtonHidden()
    }
}
