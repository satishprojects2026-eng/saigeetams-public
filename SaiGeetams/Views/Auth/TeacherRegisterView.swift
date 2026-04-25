import SwiftUI

struct TeacherRegisterView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var agreedTerms = false
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var showOTP = false

    var body: some View {
        ZStack {
            AppSettings.Colors.teacherBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let ac = AppSettings.Colors.teacherAccent
                    ThemedInput(label: "First Name", text: $firstName, accentColor: ac)
                    ThemedInput(label: "Last Name", text: $lastName, accentColor: ac)
                    ThemedInput(label: "Email", text: $email, accentColor: ac, keyboardType: .emailAddress)
                        .textInputAutocapitalization(.never)
                    ThemedInput(label: "Phone", text: $phone, accentColor: ac, keyboardType: .phonePad)
                    ThemedInput(label: "Password", text: $password, accentColor: ac, isSecure: true)
                    Text("Min 8 chars, 1 number, 1 special character")
                        .font(.caption).foregroundStyle(.white.opacity(0.4))

                    ThemedInput(label: "Subject", text: .constant(AppSettings.subjectName), accentColor: ac)
                        .disabled(true)

                    Button { SoundService.shared.playNavigationSound(); agreedTerms.toggle() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: agreedTerms ? "checkmark.square.fill" : "square")
                                .foregroundStyle(ac)
                            Text("I accept the Terms and Privacy Policy")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(minHeight: 44)
                    }
                    .padding(.top, 16)

                    if let errorMsg { Text(errorMsg).font(.caption).foregroundStyle(.red).padding(.top, 4) }

                    ThemedButton("Create Account", color: AppSettings.Colors.teacherPrimary, isLoading: loading) {
                        register()
                    }
                    .padding(.top, 24)
                }
                .padding(24)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showOTP) {
            OTPVerifyView(email: email)
        }
    }

    private func register() {
        guard !firstName.isEmpty, !lastName.isEmpty else { errorMsg = "Name required"; return }
        guard !email.isEmpty else { errorMsg = "Email required"; return }
        guard password.count >= 8 else { errorMsg = "Password too short"; return }
        guard password.rangeOfCharacter(from: .decimalDigits) != nil else { errorMsg = "Password needs a number"; return }
        guard password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*(),.?\":{}|<>")) != nil else { errorMsg = "Password needs a special char"; return }
        guard agreedTerms else { errorMsg = "Accept Terms"; return }

        loading = true; errorMsg = nil
        Task {
            do {
                try await authStore.signUpTeacher(
                    email: email.trimmingCharacters(in: .whitespaces), password: password,
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces),
                    phone: phone.trimmingCharacters(in: .whitespaces))
                showOTP = true
            } catch { errorMsg = error.localizedDescription }
            loading = false
        }
    }
}
