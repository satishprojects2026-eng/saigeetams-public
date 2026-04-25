import SwiftUI

struct TeacherCalendarView: View {
    @Environment(ClassStore.self) private var classStore
    @State private var selectedDate = ""

    private let colors = (AppSettings.Colors.teacherBg, AppSettings.Colors.teacherAccent, AppSettings.Colors.teacherPrimary)

    var body: some View {
        let daySessions = classStore.sessions.filter { $0.scheduledDate == selectedDate }

        ScrollView {
            VStack(spacing: 12) {
                // Simple month calendar placeholder - use a date picker
                DatePicker("Select Date", selection: Binding(
                    get: { dateFromString(selectedDate) ?? Date() },
                    set: { selectedDate = dateString($0) }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(colors.1)
                .colorScheme(.dark)
                .padding(.horizontal)

                Text(selectedDate.isEmpty ? "Select a date" : selectedDate)
                    .font(.headline).foregroundStyle(colors.1)

                ForEach(daySessions) { session in
                    NavigationLink(destination: TeacherSessionDetailView(sessionId: session.id)) {
                        ThemedCard(bgColor: session.status == .cancelled ? Color.gray.opacity(0.2) : Color.white.opacity(0.08)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(classStore.classes.first { $0.id == session.classId }?.title ?? "Class")
                                        .font(.headline).foregroundStyle(session.status == .cancelled ? .gray : .white)
                                    Text("\(session.startTime) - \(session.endTime)")
                                        .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                if session.status == .cancelled {
                                    Text("CANCELLED").font(.caption2).bold().foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                }

                if daySessions.isEmpty && !selectedDate.isEmpty {
                    Text("No sessions on this date").foregroundStyle(.white.opacity(0.4)).padding()
                }
            }
            .padding(.bottom, 80)
        }
        .background(colors.0.ignoresSafeArea())
        .onAppear { if selectedDate.isEmpty { selectedDate = dateString(Date()) } }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HelpButton { "Tap a date to see sessions." } } }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
    private func dateFromString(_ str: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: str)
    }
}
