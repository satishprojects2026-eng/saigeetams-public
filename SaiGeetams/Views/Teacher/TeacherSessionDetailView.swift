import SwiftUI

struct TeacherSessionDetailView: View {
    @Environment(ClassStore.self) private var classStore
    let sessionId: UUID
    @State private var activeTab = 0
    @State private var cancelNote = ""
    @State private var subName = ""
    @State private var roster: [(id: UUID, name: String, rsvp: String, status: String?)] = []

    private let tabs = ["Roster", "Materials", "Actions", "Makeup", "Waitlist"]

    var body: some View {
        let session = classStore.sessions.first { $0.id == sessionId }
        let classTitle = classStore.classes.first { $0.id == session?.classId }?.title ?? "Session"
        let ac = AppSettings.Colors.teacherAccent

        ScrollView {
            VStack(spacing: 12) {
                if let s = session {
                    ThemedCard {
                        Text(s.scheduledDate).font(.headline).foregroundStyle(.white)
                        Text("\(s.startTime) - \(s.endTime)").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                        if s.status == .cancelled {
                            Text("CANCELLED").font(.caption).bold().foregroundStyle(.gray)
                        }
                    }
                }

                // Tab picker
                Picker("Tab", selection: $activeTab) {
                    ForEach(0..<tabs.count, id: \.self) { Text(tabs[$0]).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch activeTab {
                case 0: rosterTab
                case 1: materialsTab
                case 2: actionsTab(session: session)
                case 3: makeupTab
                case 4: waitlistTab
                default: EmptyView()
                }
            }
            .padding(16)
            .padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .navigationTitle(classTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Manage attendance, materials, and actions." } } }
        .task { await loadRoster() }
    }

    private var rosterTab: some View {
        VStack(spacing: 4) {
            ForEach(roster, id: \.id) { stu in
                HStack {
                    VStack(alignment: .leading) {
                        Text(stu.name).font(.subheadline).bold().foregroundStyle(.white)
                        Text(stu.rsvp == "coming" ? "RSVP: Yes" : stu.rsvp == "not_coming" ? "RSVP: No" : "No RSVP")
                            .font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    ForEach(["P", "A", "E"], id: \.self) { label in
                        let status = label == "P" ? "present" : label == "A" ? "absent" : "excused"
                        Button {
                            SoundService.shared.playNavigationSound()
                            Task { await classStore.updateAttendance(sessionId: sessionId, studentId: stu.id, status: AttendanceStatus(rawValue: status)!) }
                        } label: {
                            Text(label).font(.headline).bold()
                                .frame(width: 44, height: 44)
                                .foregroundStyle(stu.status == status ? .black : .white)
                                .background(stu.status == status ? AppSettings.Colors.teacherAccent : Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.vertical, 8)
                Divider().background(Color.white.opacity(0.1))
            }
            if roster.isEmpty { Text("No students enrolled").foregroundStyle(.white.opacity(0.4)).padding() }
        }
    }

    private var materialsTab: some View {
        VStack(spacing: 8) {
            ForEach(classStore.materials) { m in
                ThemedCard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(m.title).font(.subheadline).bold().foregroundStyle(.white)
                            Text(m.fileType?.rawValue ?? "file").font(.caption).foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                    }
                }
            }
            ThemedButton("Upload Material", color: AppSettings.Colors.teacherAccent, textColor: .black) {}
        }
    }

    private func actionsTab(session: ClassSession?) -> some View {
        VStack(spacing: 12) {
            ThemedCard {
                Text("Cancel Class").font(.subheadline).bold().foregroundStyle(AppSettings.Colors.teacherAccent)
                TextField("Cancellation note...", text: $cancelNote)
                    .foregroundStyle(.white).padding(12)
                    .background(Color.white.opacity(0.06)).cornerRadius(10)
                ThemedButton("Cancel Session", color: AppSettings.Colors.atRisk) {
                    Task { await classStore.cancelSession(sessionId: sessionId, note: cancelNote) }
                }
            }
            ThemedCard {
                Text("Assign Substitute").font(.subheadline).bold().foregroundStyle(AppSettings.Colors.teacherAccent)
                TextField("Substitute name...", text: $subName)
                    .foregroundStyle(.white).padding(12)
                    .background(Color.white.opacity(0.06)).cornerRadius(10)
                ThemedButton("Save", color: AppSettings.Colors.teacherAccent, textColor: .black) {}
            }
        }
    }

    private var makeupTab: some View {
        let sessionMakeups = classStore.makeupRequests.filter { $0.sessionId == sessionId }
        return VStack(spacing: 8) {
            if sessionMakeups.isEmpty {
                Text("No makeup requests").foregroundStyle(.white.opacity(0.4)).padding()
            }
            ForEach(sessionMakeups) { req in
                ThemedCard {
                    Text("Reason: \(req.reason ?? "None")").font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    Text(req.status.rawValue.uppercased()).font(.caption).bold()
                        .foregroundStyle(req.status == .approved ? AppSettings.Colors.success : req.status == .declined ? AppSettings.Colors.atRisk : AppSettings.Colors.teacherAccent)
                    if req.status == .pending {
                        HStack(spacing: 8) {
                            ThemedButton("Approve", color: AppSettings.Colors.success) {
                                Task { await classStore.approveMakeup(requestId: req.id, date: dateString(Date())) }
                            }
                            ThemedButton("Decline", color: AppSettings.Colors.atRisk) {
                                Task { await classStore.declineMakeup(requestId: req.id) }
                            }
                        }
                    }
                }
            }
        }
    }

    private var waitlistTab: some View {
        let waitlist = classStore.enrollments.filter { e in
            let session = classStore.sessions.first { $0.id == sessionId }
            return e.classId == session?.classId && e.status == .waitlist
        }
        return VStack(spacing: 8) {
            if waitlist.isEmpty { Text("No waitlist").foregroundStyle(.white.opacity(0.4)).padding() }
            ForEach(waitlist) { e in
                ThemedCard {
                    HStack {
                        Text("Student").foregroundStyle(.white)
                        Spacer()
                        ThemedButton("Enrol", color: AppSettings.Colors.teacherAccent, textColor: .black) {
                            Task { await classStore.approveStudent(enrollmentId: e.id) }
                        }
                    }
                }
            }
        }
    }

    private func loadRoster() async {
        let session = classStore.sessions.first { $0.id == sessionId }
        guard let session else { return }
        let active = classStore.enrollments.filter { $0.classId == session.classId && $0.status == .active }
        let studentIds = active.map(\.studentId)
        var loaded: [(id: UUID, name: String, rsvp: String, status: String?)] = []
        for sid in studentIds {
            let user: AppUser? = try? await SupabaseService.shared.fetchSingle("users", eq: "id", value: sid.uuidString)
            let att: [Attendance] = (try? await SupabaseService.shared.fetch("attendance", eq: "session_id", value: sessionId.uuidString)) ?? []
            let myAtt = att.first { $0.studentId == sid }
            loaded.append((id: sid, name: user?.fullName ?? "Student", rsvp: myAtt?.rsvpStatus.rawValue ?? "no_response", status: myAtt?.actualStatus?.rawValue))
        }
        await MainActor.run { roster = loaded }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
}
