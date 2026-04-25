import SwiftUI

// MARK: - Classes
struct TeacherClassesView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore
    @State private var showCreate = false
    @State private var newTitle = ""
    @State private var newDesc = ""

    var body: some View {
        let ac = AppSettings.Colors.teacherAccent
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    NavigationLink(destination: TeacherTermEnrollView()) {
                        Text("Term Enrollment").font(.caption).bold().frame(maxWidth: .infinity, minHeight: 36)
                            .foregroundStyle(.white).background(AppSettings.Colors.teacherPrimary).cornerRadius(8)
                    }
                    NavigationLink(destination: TeacherMakeupView()) {
                        Text("Makeup Mgmt").font(.caption).bold().frame(maxWidth: .infinity, minHeight: 36)
                            .foregroundStyle(.white).background(AppSettings.Colors.teacherPrimary).cornerRadius(8)
                    }
                }

                ForEach(classStore.classes) { cls in
                    let count = classStore.enrollments.filter { $0.classId == cls.id && $0.status == .active }.count
                    ThemedCard {
                        HStack {
                            Text(cls.title).font(.headline).foregroundStyle(.white)
                            Spacer()
                        }
                        if let desc = cls.description { Text(desc).font(.caption).foregroundStyle(.white.opacity(0.5)) }
                        Text("\(count) students").font(.caption).foregroundStyle(.white.opacity(0.6))
                    }
                }

                if showCreate {
                    ThemedCard {
                        Text("New Class").font(.headline).foregroundStyle(ac)
                        ThemedInput(label: "Title", text: $newTitle, accentColor: ac)
                        ThemedInput(label: "Description", text: $newDesc, accentColor: ac)
                        HStack(spacing: 8) {
                            GhostButton(title: "Cancel", color: ac) { showCreate = false }
                            ThemedButton("Create", color: ac, textColor: .black) {
                                Task {
                                    try? await classStore.createClass(teacherId: authStore.user!.id, title: newTitle, description: newDesc.isEmpty ? nil : newDesc, colorCode: nil)
                                    showCreate = false; newTitle = ""; newDesc = ""
                                }
                            }
                        }
                    }
                } else {
                    ThemedButton("+ Create Class", color: ac, textColor: .black) { SoundService.shared.playNavigationSound(); showCreate = true }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Manage your class groups." } } }
    }
}

// MARK: - Students
struct TeacherStudentsView: View {
    @Environment(ClassStore.self) private var classStore
    @State private var search = ""
    @State private var students: [AppUser] = []

    var body: some View {
        let pending = classStore.enrollments.filter { $0.status == .pending }
        let filtered = students.filter { search.isEmpty || $0.fullName.localizedCaseInsensitiveContains(search) }

        ScrollView {
            VStack(spacing: 12) {
                ThemedInput(label: "Search", text: $search, placeholder: "Search students...", accentColor: AppSettings.Colors.teacherAccent)

                if !pending.isEmpty {
                    AppHeader(title: "Pending Approvals", bgColor: .clear, textColor: AppSettings.Colors.teacherAccent)
                    ForEach(pending) { e in
                        let stu = students.first { $0.id == e.studentId }
                        ThemedCard {
                            Text(stu?.fullName ?? "Loading...").foregroundStyle(.white)
                            HStack(spacing: 8) {
                                ThemedButton("Approve", color: AppSettings.Colors.success) { Task { await classStore.approveStudent(enrollmentId: e.id) } }
                                ThemedButton("Reject", color: AppSettings.Colors.atRisk) { Task { await classStore.rejectStudent(enrollmentId: e.id) } }
                            }
                        }
                    }
                }

                AppHeader(title: "All Students (\(filtered.count))", bgColor: .clear, textColor: AppSettings.Colors.teacherAccent)
                ForEach(filtered) { stu in
                    NavigationLink(destination: TeacherStudentProfileView(studentId: stu.id)) {
                        ThemedCard {
                            Text(stu.fullName).font(.headline).foregroundStyle(.white)
                            Text(stu.email ?? "").font(.caption).foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .task { await loadStudents() }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Manage students and approvals." } } }
    }

    private func loadStudents() async {
        let ids = Array(Set(classStore.enrollments.map(\.studentId)))
        var loaded: [AppUser] = []
        for id in ids {
            if let u: AppUser = try? await SupabaseService.shared.fetchSingle("users", eq: "id", value: id.uuidString) {
                loaded.append(u)
            }
        }
        await MainActor.run { students = loaded }
    }
}

// MARK: - Student Profile
struct TeacherStudentProfileView: View {
    let studentId: UUID
    @Environment(ClassStore.self) private var classStore
    @State private var student: AppUser?
    @State private var parent: ParentGuardian?
    @State private var notes: [ProgressNote] = []
    @State private var skills: [StudentSkill] = []
    @State private var reports: [ReportCard] = []
    @State private var activeTab = 0
    @State private var newNote = ""

    var body: some View {
        let ac = AppSettings.Colors.teacherAccent
        ScrollView {
            VStack(spacing: 12) {
                Picker("Tab", selection: $activeTab) {
                    Text("Info").tag(0); Text("Notes").tag(1); Text("Skills").tag(2); Text("Report").tag(3)
                }.pickerStyle(.segmented).padding(.horizontal)

                switch activeTab {
                case 0:
                    if let s = student {
                        ThemedCard { Text("Email: \(s.email ?? "N/A")").foregroundStyle(.white); Text("DOB: \(s.dob ?? "N/A")").foregroundStyle(.white) }
                    }
                    if let p = parent {
                        ThemedCard {
                            Text("Parent").font(.headline).foregroundStyle(ac)
                            Text("\(p.name) (\(p.relationship))").foregroundStyle(.white)
                            Text("Phone: \(p.phone)").foregroundStyle(.white.opacity(0.7))
                            Text("Emergency: \(p.emergencyContact)").foregroundStyle(.white.opacity(0.7))
                        }
                    }
                case 1:
                    ThemedCard {
                        TextField("Add a progress note...", text: $newNote, axis: .vertical)
                            .foregroundStyle(.white).lineLimit(3...6)
                        ThemedButton("Add Note", color: ac, textColor: .black) {
                            Task { await addNote() }
                        }
                    }
                    ForEach(notes) { n in
                        ThemedCard {
                            Text(n.noteDate).font(.caption).foregroundStyle(ac)
                            Text(n.note).foregroundStyle(.white.opacity(0.7))
                        }
                    }
                case 2:
                    ForEach(skills) { skill in
                        SkillBarView(skillName: skill.skillName, level: skill.level) { newLevel in
                            Task {
                                struct LevelUpdate: Encodable { let level: Int }
                                try? await SupabaseService.shared.update("student_skills", value: LevelUpdate(level: newLevel), eq: "id", id: skill.id.uuidString)
                                await loadProfile()
                            }
                        }
                    }
                    if skills.isEmpty { Text("No skills defined").foregroundStyle(.white.opacity(0.4)).padding() }
                case 3:
                    ForEach(reports) { r in
                        ThemedCard {
                            Text(r.termName).font(.headline).foregroundStyle(ac)
                            Text("Grade: \(r.overallGrade ?? "N/A")").foregroundStyle(.white)
                            Text("Attendance: \(r.attendancePct ?? 0, specifier: "%.0f")%").foregroundStyle(.white)
                            if let c = r.comments { Text(c).font(.caption).foregroundStyle(.white.opacity(0.7)).italic() }
                        }
                    }
                default: EmptyView()
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .navigationTitle(student?.fullName ?? "Student")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadProfile() }
    }

    private func loadProfile() async {
        let supa = SupabaseService.shared
        let id = studentId.uuidString
        student = try? await supa.fetchSingle("users", eq: "id", value: id)
        parent = try? await supa.fetchSingle("parent_guardians", eq: "student_id", value: id)
        notes = (try? await supa.fetch("progress_notes", eq: "student_id", value: id)) ?? []
        skills = (try? await supa.fetch("student_skills", eq: "student_id", value: id)) ?? []
        reports = (try? await supa.fetch("report_cards", eq: "student_id", value: id)) ?? []
    }

    private func addNote() async {
        guard !newNote.isEmpty, let teacherId = await SupabaseService.shared.currentUserId else { return }
        struct Insert: Encodable { let student_id: UUID; let teacher_id: UUID; let note_date: String; let note: String }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        try? await SupabaseService.shared.insert("progress_notes", value: Insert(
            student_id: studentId, teacher_id: teacherId, note_date: f.string(from: Date()), note: newNote))
        newNote = ""
        await loadProfile()
    }
}

// MARK: - Analytics
struct TeacherAnalyticsView: View {
    @Environment(ClassStore.self) private var classStore
    @State private var atRisk: [AtRiskStudent] = []

    var body: some View {
        let ac = AppSettings.Colors.teacherAccent
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ThemedCard { VStack { Text("\(classStore.enrollments.filter { $0.status == .active }.count)").font(.title).bold().foregroundStyle(ac); Text("Students").font(.caption).foregroundStyle(.white.opacity(0.5)) }.frame(maxWidth: .infinity) }
                    ThemedCard { VStack { Text("\(classStore.sessions.count)").font(.title).bold().foregroundStyle(ac); Text("Sessions").font(.caption).foregroundStyle(.white.opacity(0.5)) }.frame(maxWidth: .infinity) }
                    ThemedCard { VStack { Text("\(classStore.classes.count)").font(.title).bold().foregroundStyle(ac); Text("Classes").font(.caption).foregroundStyle(.white.opacity(0.5)) }.frame(maxWidth: .infinity) }
                }

                AppHeader(title: "At-Risk Students", bgColor: .clear, textColor: AppSettings.Colors.atRisk)
                if atRisk.isEmpty { Text("No at-risk students").foregroundStyle(.white.opacity(0.4)).padding() }
                ForEach(atRisk) { s in
                    ThemedCard(bgColor: AppSettings.Colors.atRisk.opacity(0.1)) {
                        Text("\(s.firstName) \(s.lastName)").font(.headline).foregroundStyle(.white)
                        Text("\(s.absencesLast30Days) absences in 30 days").font(.caption).foregroundStyle(AppSettings.Colors.atRisk)
                    }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .navigationTitle("Analytics").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let data: [AtRiskStudent] = (try? await SupabaseService.shared.fetch("at_risk_students")) ?? []
            await MainActor.run { atRisk = data }
        }
    }
}

// MARK: - Term Enrollment
struct TeacherTermEnrollView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore
    @State private var showCreate = false
    @State private var name = ""; @State private var startDate = ""; @State private var endDate = ""

    var body: some View {
        let ac = AppSettings.Colors.teacherAccent
        let today = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }()
        ScrollView {
            VStack(spacing: 12) {
                ForEach(classStore.terms) { term in
                    let isActive = term.startDate <= today && term.endDate >= today
                    let isUpcoming = term.startDate > today
                    ThemedCard {
                        HStack {
                            Text(term.name).font(.headline).foregroundStyle(.white)
                            Spacer()
                            Text(isActive ? "Active" : isUpcoming ? "Upcoming" : "Past")
                                .font(.caption).bold().foregroundStyle(isActive ? AppSettings.Colors.success : isUpcoming ? ac : .gray)
                        }
                        Text("\(term.startDate) to \(term.endDate)").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                }
                if showCreate {
                    ThemedCard {
                        ThemedInput(label: "Name", text: $name, accentColor: ac)
                        ThemedInput(label: "Start (YYYY-MM-DD)", text: $startDate, accentColor: ac)
                        ThemedInput(label: "End (YYYY-MM-DD)", text: $endDate, accentColor: ac)
                        ThemedButton("Create", color: ac, textColor: .black) {
                            Task { try? await classStore.createTerm(teacherId: authStore.user!.id, name: name, startDate: startDate, endDate: endDate); showCreate = false }
                        }
                    }
                } else {
                    ThemedButton("+ Create Term", color: ac, textColor: .black) { showCreate = true }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .navigationTitle("Term Enrollment").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Makeup Management
struct TeacherMakeupView: View {
    @Environment(ClassStore.self) private var classStore

    var body: some View {
        let pending = classStore.makeupRequests.filter { $0.status == .pending }
        ScrollView {
            VStack(spacing: 12) {
                if pending.isEmpty { Text("No pending makeup requests").foregroundStyle(.white.opacity(0.4)).padding(40) }
                ForEach(pending) { req in
                    ThemedCard {
                        Text("Reason: \(req.reason ?? "None")").foregroundStyle(.white.opacity(0.7))
                        HStack(spacing: 8) {
                            ThemedButton("Approve", color: AppSettings.Colors.success) {
                                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                                Task { await classStore.approveMakeup(requestId: req.id, date: f.string(from: Date())) }
                            }
                            ThemedButton("Decline", color: AppSettings.Colors.atRisk) { Task { await classStore.declineMakeup(requestId: req.id) } }
                        }
                    }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .navigationTitle("Makeup Management").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Communications
struct TeacherCommsView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore
    @State private var activeTab = 0
    @State private var msgType = 0
    @State private var title = ""; @State private var content = ""
    @State private var requiresAck = false; @State private var sending = false

    let types = ["Announcement", "Cancellation", "Poll", "General"]

    var body: some View {
        let ac = AppSettings.Colors.teacherAccent
        ScrollView {
            VStack(spacing: 12) {
                Picker("Tab", selection: $activeTab) { Text("Compose").tag(0); Text("History").tag(1) }.pickerStyle(.segmented)

                if activeTab == 0 {
                    Picker("Type", selection: $msgType) { ForEach(0..<types.count, id: \.self) { Text(types[$0]).tag($0) } }.pickerStyle(.segmented)
                    ThemedInput(label: "Title (optional)", text: $title, accentColor: ac)
                    Text("Content").font(.subheadline).bold().foregroundStyle(ac).frame(maxWidth: .infinity, alignment: .leading)
                    TextEditor(text: $content)
                        .frame(minHeight: 120).foregroundStyle(.white).scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.06)).cornerRadius(12)
                    Toggle("Requires Acknowledgement", isOn: $requiresAck).tint(ac).foregroundStyle(.white)
                    ThemedButton("Send Message", color: AppSettings.Colors.teacherPrimary, isLoading: sending) {
                        guard !content.isEmpty else { return }; sending = true
                        Task {
                            let t = MessageType(rawValue: types[msgType].lowercased()) ?? .general
                            try? await classStore.sendMessage(teacherId: authStore.user!.id, classId: classStore.classes.first?.id, type: t, title: title.isEmpty ? nil : title, content: content, requiresAck: requiresAck)
                            await SoundService.shared.playAnnouncementMelody()
                            sending = false; title = ""; content = ""
                        }
                    }
                } else {
                    ForEach(classStore.messages) { msg in
                        ThemedCard {
                            HStack {
                                Text(msg.type.rawValue.uppercased()).font(.caption2).bold().foregroundStyle(ac)
                                Spacer()
                                Text(msg.createdAt?.prefix(10) ?? "").font(.caption2).foregroundStyle(.white.opacity(0.4))
                            }
                            if let t = msg.title { Text(t).font(.headline).foregroundStyle(.white) }
                            Text(msg.content).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    if classStore.messages.isEmpty { Text("No messages sent").foregroundStyle(.white.opacity(0.4)).padding() }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .navigationTitle("Communications").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Settings
struct TeacherSettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var navSounds = AppSettings.navigationSounds
    @State private var annSounds = AppSettings.announcementSounds
    @State private var showDeleteAlert = false

    var body: some View {
        let ac = AppSettings.Colors.teacherAccent
        ScrollView {
            VStack(spacing: 12) {
                ThemedCard {
                    Text("Profile").font(.headline).foregroundStyle(ac)
                    Text("Name: \(authStore.user?.fullName ?? "")").foregroundStyle(.white)
                    Text("Email: \(authStore.user?.email ?? "")").foregroundStyle(.white)
                    Text("Phone: \(authStore.user?.phone ?? "N/A")").foregroundStyle(.white)
                }
                ThemedCard {
                    Text("Sounds").font(.headline).foregroundStyle(ac)
                    Toggle("Navigation Sounds", isOn: $navSounds).tint(ac).foregroundStyle(.white)
                    Toggle("Announcement Melody", isOn: $annSounds).tint(ac).foregroundStyle(.white)
                }
                ThemedCard {
                    Text("Calendar Sync").font(.headline).foregroundStyle(ac)
                    ThemedButton("Sync to Apple Calendar", color: AppSettings.Colors.teacherPrimary) {}
                }
                OutlineButton(title: "Sign Out", color: ac) { Task { await authStore.signOut() } }
                    .padding(.top, 24)
                GhostButton(title: "Delete Account", color: AppSettings.Colors.atRisk) { showDeleteAlert = true }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.teacherBg.ignoresSafeArea())
        .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { Task { await authStore.deleteAccount() } }
        } message: { Text("This permanently deletes your account, classes, sessions, and materials.") }
    }
}
