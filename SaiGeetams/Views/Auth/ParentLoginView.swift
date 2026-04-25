import SwiftUI

struct ParentLoginView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            AppSettings.Colors.parentBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome")
                        .font(.title).bold()
                        .foregroundStyle(AppSettings.Colors.parentAccent)
                        .padding(.bottom, 24)

                    ThemedInput(label: "Email", text: $email, accentColor: AppSettings.Colors.parentAccent, keyboardType: .emailAddress)
                        .textInputAutocapitalization(.never)
                    ThemedInput(label: "Password", text: $password, accentColor: AppSettings.Colors.parentAccent, isSecure: true)
                    if let errorMsg { Text(errorMsg).font(.caption).foregroundStyle(.red).padding(.top, 4) }

                    ThemedButton("Sign In", color: AppSettings.Colors.parentPrimary, isLoading: loading) {
                        guard !email.isEmpty, !password.isEmpty else { errorMsg = "Enter email and password"; return }
                        loading = true; errorMsg = nil
                        Task {
                            do { try await authStore.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password) }
                            catch { self.errorMsg = error.localizedDescription }
                            loading = false
                        }
                    }
                    .padding(.top, 24)
                }
                .padding(24).padding(.top, 20)
            }
        }
        .navigationTitle("\(AppSettings.parentLabel) Login")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Sign in with the email from your invitation." } } }
    }
}
