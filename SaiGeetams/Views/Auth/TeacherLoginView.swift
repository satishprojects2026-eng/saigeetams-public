import SwiftUI

struct TeacherLoginView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            AppSettings.Colors.teacherBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome Back")
                        .font(.title).bold()
                        .foregroundStyle(AppSettings.Colors.teacherAccent)
                        .padding(.bottom, 24)

                    ThemedInput(label: "Email", text: $email, placeholder: "you@email.com",
                                accentColor: AppSettings.Colors.teacherAccent, keyboardType: .emailAddress)
                        .textInputAutocapitalization(.never)
                    ThemedInput(label: "Password", text: $password, accentColor: AppSettings.Colors.teacherAccent, isSecure: true)

                    if let errorMsg { Text(errorMsg).font(.caption).foregroundStyle(.red).padding(.top, 4) }

                    ThemedButton("Sign In", color: AppSettings.Colors.teacherPrimary, isLoading: loading) {
                        login()
                    }
                    .padding(.top, 24)

                    NavigationLink(destination: TeacherRegisterView()) {
                        Text("Create Account")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppSettings.Colors.teacherAccent)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.top, 12)
                }
                .padding(24)
                .padding(.top, 20)
            }
        }
        .navigationTitle("\(AppSettings.teacherLabel) Login")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HelpButton { "Enter your email and password to sign in." }
            }
        }
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else { errorMsg = "Please enter email and password"; return }
        loading = true; errorMsg = nil
        Task {
            do {
                try await authStore.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            } catch { errorMsg = error.localizedDescription }
            loading = false
        }
    }
}

struct HelpButton: View {
    let message: () -> String
    @State private var showHelp = false
    var body: some View {
        Button {
            SoundService.shared.playNavigationSound()
            showHelp = true
        } label: {
            Image(systemName: "questionmark.circle").frame(minWidth: 44, minHeight: 44)
        }
        .alert("Help", isPresented: $showHelp) { Button("OK") {} } message: { Text(message()) }
    }
}
