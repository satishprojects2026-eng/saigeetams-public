import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private let schema = "saigeetams"

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey,
            options: .init(db: .init(schema: "saigeetams"))
        )
    }

    // MARK: - Auth
    func signUp(email: String, password: String) async throws -> UUID {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.user.id
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func verifyOTP(email: String, token: String) async throws {
        try await client.auth.verifyOTP(email: email, token: token, type: .email)
    }

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    func restoreSession() async -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }

    // MARK: - Generic CRUD
    func fetch<T: Decodable>(_ table: String) async throws -> [T] {
        try await client.from(table).select().execute().value
    }

    func fetch<T: Decodable>(_ table: String, eq column: String, value: String) async throws -> [T] {
        try await client.from(table).select().eq(column, value: value).execute().value
    }

    func fetchSingle<T: Decodable>(_ table: String, eq column: String, value: String) async throws -> T? {
        let results: [T] = try await client.from(table).select().eq(column, value: value).limit(1).execute().value
        return results.first
    }

    func insert<T: Encodable>(_ table: String, value: T) async throws {
        try await client.from(table).insert(value).execute()
    }

    func insertReturning<T: Encodable, R: Decodable>(_ table: String, value: T) async throws -> R {
        try await client.from(table).insert(value).select().single().execute().value
    }

    func update<T: Encodable>(_ table: String, value: T, eq column: String, id: String) async throws {
        try await client.from(table).update(value).eq(column, value: id).execute()
    }

    func upsert<T: Encodable>(_ table: String, value: T) async throws {
        try await client.from(table).upsert(value).execute()
    }

    func delete(_ table: String, eq column: String, value: String) async throws {
        try await client.from(table).delete().eq(column, value: value).execute()
    }

    // MARK: - Edge Functions
    func checkDuplicateStudent(firstName: String, lastName: String, phone: String, email: String) async throws -> (isDuplicate: Bool, matchedFields: [String]) {
        struct DupRequest: Encodable {
            let firstName, lastName, phone, email: String
        }
        struct DupResponse: Decodable {
            let isDuplicate: Bool
            let matchedFields: [String]
        }
        let response: DupResponse = try await client.functions.invoke(
            "check-duplicate-student",
            options: .init(body: DupRequest(firstName: firstName, lastName: lastName, phone: phone, email: email))
        )
        return (response.isDuplicate, response.matchedFields)
    }
}

enum AppError: LocalizedError {
    case authFailed
    case notFound
    case duplicateStudent([String])

    var errorDescription: String? {
        switch self {
        case .authFailed: return "Authentication failed"
        case .notFound: return "Not found"
        case .duplicateStudent(let fields): return "Duplicate student found: \(fields.joined(separator: ", "))"
        }
    }
}
