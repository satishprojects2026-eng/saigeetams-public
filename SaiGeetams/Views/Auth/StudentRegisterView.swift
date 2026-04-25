import SwiftUI

struct StudentRegisterView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var step = 1
    @State private var loading = false
    @State private var errorMsg: String?

    // Student
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dob = ""
    @State private var email = ""
    @State private var password = ""

    // Parent
    @State private var parentName = ""
    @State private var parentRelation = ""
    @State private var parentPhone = ""
    @State private var parentEmail = ""
    @State private var emergencyContact = ""

    // Consent & terms
    @State private var consentSigned = false
    @State private var agreedTerms = false
    @State private var inviteCode = ""

    let ac = AppSettings.Colors.studentAccent
    let pc = AppSettings.Colors.studentPrimary

    var body: some View {
        ZStack {
            AppSettings.Colors.studentBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Step \(step) of 5")
                        .font(.caption).foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity).padding(.bottom, 8)

                    switch step {
                    case 1: studentInfoStep
                    case 2: parentInfoStep
                    case 3: consentStep
                    case 4: termsStep
                    case 5: inviteStep
                    default: EmptyView()
                    }

                    if let errorMsg {
                        Text(errorMsg).font(.caption).foregroundStyle(.red).padding(.top, 8)
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("New \(AppSettings.studentLabel)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HelpButton { "Fill in your details to join a class!" }
            }
        }
    }

    private var studentInfoStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About You").font(.title2).bold().foregroundStyle(ac).padding(.bottom, 16)
            ThemedInput(label: "First Name", text: $firstName, accentColor: ac)
            ThemedInput(label: "Last Name", text: $lastName, accentColor: ac)
            ThemedInput(label: "Date of Birth (YYYY-MM-DD)", text: $dob, accentColor: ac)
            ThemedInput(label: "Email", text: $email, accentColor: ac, keyboardType: .emailAddress).textInputAutocapitalization(.never)
            ThemedInput(label: "Password", text: $password, accentColor: ac, isSecure: true)
            ThemedButton("Next", color: pc) { validateAndNext() }
                .padding(.top, 24)
        }
    }

    private var parentInfoStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Parent / Guardian").font(.title2).bold().foregroundStyle(ac).padding(.bottom, 16)
            ThemedInput(label: "Parent Name", text: $parentName, accentColor: ac)
            ThemedInput(label: "Relationship", text: $parentRelation, placeholder: "Mother, Father, Guardian...", accentColor: ac)
            ThemedInput(label: "Phone", text: $parentPhone, accentColor: ac, keyboardType: .phonePad)
            ThemedInput(label: "Parent Email (optional)", text: $parentEmail, accentColor: ac, keyboardType: .emailAddress).textInputAutocapitalization(.never)
            ThemedInput(label: "Emergency Contact", text: $emergencyContact, accentColor: ac, keyboardType: .phonePad)
            ThemedButton("Next", color: pc) { validateAndNext() }
                .padding(.top, 24)
        }
    }

    private var consentStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parent Consent").font(.title2).bold().foregroundStyle(ac)
            Text("I, the parent/guardian, consent to my child using \(AppSettings.appName) for \(AppSettings.subjectName) class management. Data will be handled per our Privacy Policy and COPPA requirements.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.7))
            Button { SoundService.shared.playNavigationSound(); consentSigned.toggle() } label: {
                HStack(spacing: 10) {
                    Image(systemName: consentSigned ? "checkmark.square.fill" : "square").foregroundStyle(ac)
                    Text("I consent on behalf of my child").foregroundStyle(.white.opacity(0.7))
                }.frame(minHeight: 44)
            }
            ThemedButton("Next", color: pc) { validateAndNext() }
        }
    }

    private var termsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Terms").font(.title2).bold().foregroundStyle(ac)
            Button { SoundService.shared.playNavigationSound(); agreedTerms.toggle() } label: {
                HStack(spacing: 10) {
                    Image(systemName: agreedTerms ? "checkmark.square.fill" : "square").foregroundStyle(ac)
                    Text("I accept the Terms and Privacy Policy").foregroundStyle(.white.opacity(0.7))
                }.frame(minHeight: 44)
            }
            ThemedButton("Next", color: pc) { validateAndNext() }
        }
    }

    private var inviteStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invite Code").font(.title2).bold().foregroundStyle(ac)
            Text("Enter the invite code from your teacher to join their class.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.6))
            ThemedInput(label: "Invite Code", text: $inviteCode, accentColor: ac).textInputAutocapitalization(.never)
            ThemedButton("Join Class", color: pc, isLoading: loading) { register() }
        }
    }

    private func validateAndNext() {
        errorMsg = nil
        switch step {
        case 1:
            guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else { errorMsg = "Fill in all fields"; return }
        case 2:
            guard !parentName.isEmpty, !parentRelation.isEmpty, !parentPhone.isEmpty, !emergencyContact.isEmpty else { errorMsg = "Parent details required"; return }
        case 3:
            guard consentSigned else { errorMsg = "Consent required"; return }
        case 4:
            guard agreedTerms else { errorMsg = "Accept Terms"; return }
        default: break
        }
        SoundService.shared.playNavigationSound()
        step += 1
    }

    private func register() {
        guard !inviteCode.isEmpty else { errorMsg = "Enter an invite code"; return }
        loading = true; errorMsg = nil
        Task {
            do {
                // Duplicate check
                let (isDup, matched) = try await SupabaseService.shared.checkDuplicateStudent(
                    firstName: firstName, lastName: lastName, phone: parentPhone, email: email)
                if isDup { errorMsg = "Account exists (\(matched.joined(separator: ", "))). Contact your teacher."; loading = false; return }

                // Sign up
                let userId = try await SupabaseService.shared.signUp(email: email.trimmingCharacters(in: .whitespaces), password: password)
                let supa = SupabaseService.shared

                struct UserInsert: Encodable {
                    let id: UUID; let role: String; let email: String; let first_name: String; let last_name: String
                    let dob: String?; let is_verified: Bool; let is_approved: Bool
                }
                try await supa.insert("users", value: UserInsert(
                    id: userId, role: "student", email: email, first_name: firstName, last_name: lastName,
                    dob: dob.isEmpty ? nil : dob, is_verified: false, is_approved: false))

                struct ParentInsert: Encodable {
                    let student_id: UUID; let name: String; let relationship: String
                    let phone: String; let email: String?; let emergency_contact: String
                }
                try await supa.insert("parent_guardians", value: ParentInsert(
                    student_id: userId, name: parentName, relationship: parentRelation,
                    phone: parentPhone, email: parentEmail.isEmpty ? nil : parentEmail, emergency_contact: emergencyContact))

                if AppSettings.consentFormRequired {
                    struct ConsentInsert: Encodable {
                        let student_id: UUID; let signed_by: String; let relationship: String
                        let form_version: String; let signature_data: String
                    }
                    try await supa.insert("consent_forms", value: ConsentInsert(
                        student_id: userId, signed_by: parentName, relationship: parentRelation,
                        form_version: "1.0", signature_data: "Digitally signed by \(parentName) on \(Date())"))
                }

                // Use invite code
                let invites: [InvitationLink] = try await supa.fetch("invitation_links", eq: "token", value: inviteCode.trimmingCharacters(in: .whitespaces))
                if let invite = invites.first, invite.isActive {
                    struct EnrollInsert: Encodable { let class_id: UUID; let student_id: UUID; let status: String }
                    try await supa.insert("class_enrollments", value: EnrollInsert(class_id: invite.classId, student_id: userId, status: "pending"))
                    struct CountUpdate: Encodable { let used_count: Int }
                    try await supa.update("invitation_links", value: CountUpdate(used_count: invite.usedCount + 1), eq: "id", id: invite.id.uuidString)
                }
                errorMsg = nil
                // Navigate back - pending approval
            } catch { errorMsg = error.localizedDescription }
            loading = false
        }
    }
}
