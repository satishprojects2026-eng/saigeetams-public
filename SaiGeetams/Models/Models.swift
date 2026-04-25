import Foundation

// MARK: - Enums
enum UserRole: String, Codable {
    case teacher, student
}

enum SessionStatus: String, Codable {
    case active, cancelled, rescheduled
}

enum EnrollmentStatus: String, Codable {
    case active, pending, removed, transferred, waitlist
}

enum RSVPStatus: String, Codable {
    case coming, notComing = "not_coming", noResponse = "no_response"
}

enum AttendanceStatus: String, Codable {
    case present, absent, excused
}

enum MakeupStatus: String, Codable {
    case pending, approved, declined
}

enum MessageType: String, Codable {
    case announcement, poll, cancellation, general
}

enum MessageResponse: String, Codable {
    case acknowledged, accepted, rejected
}

enum FileType: String, Codable {
    case image, pdf, note, audio, video
}

// MARK: - User
struct AppUser: Codable, Identifiable {
    let id: UUID
    var role: UserRole
    var email: String?
    var phone: String?
    var firstName: String
    var lastName: String
    var profilePhoto: String?
    var dob: String?
    var isVerified: Bool
    var isApproved: Bool
    var pinHash: String?
    var biometricsKey: String?
    var createdAt: String?
    var updatedAt: String?
    var deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, role, email, phone, dob
        case firstName = "first_name"
        case lastName = "last_name"
        case profilePhoto = "profile_photo"
        case isVerified = "is_verified"
        case isApproved = "is_approved"
        case pinHash = "pin_hash"
        case biometricsKey = "biometrics_key"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - Parent Guardian
struct ParentGuardian: Codable, Identifiable {
    let id: UUID
    var studentId: UUID
    var userId: UUID?
    var name: String
    var relationship: String
    var phone: String
    var email: String?
    var emergencyContact: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, relationship, phone, email
        case studentId = "student_id"
        case userId = "user_id"
        case emergencyContact = "emergency_contact"
        case createdAt = "created_at"
    }
}

// MARK: - Consent Form
struct ConsentForm: Codable, Identifiable {
    let id: UUID
    var studentId: UUID
    var signedBy: String
    var relationship: String
    var signedAt: String?
    var formVersion: String
    var signatureData: String
    var ipAddress: String?

    enum CodingKeys: String, CodingKey {
        case id, relationship
        case studentId = "student_id"
        case signedBy = "signed_by"
        case signedAt = "signed_at"
        case formVersion = "form_version"
        case signatureData = "signature_data"
        case ipAddress = "ip_address"
    }
}

// MARK: - Class
struct ClassGroup: Codable, Identifiable {
    let id: UUID
    var teacherId: UUID
    var title: String
    var description: String?
    var colorCode: String?
    var isActive: Bool
    var createdAt: String?
    var deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case teacherId = "teacher_id"
        case colorCode = "color_code"
        case isActive = "is_active"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Term
struct Term: Codable, Identifiable {
    let id: UUID
    var teacherId: UUID
    var name: String
    var startDate: String
    var endDate: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case teacherId = "teacher_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
    }
}

// MARK: - Class Session
struct ClassSession: Codable, Identifiable {
    let id: UUID
    var classId: UUID
    var teacherId: UUID
    var termId: UUID?
    var scheduledDate: String
    var startTime: String
    var endTime: String
    var status: SessionStatus
    var cancellationNote: String?
    var liveLink: String?
    var substituteName: String?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case classId = "class_id"
        case teacherId = "teacher_id"
        case termId = "term_id"
        case scheduledDate = "scheduled_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case cancellationNote = "cancellation_note"
        case liveLink = "live_link"
        case substituteName = "substitute_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Class Enrollment
struct ClassEnrollment: Codable, Identifiable {
    let id: UUID
    var classId: UUID
    var studentId: UUID
    var termId: UUID?
    var status: EnrollmentStatus
    var enrolledAt: String?
    var removedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case classId = "class_id"
        case studentId = "student_id"
        case termId = "term_id"
        case enrolledAt = "enrolled_at"
        case removedAt = "removed_at"
    }
}

// MARK: - Attendance
struct Attendance: Codable, Identifiable {
    let id: UUID
    var sessionId: UUID
    var studentId: UUID
    var rsvpStatus: RSVPStatus
    var actualStatus: AttendanceStatus?
    var absenceReason: String?
    var rsvpUpdatedAt: String?
    var markedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case studentId = "student_id"
        case rsvpStatus = "rsvp_status"
        case actualStatus = "actual_status"
        case absenceReason = "absence_reason"
        case rsvpUpdatedAt = "rsvp_updated_at"
        case markedAt = "marked_at"
    }
}

// MARK: - Makeup Request
struct MakeupRequest: Codable, Identifiable {
    let id: UUID
    var sessionId: UUID
    var studentId: UUID
    var teacherId: UUID
    var reason: String?
    var status: MakeupStatus
    var makeupDate: String?
    var makeupSessionId: UUID?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, reason, status
        case sessionId = "session_id"
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case makeupDate = "makeup_date"
        case makeupSessionId = "makeup_session_id"
        case createdAt = "created_at"
    }
}

// MARK: - Practice Log
struct PracticeLog: Codable, Identifiable {
    let id: UUID
    var studentId: UUID
    var teacherId: UUID
    var logDate: String
    var durationMin: Int
    var notes: String?
    var approved: Bool?
    var approvedAt: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, notes, approved
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case logDate = "log_date"
        case durationMin = "duration_min"
        case approvedAt = "approved_at"
        case createdAt = "created_at"
    }
}

// MARK: - Progress Note
struct ProgressNote: Codable, Identifiable {
    let id: UUID
    var studentId: UUID
    var teacherId: UUID
    var sessionId: UUID?
    var noteDate: String
    var note: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, note
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case sessionId = "session_id"
        case noteDate = "note_date"
        case createdAt = "created_at"
    }
}

// MARK: - Student Skill
struct StudentSkill: Codable, Identifiable {
    let id: UUID
    var studentId: UUID
    var teacherId: UUID
    var skillName: String
    var level: Int
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, level
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case skillName = "skill_name"
        case updatedAt = "updated_at"
    }
}

// MARK: - Student Badge
struct StudentBadge: Codable, Identifiable {
    let id: UUID
    var studentId: UUID
    var badgeId: String
    var earnedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case studentId = "student_id"
        case badgeId = "badge_id"
        case earnedAt = "earned_at"
    }
}

// MARK: - Report Card
struct ReportCard: Codable, Identifiable {
    let id: UUID
    var studentId: UUID
    var teacherId: UUID
    var termId: UUID?
    var termName: String
    var attendancePct: Double?
    var overallGrade: String?
    var comments: String?
    var skillGrades: [String: String]?
    var isShared: Bool
    var sharedAt: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, comments
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case termId = "term_id"
        case termName = "term_name"
        case attendancePct = "attendance_pct"
        case overallGrade = "overall_grade"
        case skillGrades = "skill_grades"
        case isShared = "is_shared"
        case sharedAt = "shared_at"
        case createdAt = "created_at"
    }
}

// MARK: - Message
struct AppMessage: Codable, Identifiable {
    let id: UUID
    var teacherId: UUID
    var classId: UUID?
    var type: MessageType
    var title: String?
    var content: String
    var requiresAck: Bool
    var pollOptions: [String]?
    var createdAt: String?
    var expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id, type, title, content
        case teacherId = "teacher_id"
        case classId = "class_id"
        case requiresAck = "requires_ack"
        case pollOptions = "poll_options"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

// MARK: - Message Response
struct MessageResponseRow: Codable, Identifiable {
    let id: UUID
    var messageId: UUID
    var studentId: UUID
    var response: MessageResponse?
    var pollChoice: String?
    var respondedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, response
        case messageId = "message_id"
        case studentId = "student_id"
        case pollChoice = "poll_choice"
        case respondedAt = "responded_at"
    }
}

// MARK: - Material
struct Material: Codable, Identifiable {
    let id: UUID
    var sessionId: UUID
    var teacherId: UUID
    var title: String
    var fileUrl: String
    var fileType: FileType?
    var fileSizeKb: Int?
    var isActive: Bool
    var createdAt: String?
    var deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case sessionId = "session_id"
        case teacherId = "teacher_id"
        case fileUrl = "file_url"
        case fileType = "file_type"
        case fileSizeKb = "file_size_kb"
        case isActive = "is_active"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Submission
struct Submission: Codable, Identifiable {
    let id: UUID
    var sessionId: UUID
    var studentId: UUID
    var teacherId: UUID
    var fileUrl: String
    var fileType: String?
    var fileSizeKb: Int?
    var teacherNote: String?
    var submittedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case fileUrl = "file_url"
        case fileType = "file_type"
        case fileSizeKb = "file_size_kb"
        case teacherNote = "teacher_note"
        case submittedAt = "submitted_at"
    }
}

// MARK: - Invitation Link
struct InvitationLink: Codable, Identifiable {
    let id: UUID
    var classId: UUID
    var teacherId: UUID
    var token: String
    var expiresAt: String
    var maxUses: Int
    var usedCount: Int
    var isActive: Bool
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, token
        case classId = "class_id"
        case teacherId = "teacher_id"
        case expiresAt = "expires_at"
        case maxUses = "max_uses"
        case usedCount = "used_count"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - Push Token
struct PushToken: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var token: String
    var platform: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, token, platform
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - At Risk Student (View)
struct AtRiskStudent: Codable, Identifiable {
    var id: UUID { studentId }
    var studentId: UUID
    var firstName: String
    var lastName: String
    var absencesLast30Days: Int

    enum CodingKeys: String, CodingKey {
        case studentId = "student_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case absencesLast30Days = "absences_last_30_days"
    }
}
