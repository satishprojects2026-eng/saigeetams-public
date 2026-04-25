import SwiftUI
import LocalAuthentication

@Observable
final class AuthStore {
    var user: AppUser?
    var role: UserRole?
    var isLoading = true
    var isAuthenticated = false
    var isOnboarded = false

    private let supa = SupabaseService.shared

    // MARK: - Teacher Auth
    func signUpTeacher(email: String, password: String, firstName: String, lastName: String, phone: String) async throws {
        let userId = try await supa.signUp(email: email, password: password)

        struct UserInsert: Encodable {
            let id: UUID
            let role: String
            let email: String
            let phone: String
            let first_name: String
            let last_name: String
            let is_verified: Bool
            let is_approved: Bool
        }

        try await supa.insert("users", value: UserInsert(
            id: userId, role: "teacher", email: email, phone: phone,
            first_name: firstName, last_name: lastName,
            is_verified: false, is_approved: true
        ))

        let fetched: AppUser? = try await supa.fetchSingle("users", eq: "id", value: userId.uuidString)
        await MainActor.run {
            self.user = fetched
            self.role = .teacher
            self.isAuthenticated = true
        }
    }

    func signIn(email: String, password: String) async throws {
        try await supa.signIn(email: email, password: password)
        guard let userId = await supa.currentUserId else { throw AppError.authFailed }

        let fetched: AppUser? = try await supa.fetchSingle("users", eq: "id", value: userId.uuidString)
        guard let u = fetched, u.deletedAt == nil else { throw AppError.notFound }

        await MainActor.run {
            self.user = u
            self.role = u.role
            self.isAuthenticated = true
            self.isLoading = false
        }
    }

    func verifyOTP(email: String, token: String) async throws {
        try await supa.verifyOTP(email: email, token: token)
        guard let userId = user?.id else { return }
        struct VerifyUpdate: Encodable { let is_verified: Bool }
        try await supa.update("users", value: VerifyUpdate(is_verified: true), eq: "id", id: userId.uuidString)
        await MainActor.run { self.user?.isVerified = true }
    }

    func restoreSession() async {
        await MainActor.run { isLoading = true }
        guard let userId = await supa.restoreSession() else {
            await MainActor.run { isLoading = false }
            return
        }
        let fetched: AppUser? = try? await supa.fetchSingle("users", eq: "id", value: userId.uuidString)
        await MainActor.run {
            if let u = fetched, u.deletedAt == nil {
                self.user = u
                self.role = u.role
                self.isAuthenticated = true
            }
            self.isLoading = false
        }
    }

    func signOut() async {
        try? await supa.signOut()
        await MainActor.run {
            user = nil
            role = nil
            isAuthenticated = false
            isOnboarded = false
        }
    }

    func deleteAccount() async {
        guard let userId = user?.id else { return }
        struct DeleteUpdate: Encodable {
            let deleted_at: String
            let first_name: String
            let last_name: String
            let email: String?
            let phone: String?
            let profile_photo: String?
        }
        try? await supa.update("users", value: DeleteUpdate(
            deleted_at: ISO8601DateFormatter().string(from: Date()),
            first_name: "Deleted", last_name: "User",
            email: nil, phone: nil, profile_photo: nil
        ), eq: "id", id: userId.uuidString)
        try? await supa.delete("push_tokens", eq: "user_id", value: userId.uuidString)
        await signOut()
    }

    // MARK: - Biometrics
    func authenticateWithBiometrics() async -> Bool {
        guard AppSettings.biometricsEnabled else { return false }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return false }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sign in to \(AppSettings.appName)")
        } catch {
            return false
        }
    }
}
