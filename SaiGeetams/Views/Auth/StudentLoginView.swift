import SwiftUI

struct StudentLoginView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var email = ""
    @State private var pin = ""
    @State private var loading = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            AppSettings.Colors.studentBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome Back!")
                        .font(.title).bold()
                        .foregroundStyle(AppSettings.Colors.studentAccent)
                        .padding(.bottom, 24)

                    ThemedInput(label: "Email", text: $email, accentColor: AppSettings.Colors.studentAccent, keyboardType: .emailAddress)
                        .textInputAutocapitalization(.never)
                    ThemedInput(label: "PIN (\(AppSettings.pinLength) digits)", text: $pin,
                                accentColor: AppSettings.Colors.studentAccent, isSecure: true, keyboardType: .numberPad)

                    if let errorMsg { Text(errorMsg).font(.caption).foregroundStyle(.red).padding(.top, 4) }

                    ThemedButton("Let's Go!", color: AppSettings.Colors.studentPrimary, isLoading: loading) {
                        login()
                    }
                    .padding(.top, 24)

                    NavigationLink(destination: StudentRegisterView()) {
                        Text("New Student? Register Here")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppSettings.Colors.studentAccent)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.top, 12)
                }
                .padding(24)
                .padding(.top, 20)
            }
        }
        .navigationTitle("\(AppSettings.studentLabel) Login")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HelpButton { "Enter your email and PIN to sign in!" }
            }
        }
    }

    private func login() {
        guard !email.isEmpty else { errorMsg = "Please enter your email"; return }
        guard pin.count == AppSettings.pinLength else { errorMsg = "PIN should be \(AppSettings.pinLength) numbers"; return }
        loading = true; errorMsg = nil
        Task {
            do { try await authStore.signIn(email: email.trimmingCharacters(in: .whitespaces), password: pin) }
            catch { errorMsg = error.localizedDescription }
            loading = false
        }
    }
}
