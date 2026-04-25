import SwiftUI

struct RoleSelectView: View {
    var body: some View {
        ZStack {
            AppSettings.Colors.teacherBg.ignoresSafeArea()
            VStack(spacing: 16) {
                Text(AppSettings.appName)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(AppSettings.Colors.teacherAccent)
                Text("I am a...")
                    .font(.title3).foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 24)

                NavigationLink(destination: TeacherLoginView()) {
                    RoleCard(label: AppSettings.teacherLabel,
                             desc: "Manage your \(AppSettings.subjectName) classes",
                             color: AppSettings.Colors.teacherPrimary)
                }
                NavigationLink(destination: StudentLoginView()) {
                    RoleCard(label: AppSettings.studentLabel,
                             desc: "Learn and grow with \(AppSettings.subjectName)",
                             color: AppSettings.Colors.studentPrimary)
                }
                NavigationLink(destination: ParentLoginView()) {
                    RoleCard(label: AppSettings.parentLabel,
                             desc: "Track your child's progress",
                             color: AppSettings.Colors.parentPrimary)
                }
                Spacer()
            }
            .padding(.top, 80)
            .padding(.horizontal, 24)
        }
    }
}

struct RoleCard: View {
    let label: String
    let desc: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.title2).bold().foregroundStyle(.white)
            Text(desc).font(.subheadline).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(color)
        .cornerRadius(20)
    }
}
