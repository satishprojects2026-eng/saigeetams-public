import SwiftUI

@Observable
final class ClassStore {
    var classes: [ClassGroup] = []
    var sessions: [ClassSession] = []
    var enrollments: [ClassEnrollment] = []
    var attendance: [Attendance] = []
    var makeupRequests: [MakeupRequest] = []
    var practiceLogs: [PracticeLog] = []
    var skills: [StudentSkill] = []
    var badges: [StudentBadge] = []
    var materials: [Material] = []
    var messages: [AppMessage] = []
    var progressNotes: [ProgressNote] = []
    var reportCards: [ReportCard] = []
    var terms: [Term] = []
    var isLoading = false

    private let supa = SupabaseService.shared

    // MARK: - Teacher Data
    func fetchTeacherData(teacherId: UUID) async {
        await MainActor.run { isLoading = true }
        let id = teacherId.uuidString
        async let c: [ClassGroup] = (try? supa.fetch("classes", eq: "teacher_id", value: id)) ?? []
        async let s: [ClassSession] = (try? supa.fetch("class_sessions", eq: "teacher_id", value: id)) ?? []
        async let e: [ClassEnrollment] = (try? supa.fetch("class_enrollments")) ?? []
        async let m: [MakeupRequest] = (try? supa.fetch("makeup_requests", eq: "teacher_id", value: id)) ?? []
        async let t: [Term] = (try? supa.fetch("terms", eq: "teacher_id", value: id)) ?? []
        async let msg: [AppMessage] = (try? supa.fetch("messages", eq: "teacher_id", value: id)) ?? []

        let (rc, rs, re, rm, rt, rmsg) = await (c, s, e, m, t, msg)
        await MainActor.run {
            classes = rc; sessions = rs; enrollments = re
            makeupRequests = rm; terms = rt; messages = rmsg
            isLoading = false
        }
    }

    // MARK: - Create Class
    func createClass(teacherId: UUID, title: String, description: String?, colorCode: String?) async throws -> ClassGroup {
        struct Insert: Encodable {
            let teacher_id: UUID; let title: String; let description: String?; let color_code: String?
            let is_active: Bool
        }
        let newClass: ClassGroup = try await supa.insertReturning("classes", value: Insert(
            teacher_id: teacherId, title: title, description: description,
            color_code: colorCode, is_active: true
        ))
        await MainActor.run { classes.append(newClass) }
        return newClass
    }

    // MARK: - Create Session
    func createSession(_ session: ClassSession) async throws {
        struct Insert: Encodable {
            let class_id: UUID; let teacher_id: UUID; let term_id: UUID?
            let scheduled_date: String; let start_time: String; let end_time: String
            let status: String; let live_link: String?; let substitute_name: String?
        }
        let s: ClassSession = try await supa.insertReturning("class_sessions", value: Insert(
            class_id: session.classId, teacher_id: session.teacherId, term_id: session.termId,
            scheduled_date: session.scheduledDate, start_time: session.startTime, end_time: session.endTime,
            status: session.status.rawValue, live_link: session.liveLink, substitute_name: session.substituteName
        ))
        await MainActor.run { sessions.append(s) }
    }

    // MARK: - Attendance
    func updateAttendance(sessionId: UUID, studentId: UUID, status: AttendanceStatus) async {
        struct Upsert: Encodable {
            let session_id: UUID; let student_id: UUID
            let actual_status: String; let marked_at: String
        }
        try? await supa.upsert("attendance", value: Upsert(
            session_id: sessionId, student_id: studentId,
            actual_status: status.rawValue,
            marked_at: ISO8601DateFormatter().string(from: Date())
        ))
    }

    // MARK: - Approve / Reject
    func approveStudent(enrollmentId: UUID) async {
        struct StatusUpdate: Encodable { let status: String }
        try? await supa.update("class_enrollments", value: StatusUpdate(status: "active"), eq: "id", id: enrollmentId.uuidString)
        await MainActor.run {
            if let i = enrollments.firstIndex(where: { $0.id == enrollmentId }) {
                enrollments[i].status = .active
            }
        }
    }

    func rejectStudent(enrollmentId: UUID) async {
        struct StatusUpdate: Encodable { let status: String }
        try? await supa.update("class_enrollments", value: StatusUpdate(status: "removed"), eq: "id", id: enrollmentId.uuidString)
        await MainActor.run { enrollments.removeAll { $0.id == enrollmentId } }
    }

    // MARK: - Cancel Session
    func cancelSession(sessionId: UUID, note: String) async {
        struct CancelUpdate: Encodable { let status: String; let cancellation_note: String }
        try? await supa.update("class_sessions", value: CancelUpdate(status: "cancelled", cancellation_note: note), eq: "id", id: sessionId.uuidString)
        await MainActor.run {
            if let i = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[i].status = .cancelled
                sessions[i].cancellationNote = note
            }
        }
    }

    // MARK: - Makeup
    func approveMakeup(requestId: UUID, date: String) async {
        struct MakeupUpdate: Encodable { let status: String; let makeup_date: String }
        try? await supa.update("makeup_requests", value: MakeupUpdate(status: "approved", makeup_date: date), eq: "id", id: requestId.uuidString)
        await MainActor.run {
            if let i = makeupRequests.firstIndex(where: { $0.id == requestId }) {
                makeupRequests[i].status = .approved
                makeupRequests[i].makeupDate = date
            }
        }
    }

    func declineMakeup(requestId: UUID) async {
        struct StatusUpdate: Encodable { let status: String }
        try? await supa.update("makeup_requests", value: StatusUpdate(status: "declined"), eq: "id", id: requestId.uuidString)
        await MainActor.run {
            if let i = makeupRequests.firstIndex(where: { $0.id == requestId }) {
                makeupRequests[i].status = .declined
            }
        }
    }

    // MARK: - Create Term
    func createTerm(teacherId: UUID, name: String, startDate: String, endDate: String) async throws {
        struct Insert: Encodable {
            let teacher_id: UUID; let name: String; let start_date: String; let end_date: String
        }
        let t: Term = try await supa.insertReturning("terms", value: Insert(
            teacher_id: teacherId, name: name, start_date: startDate, end_date: endDate
        ))
        await MainActor.run { terms.append(t) }
    }

    // MARK: - Student Data
    func fetchStudentData(studentId: UUID) async {
        await MainActor.run { isLoading = true }
        let id = studentId.uuidString
        async let e: [ClassEnrollment] = (try? supa.fetch("class_enrollments", eq: "student_id", value: id)) ?? []
        async let s: [ClassSession] = (try? supa.fetch("class_sessions")) ?? []
        async let a: [Attendance] = (try? supa.fetch("attendance", eq: "student_id", value: id)) ?? []
        async let p: [PracticeLog] = (try? supa.fetch("practice_logs", eq: "student_id", value: id)) ?? []
        async let sk: [StudentSkill] = (try? supa.fetch("student_skills", eq: "student_id", value: id)) ?? []
        async let b: [StudentBadge] = (try? supa.fetch("student_badges", eq: "student_id", value: id)) ?? []
        async let msg: [AppMessage] = (try? supa.fetch("messages")) ?? []
        async let n: [ProgressNote] = (try? supa.fetch("progress_notes", eq: "student_id", value: id)) ?? []
        async let r: [ReportCard] = (try? supa.fetch("report_cards", eq: "student_id", value: id)) ?? []

        let (re, rs, ra, rp, rsk, rb, rmsg, rn, rr) = await (e, s, a, p, sk, b, msg, n, r)
        await MainActor.run {
            enrollments = re; sessions = rs; attendance = ra
            practiceLogs = rp; skills = rsk; badges = rb
            messages = rmsg; progressNotes = rn; reportCards = rr
            isLoading = false
        }
    }

    // MARK: - RSVP
    func updateRSVP(sessionId: UUID, studentId: UUID, status: RSVPStatus) async {
        struct Upsert: Encodable {
            let session_id: UUID; let student_id: UUID
            let rsvp_status: String; let rsvp_updated_at: String
        }
        try? await supa.upsert("attendance", value: Upsert(
            session_id: sessionId, student_id: studentId,
            rsvp_status: status.rawValue,
            rsvp_updated_at: ISO8601DateFormatter().string(from: Date())
        ))
    }

    // MARK: - Makeup Request
    func submitMakeupRequest(sessionId: UUID, studentId: UUID, teacherId: UUID, reason: String) async throws {
        struct Insert: Encodable {
            let session_id: UUID; let student_id: UUID; let teacher_id: UUID; let reason: String
        }
        let req: MakeupRequest = try await supa.insertReturning("makeup_requests", value: Insert(
            session_id: sessionId, student_id: studentId, teacher_id: teacherId, reason: reason
        ))
        await MainActor.run { makeupRequests.append(req) }
    }

    // MARK: - Practice
    func logPractice(studentId: UUID, teacherId: UUID, duration: Int, notes: String) async throws {
        struct Insert: Encodable {
            let student_id: UUID; let teacher_id: UUID
            let log_date: String; let duration_min: Int; let notes: String
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let log: PracticeLog = try await supa.insertReturning("practice_logs", value: Insert(
            student_id: studentId, teacher_id: teacherId,
            log_date: formatter.string(from: Date()), duration_min: duration, notes: notes
        ))
        await MainActor.run { practiceLogs.insert(log, at: 0) }
    }

    // MARK: - Parent Data
    func fetchParentData(studentId: UUID) async {
        await MainActor.run { isLoading = true }
        let id = studentId.uuidString
        async let s: [ClassSession] = (try? supa.fetch("class_sessions")) ?? []
        async let a: [Attendance] = (try? supa.fetch("attendance", eq: "student_id", value: id)) ?? []
        async let sk: [StudentSkill] = (try? supa.fetch("student_skills", eq: "student_id", value: id)) ?? []
        async let n: [ProgressNote] = (try? supa.fetch("progress_notes", eq: "student_id", value: id)) ?? []
        async let r: [ReportCard] = (try? supa.fetch("report_cards", eq: "student_id", value: id)) ?? []
        async let b: [StudentBadge] = (try? supa.fetch("student_badges", eq: "student_id", value: id)) ?? []
        async let msg: [AppMessage] = (try? supa.fetch("messages")) ?? []

        let (rs, ra, rsk, rn, rr, rb, rmsg) = await (s, a, sk, n, r, b, msg)
        await MainActor.run {
            sessions = rs; attendance = ra; skills = rsk
            progressNotes = rn; reportCards = rr; badges = rb; messages = rmsg
            isLoading = false
        }
    }

    // MARK: - Materials
    func fetchSessionMaterials(sessionId: UUID) async {
        let mats: [Material] = (try? await supa.fetch("materials", eq: "session_id", value: sessionId.uuidString)) ?? []
        await MainActor.run { materials = mats }
    }

    // MARK: - Send Message
    func sendMessage(teacherId: UUID, classId: UUID?, type: MessageType, title: String?, content: String, requiresAck: Bool) async throws {
        struct Insert: Encodable {
            let teacher_id: UUID; let class_id: UUID?; let type: String
            let title: String?; let content: String; let requires_ack: Bool
        }
        let msg: AppMessage = try await supa.insertReturning("messages", value: Insert(
            teacher_id: teacherId, class_id: classId, type: type.rawValue,
            title: title, content: content, requires_ack: requiresAck
        ))
        await MainActor.run { messages.insert(msg, at: 0) }
    }
}
