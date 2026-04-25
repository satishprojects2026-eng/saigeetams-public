import SwiftUI

struct OTPVerifyView: View {
    @Environment(AuthStore.self) private var authStore
    let email: String
    @State private var otp = ""
    @State private var loading = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            AppSettings.Colors.teacherBg.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("We sent a verification code to \(email)")
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                ThemedInput(label: "Verification Code", text: $otp, accentColor: AppSettings.Colors.teacherAccent, keyboardType: .numberPad)
                if let errorMsg { Text(errorMsg).font(.caption).foregroundStyle(.red) }
                ThemedButton("Verify", color: AppSettings.Colors.teacherPrimary, isLoading: loading) {
                    verify()
                }
            }
            .padding(24)
        }
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func verify() {
        guard otp.count >= 6 else { errorMsg = "Enter the 6-digit code"; return }
        loading = true; errorMsg = nil
        Task {
            do {
                try await authStore.verifyOTP(email: email, token: otp)
                authStore.isOnboarded = false
            } catch { errorMsg = error.localizedDescription }
            loading = false
        }
    }
}
