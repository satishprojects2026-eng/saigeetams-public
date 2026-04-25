import SwiftUI

// MARK: - Parent Dashboard
struct ParentDashboardView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore
    @State private var childName = ""
    @State private var childId: UUID?

    var body: some View {
        let ac = AppSettings.Colors.parentAccent
        let presentCount = classStore.attendance.filter { $0.actualStatus == .present }.count
        let total = classStore.attendance.count
        let pct = total > 0 ? Int(Double(presentCount) / Double(total) * 100) : 0
        let today = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }()
        let upcoming = classStore.sessions.filter { $0.scheduledDate >= today && $0.status == .active }.prefix(3)

        ScrollView {
            VStack(spacing: 12) {
                ThemedCard {
                    Text(childName.isEmpty ? "Your Child" : childName).font(.title2).bold().foregroundStyle(ac)
                    HStack {
                        VStack { Text("\(presentCount)").font(.title2).bold().foregroundStyle(.white); Text("Attended").font(.caption).foregroundStyle(.white.opacity(0.5)) }
                        Spacer()
                        VStack { Text("\(pct)%").font(.title2).bold().foregroundStyle(.white); Text("Attendance").font(.caption).foregroundStyle(.white.opacity(0.5)) }
                        Spacer()
                        VStack { Text("\(classStore.badges.count)").font(.title2).bold().foregroundStyle(.white); Text("Badges").font(.caption).foregroundStyle(.white.opacity(0.5)) }
                    }
                }

                AppHeader(title: "Upcoming Sessions", bgColor: .clear, textColor: ac)
                if upcoming.isEmpty { Text("No upcoming sessions").foregroundStyle(.white.opacity(0.4)).padding() }
                ForEach(Array(upcoming)) { s in
                    ThemedCard {
                        Text(s.scheduledDate).font(.subheadline).bold().foregroundStyle(.white)
                        Text("\(s.startTime) - \(s.endTime)").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                }

                AppHeader(title: "Recent Messages", bgColor: .clear, textColor: ac)
                ForEach(classStore.messages.prefix(3)) { msg in
                    ThemedCard {
                        Text(msg.type.rawValue.uppercased()).font(.caption2).bold().foregroundStyle(ac)
                        if let t = msg.title { Text(t).font(.subheadline).bold().foregroundStyle(.white) }
                        Text(msg.content).font(.caption).foregroundStyle(.white.opacity(0.6)).lineLimit(2)
                    }
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.parentBg.ignoresSafeArea())
        .task { await loadChild() }
    }

    private func loadChild() async {
        guard let uid = authStore.user?.id else { return }
        let parents: [ParentGuardian] = (try? await SupabaseService.shared.fetch("parent_guardians", eq: "user_id", value: uid.uuidString)) ?? []
        guard let pg = parents.first else { return }
        childId = pg.studentId
        await classStore.fetchParentData(studentId: pg.studentId)
        let child: AppUser? = try? await SupabaseService.shared.fetchSingle("users", eq: "id", value: pg.studentId.uuidString)
        await MainActor.run { childName = child?.fullName ?? "" }
    }
}

// MARK: - Parent Schedule
struct ParentScheduleView: View {
    @Environment(ClassStore.self) private var classStore
    @State private var selectedDate = ""

    var body: some View {
        let ac = AppSettings.Colors.parentAccent
        let daySessions = classStore.sessions.filter { $0.scheduledDate == selectedDate }

        ScrollView {
            VStack(spacing: 12) {
                DatePicker("", selection: Binding(
                    get: { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: selectedDate) ?? Date() },
                    set: { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; selectedDate = f.string(from: $0) }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical).tint(ac).colorScheme(.dark)

                ThemedButton("Sync to My Calendar", color: AppSettings.Colors.parentPrimary) {
                    Task {
                        for s in classStore.sessions.filter({ $0.status == .active }) {
                            _ = await CalendarSyncService.shared.syncSession(
                                title: "\(AppSettings.subjectName) Class",
                                date: s.scheduledDate, startTime: s.startTime, endTime: s.endTime)
                        }
                    }
                }

                ForEach(daySessions) { s in
                    ThemedCard(bgColor: s.status == .cancelled ? Color.gray.opacity(0.2) : Color.white.opacity(0.08)) {
                        Text("\(s.startTime) - \(s.endTime)\(s.status == .cancelled ? " (Cancelled)" : "")")
                            .foregroundStyle(s.status == .cancelled ? .gray : .white)
                    }
                }
                if daySessions.isEmpty && !selectedDate.isEmpty {
                    Text("No classes on this day").foregroundStyle(.white.opacity(0.4)).padding()
                }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.parentBg.ignoresSafeArea())
        .onAppear { if selectedDate.isEmpty { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; selectedDate = f.string(from: Date()) } }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Your child's class schedule." } } }
    }
}

// MARK: - Parent Progress
struct ParentProgressView: View {
    @Environment(ClassStore.self) private var classStore
    @State private var activeTab = 0

    var body: some View {
        let ac = AppSettings.Colors.parentAccent
        ScrollView {
            VStack(spacing: 12) {
                Picker("Tab", selection: $activeTab) { Text("Skills").tag(0); Text("Notes").tag(1); Text("Report").tag(2) }.pickerStyle(.segmented)

                switch activeTab {
                case 0:
                    ForEach(classStore.skills) { skill in SkillBarView(skillName: skill.skillName, level: skill.level, readOnly: true) }
                    if classStore.skills.isEmpty { Text("No skills tracked yet").foregroundStyle(.white.opacity(0.4)).padding() }
                case 1:
                    ForEach(classStore.progressNotes) { n in
                        ThemedCard {
                            Text(n.noteDate).font(.caption).foregroundStyle(ac)
                            Text(n.note).foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    if classStore.progressNotes.isEmpty { Text("No notes yet").foregroundStyle(.white.opacity(0.4)).padding() }
                case 2:
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
        .background(AppSettings.Colors.parentBg.ignoresSafeArea())
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Your child's skills, notes, and reports." } } }
    }
}

// MARK: - Parent Settings
struct ParentSettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var reminders = true
    @State private var cancellations = true
    @State private var reportNotifs = true
    @State private var badgeNotifs = true
    @State private var showDeleteAlert = false

    var body: some View {
        let ac = AppSettings.Colors.parentAccent
        ScrollView {
            VStack(spacing: 12) {
                ThemedCard {
                    Text("Notifications").font(.headline).foregroundStyle(ac)
                    Toggle("Class Reminders", isOn: $reminders).tint(ac).foregroundStyle(.white)
                    Toggle("Cancellations", isOn: $cancellations).tint(ac).foregroundStyle(.white)
                    Toggle("Report Cards", isOn: $reportNotifs).tint(ac).foregroundStyle(.white)
                    Toggle("Badges Earned", isOn: $badgeNotifs).tint(ac).foregroundStyle(.white)
                }
                ThemedCard {
                    Text("Calendar Sync").font(.headline).foregroundStyle(ac)
                    ThemedButton("Sync to Apple Calendar", color: AppSettings.Colors.parentPrimary) {}
                }
                OutlineButton(title: "Sign Out", color: ac) { Task { await authStore.signOut() } }.padding(.top, 24)
                GhostButton(title: "Delete Account", color: AppSettings.Colors.atRisk) { showDeleteAlert = true }
            }
            .padding(16).padding(.bottom, 80)
        }
        .background(AppSettings.Colors.parentBg.ignoresSafeArea())
        .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { Task { await authStore.deleteAccount() } }
        } message: { Text("This will unlink your account from your child.") }
    }
}
