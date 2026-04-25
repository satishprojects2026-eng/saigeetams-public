import SwiftUI

struct TeacherDashboardView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ClassStore.self) private var classStore

    private var colors: (bg: Color, accent: Color, primary: Color) {
        (AppSettings.Colors.teacherBg, AppSettings.Colors.teacherAccent, AppSettings.Colors.teacherPrimary)
    }

    var body: some View {
        let totalStudents = classStore.enrollments.filter { $0.status == .active }.count
        let pendingApprovals = classStore.enrollments.filter { $0.status == .pending }.count
        let pendingMakeups = classStore.makeupRequests.filter { $0.status == .pending }.count
        let today = dateString(Date())
        let todaySessions = classStore.sessions.filter { $0.scheduledDate == today && $0.status == .active }

        ScrollView {
            VStack(spacing: 12) {
                // Stats
                HStack(spacing: 8) {
                    statCard("\(totalStudents)", "Students")
                    statCard("\(classStore.classes.count)", "Classes")
                    statCard("\(pendingApprovals)", "Pending")
                }

                // At-Risk
                NavigationLink(destination: TeacherAnalyticsView()) {
                    ThemedCard(bgColor: AppSettings.Colors.atRisk.opacity(0.15)) {
                        Text("At-Risk Students").font(.headline).foregroundStyle(AppSettings.Colors.atRisk)
                        Text("View students who missed 2+ classes in 30 days").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                }

                // Makeup
                if pendingMakeups > 0 {
                    NavigationLink(destination: TeacherMakeupView()) {
                        ThemedCard(bgColor: colors.accent.opacity(0.15)) {
                            Text("\(pendingMakeups) Makeup Request\(pendingMakeups > 1 ? "s" : "")").font(.headline).foregroundStyle(colors.accent)
                            Text("Tap to review and approve").font(.caption).foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                // Today's Sessions
                AppHeader(title: "Today's Sessions", bgColor: .clear, textColor: colors.accent)
                if todaySessions.isEmpty {
                    Text("No sessions today").foregroundStyle(.white.opacity(0.4)).padding()
                } else {
                    ForEach(todaySessions) { session in
                        NavigationLink(destination: TeacherSessionDetailView(sessionId: session.id)) {
                            ThemedCard {
                                Text(classStore.classes.first { $0.id == session.classId }?.title ?? "Class")
                                    .font(.headline).foregroundStyle(.white)
                                Text("\(session.startTime) - \(session.endTime)")
                                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }

                // Quick Actions
                AppHeader(title: "Quick Actions", bgColor: .clear, textColor: colors.accent)
                HStack(spacing: 12) {
                    NavigationLink(destination: TeacherCommsView()) {
                        Text("Send Message").fontWeight(.bold).frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(.white).background(colors.primary).cornerRadius(12)
                    }
                    NavigationLink(destination: TeacherCalendarView()) {
                        Text("Create Session").fontWeight(.bold).frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(.black).background(colors.accent).cornerRadius(12)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 80)
        }
        .background(colors.bg.ignoresSafeArea())
        .task { if let id = authStore.user?.id { await classStore.fetchTeacherData(teacherId: id) } }
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        ThemedCard {
            VStack {
                Text(value).font(.title).bold().foregroundStyle(colors.accent)
                Text(label).font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
}
