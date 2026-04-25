import SwiftUI

struct SplashView: View {
    @Bindable var authStore: AuthStore
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            AppSettings.Colors.teacherBg.ignoresSafeArea()
            VStack(spacing: 8) {
                Text(AppSettings.appName)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(AppSettings.Colors.teacherAccent)
                    .tracking(2)
                Text(AppSettings.tagline)
                    .font(.title3).fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
                Text(AppSettings.subjectName)
                    .font(.caption).tracking(4)
                    .foregroundStyle(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .padding(.top, 16)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1)) { opacity = 1 }
            Task {
                await authStore.restoreSession()
            }
        }
    }
}
