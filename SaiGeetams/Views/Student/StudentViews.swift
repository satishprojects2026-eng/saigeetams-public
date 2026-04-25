import SwiftUI

// MARK: - Student Calendar (Home)
struct StudentCalendarView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore
    @State private var selectedDate = ""

    var body: some View {
        let ac = AppSettings.Colors.studentAccent
        let bg = AppSettings.Colors.studentBg
        let earnedIds = Set(classStore.badges.map(\.badgeId))
        let presentCount = classStore.attendance.filter { $0.actualStatus == .present }.count
        let daySessions = classStore.sessions.filter { $0.scheduledDate == selectedDate }

        ScrollView {
            VStack(spacing: 12) {
                Text("\(presentCount) classes attended").font(.subheadline).bold().foregroundStyle(ac)

                if !earnedIds.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AppSettings.badgeDefinitions.filter { earnedIds.contains($0.id) }) { b in
                                Text(b.icon).font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(ac.opacity(0.15)).clipShape(Circle())
                            }
                        }
                    }
                }

                DatePicker("", selection: Binding(
                    get: { dateFromStr(selectedDate) ?? Date() },
                    set: { selectedDate = dateStr($0) }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical).tint(ac).colorScheme(.dark)

                ForEach(daySessions) { session in
                    NavigationLink(destination: StudentSessionDetailView(sessionId: session.id)) {
                        ThemedCard(bgColor: session.status == .cancelled ? Color.gray.opacity(0.2) : Color.white.opacity(0.08)) {
                            Text(session.status == .cancelled ? "Cancelled" : "Class")
                                .font(.headline).foregroundStyle(session.status == .cancelled ? .gray : .white)
                            Text("\(session.startTime) - \(session.endTime)").font(.subheadline).foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                if daySessions.isEmpty && !selectedDate.isEmpty {
                    Text("No classes on this day").foregroundStyle(.white.opacity(0.4)).padding()
                }

                SwaraTicker()
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(bg.ignoresSafeArea())
        .task {
            if selectedDate.isEmpty { selectedDate = dateStr(Date()) }
            if let id = authStore.user?.id { await classStore.fetchStudentData(studentId: id) }
        }
    }

    private func dateStr(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: d) }
    private func dateFromStr(_ s: String) -> Date? { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: s) }
}

// MARK: - Student Session Detail
struct StudentSessionDetailView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore
    let sessionId: UUID
    @State private var reason = ""
    @State private var showMakeup = false
    @State private var submitting = false

    var body: some View {
        let session = classStore.sessions.first { $0.id == sessionId }
        let myRsvp = classStore.attendance.first { $0.sessionId == sessionId && $0.studentId == authStore.user?.id }
        let ac = AppSettings.Colors.studentAccent

        ScrollView {
            VStack(spacing: 12) {
                if let s = session {
                    ThemedCard {
                        Text(s.scheduledDate).font(.headline).foregroundStyle(.white)
                        Text("\(s.startTime) - \(s.endTime)").foregroundStyle(.white.opacity(0.6))
                        if s.status == .cancelled { Text("CANCELLED").font(.caption).bold().foregroundStyle(.gray) }
                        if let note = s.cancellationNote { Text(note).font(.caption).foregroundStyle(.white.opacity(0.5)).italic() }
                    }

                    if let link = s.liveLink, !link.isEmpty, s.status == .active {
                        ThemedButton("Join Online", color: AppSettings.Colors.studentPrimary) {
                            if let url = URL(string: link) { UIApplication.shared.open(url) }
                        }
                    }

                    if s.status == .active {
                        VStack(spacing: 8) {
                            Text("Are you coming?").font(.headline).foregroundStyle(.white)
                            HStack(spacing: 12) {
                                ThemedButton("Coming!", color: myRsvp?.rsvpStatus == .coming ? AppSettings.Colors.success : Color.white.opacity(0.15),
                                             textColor: myRsvp?.rsvpStatus == .coming ? .white : .white.opacity(0.6)) {
                                    Task { await classStore.updateRSVP(sessionId: sessionId, studentId: authStore.user!.id, status: .coming) }
                                }
                                ThemedButton("I Can't Come", color: myRsvp?.rsvpStatus == .notComing ? AppSettings.Colors.atRisk : Color.white.opacity(0.15),
                                             textColor: myRsvp?.rsvpStatus == .notComing ? .white : .white.opacity(0.6)) {
                                    Task { await classStore.updateRSVP(sessionId: sessionId, studentId: authStore.user!.id, status: .notComing) }
                                    showMakeup = true
                                }
                            }
                        }
                    }

                    if showMakeup {
                        ThemedCard {
                            Text("Request a Makeup Class").font(.headline).foregroundStyle(ac)
                            ThemedInput(label: "Why can't you come?", text: $reason, accentColor: ac)
                            ThemedButton("Send Makeup Request", color: AppSettings.Colors.studentPrimary, isLoading: submitting) {
                                guard !reason.isEmpty, let uid = authStore.user?.id else { return }
                                submitting = true
                                Task {
                                    try? await classStore.submitMakeupRequest(sessionId: sessionId, studentId: uid, teacherId: s.teacherId, reason: reason)
                                    showMakeup = false; reason = ""; submitting = false
                                }
                            }
                        }
                    }
                }

                AppHeader(title: "Class Materials", bgColor: .clear, textColor: ac)
                ForEach(classStore.materials) { m in
                    ThemedCard {
                        Text(m.title).font(.subheadline).bold().foregroundStyle(.white)
                        Text(m.fileType?.rawValue ?? "file").font(.caption).foregroundStyle(.white.opacity(0.5))
                        let cached = OfflineCacheService.shared.cachedPath(for: m.id.uuidString) != nil
                        ThemedButton(cached ? "Saved Offline" : "Save Offline",
                                     color: cached ? AppSettings.Colors.success : ac,
                                     textColor: cached ? .white : .black, disabled: cached) {
                            Task { if let url = URL(string: m.fileUrl) { try? await OfflineCacheService.shared.downloadMaterial(id: m.id.uuidString, url: url) } }
                        }
                    }
                }
                if classStore.materials.isEmpty { Text("No materials yet").foregroundStyle(.white.opacity(0.4)).padding() }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.studentBg.ignoresSafeArea())
        .navigationTitle("Class Details").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
        .task { await classStore.fetchSessionMaterials(sessionId: sessionId) }
    }
}

// MARK: - Practice Log
struct StudentPracticeLogView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore
    @State private var selectedDuration: Int?
    @State private var notes = ""
    @State private var saving = false

    private let durations = [10, 15, 20, 30, 45, 60]

    var body: some View {
        let ac = AppSettings.Colors.studentAccent
        let weekTotal = classStore.practiceLogs
            .filter { if let d = dateFromStr($0.logDate) { return d > Date().addingTimeInterval(-7*24*3600) } else { return false } }
            .reduce(0) { $0 + $1.durationMin }

        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ThemedCard { VStack { Text("\(weekTotal)").font(.title).bold().foregroundStyle(ac); Text("min this week").font(.caption).foregroundStyle(.white.opacity(0.5)) }.frame(maxWidth: .infinity) }
                    ThemedCard { VStack { Text("\(classStore.practiceLogs.count)").font(.title).bold().foregroundStyle(ac); Text("total logs").font(.caption).foregroundStyle(.white.opacity(0.5)) }.frame(maxWidth: .infinity) }
                }

                ThemedCard {
                    Text("Log Today's Practice").font(.headline).foregroundStyle(ac)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(durations, id: \.self) { d in
                            Button {
                                SoundService.shared.playNavigationSound(); selectedDuration = d
                            } label: {
                                Text("\(d) min").font(.subheadline).bold()
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .foregroundStyle(selectedDuration == d ? .black : .white)
                                    .background(selectedDuration == d ? ac : Color.white.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    ThemedInput(label: "Notes (optional)", text: $notes, placeholder: "What did you practice?", accentColor: ac)
                    ThemedButton("Save Practice", color: AppSettings.Colors.studentPrimary, isLoading: saving) {
                        guard let dur = selectedDuration, let uid = authStore.user?.id else { return }
                        saving = true
                        Task {
                            let teacherId = classStore.enrollments.first?.classId ?? UUID()
                            try? await classStore.logPractice(studentId: uid, teacherId: teacherId, duration: dur, notes: notes)
                            selectedDuration = nil; notes = ""; saving = false
                        }
                    }
                }

                AppHeader(title: "History", bgColor: .clear, textColor: ac)
                ForEach(classStore.practiceLogs) { log in
                    ThemedCard {
                        HStack {
                            Text(log.logDate).font(.subheadline).bold().foregroundStyle(.white)
                            Spacer()
                            Text("\(log.durationMin) min").font(.subheadline).bold().foregroundStyle(ac)
                        }
                        if let n = log.notes { Text(n).font(.caption).foregroundStyle(.white.opacity(0.6)) }
                        Text(log.approved == true ? "Approved" : log.approved == false ? "Declined" : "Pending")
                            .font(.caption2).bold()
                            .foregroundStyle(log.approved == true ? AppSettings.Colors.success : log.approved == false ? AppSettings.Colors.atRisk : .white.opacity(0.4))
                    }
                }
                if classStore.practiceLogs.isEmpty { Text("No practice logged yet. Start today!").foregroundStyle(.white.opacity(0.4)).padding() }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.studentBg.ignoresSafeArea())
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Log your daily practice so your teacher can see!" } } }
    }

    private func dateFromStr(_ s: String) -> Date? { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: s) }
}

// MARK: - Progress
struct StudentProgressView: View {
    @Environment(ClassStore.self) private var classStore
    @State private var activeTab = 0

    var body: some View {
        let ac = AppSettings.Colors.studentAccent
        let earnedIds = Set(classStore.badges.map(\.badgeId))
        let avgLevel = classStore.skills.isEmpty ? 0.0 : Double(classStore.skills.reduce(0) { $0 + $1.level }) / Double(classStore.skills.count)
        let levelName = avgLevel >= 3.5 ? AppSettings.levelNames[2] : avgLevel >= 1.5 ? AppSettings.levelNames[1] : AppSettings.levelNames[0]

        ScrollView {
            VStack(spacing: 12) {
                Picker("Tab", selection: $activeTab) {
                    Text("Skills").tag(0); Text("Badges").tag(1); Text("Terms").tag(2); Text("Report").tag(3)
                }.pickerStyle(.segmented)

                switch activeTab {
                case 0:
                    Text("Level: \(levelName)").font(.title3).bold().foregroundStyle(ac)
                    ForEach(classStore.skills) { skill in
                        SkillBarView(skillName: skill.skillName, level: skill.level, readOnly: true)
                    }
                    if classStore.skills.isEmpty { Text("Your teacher will add skills soon!").foregroundStyle(.white.opacity(0.4)).padding() }
                case 1:
                    BadgeGridView(earnedBadgeIds: earnedIds)
                case 2:
                    ForEach(classStore.terms) { term in
                        ThemedCard {
                            Text(term.name).font(.headline).foregroundStyle(.white)
                            Text("\(term.startDate) to \(term.endDate)").font(.caption).foregroundStyle(.white.opacity(0.5))
                            ThemedButton("Join", color: AppSettings.Colors.studentPrimary) {}
                        }
                    }
                    if classStore.terms.isEmpty { Text("No terms available").foregroundStyle(.white.opacity(0.4)).padding() }
                case 3:
                    ForEach(classStore.reportCards) { r in
                        ThemedCard {
                            Text(r.termName).font(.headline).foregroundStyle(ac)
                            if let g = r.overallGrade { Text("Grade: \(g)").foregroundStyle(.white) }
                            Text("Attendance: \(r.attendancePct ?? 0, specifier: "%.0f")%").foregroundStyle(.white)
                            if let c = r.comments { Text(c).font(.caption).foregroundStyle(.white.opacity(0.7)).italic() }
                        }
                    }
                    if classStore.reportCards.isEmpty { Text("No report cards yet").foregroundStyle(.white.opacity(0.4)).padding() }
                default: EmptyView()
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.studentBg.ignoresSafeArea())
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "See your skills, badges, and report cards!" } } }
    }
}

// MARK: - Messages
struct StudentMessagesView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore

    var body: some View {
        let sorted = classStore.messages.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }

        ScrollView {
            VStack(spacing: 12) {
                if sorted.isEmpty { Text("No messages yet").foregroundStyle(.white.opacity(0.4)).padding(40) }
                ForEach(sorted) { msg in
                    ThemedCard {
                        HStack {
                            Text(msg.type.rawValue.uppercased()).font(.caption2).bold().foregroundStyle(AppSettings.Colors.studentAccent)
                            Spacer()
                            Text(msg.createdAt?.prefix(10) ?? "").font(.caption2).foregroundStyle(.white.opacity(0.4))
                        }
                        if let t = msg.title { Text(t).font(.headline).foregroundStyle(.white) }
                        Text(msg.content).foregroundStyle(.white.opacity(0.7))

                        if msg.type == .announcement {
                            ThemedButton("OK", color: AppSettings.Colors.studentPrimary) { respond(msg.id, "acknowledged") }
                        }
                        if msg.type == .poll {
                            HStack(spacing: 8) {
                                ThemedButton("Accept", color: AppSettings.Colors.success) { respond(msg.id, "accepted") }
                                ThemedButton("Reject", color: AppSettings.Colors.atRisk) { respond(msg.id, "rejected") }
                            }
                        }
                    }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.studentBg.ignoresSafeArea())
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Read messages from your teacher." } } }
    }

    private func respond(_ messageId: UUID, _ response: String) {
        SoundService.shared.playNavigationSound()
        guard let uid = authStore.user?.id else { return }
        struct Resp: Encodable { let message_id: UUID; let student_id: UUID; let response: String }
        Task { try? await SupabaseService.shared.upsert("message_responses", value: Resp(message_id: messageId, student_id: uid, response: response)) }
    }
}

// MARK: - Profile
struct StudentProfileView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var navSounds = AppSettings.navigationSounds
    @State private var annSounds = AppSettings.announcementSounds
    @State private var showDeleteAlert = false

    var body: some View {
        let ac = AppSettings.Colors.studentAccent
        ScrollView {
            VStack(spacing: 12) {
                ThemedCard {
                    Text("About Me").font(.headline).foregroundStyle(ac)
                    Text("Name: \(authStore.user?.fullName ?? "")").foregroundStyle(.white)
                    Text("Email: \(authStore.user?.email ?? "")").foregroundStyle(.white)
                }
                ThemedCard {
                    Text("Security").font(.headline).foregroundStyle(ac)
                    ThemedButton("Change PIN", color: AppSettings.Colors.studentPrimary) {}
                    if AppSettings.biometricsEnabled {
                        ThemedButton("Enable Face ID", color: AppSettings.Colors.studentPrimary) {}
                    }
                }
                ThemedCard {
                    Text("Sounds").font(.headline).foregroundStyle(ac)
                    Toggle("Navigation Sounds", isOn: $navSounds).tint(ac).foregroundStyle(.white)
                    Toggle("Announcement Melody", isOn: $annSounds).tint(ac).foregroundStyle(.white)
                }
                ThemedCard {
                    Text("Calendar Sync").font(.headline).foregroundStyle(ac)
                    ThemedButton("Sync to Apple Calendar", color: AppSettings.Colors.studentPrimary) {}
                }
                OutlineButton(title: "Sign Out", color: ac) { Task { await authStore.signOut() } }.padding(.top, 24)
                GhostButton(title: "Delete Account", color: AppSettings.Colors.atRisk) { showDeleteAlert = true }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.studentBg.ignoresSafeArea())
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "View your profile and manage settings." } } }
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { Task { await authStore.deleteAccount() } }
        } message: { Text("This will delete your account. Ask your parent first.") }
    }
}
