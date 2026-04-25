import EventKit

final class CalendarSyncService {
    static let shared = CalendarSyncService()
    private let store = EKEventStore()

    private init() {}

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    func syncSession(title: String, date: String, startTime: String, endTime: String, notes: String? = nil) async -> String? {
        guard await requestAccess() else { return nil }

        let calendar = store.defaultCalendarForNewEvents
        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = notes
        event.calendar = calendar

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        event.startDate = formatter.date(from: "\(date) \(startTime)") ?? Date()
        event.endDate = formatter.date(from: "\(date) \(endTime)") ?? Date()

        do {
            try store.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            return nil
        }
    }

    func removeEvent(identifier: String) {
        guard let event = store.event(withIdentifier: identifier) else { return }
        try? store.remove(event, span: .thisEvent)
    }
}
