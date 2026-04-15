import Combine
import Foundation
import SwiftUI

enum TaskFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case upcoming = "Upcoming"
    case completed = "Completed"

    var id: Self { self }

    var sectionTitle: String {
        switch self {
        case .today:
            "Today"
        case .upcoming:
            "Upcoming"
        case .completed:
            "Completed"
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .today:
            "Nothing urgent is left."
        case .upcoming:
            "No upcoming tasks."
        case .completed:
            "No completed tasks yet."
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .today:
            "Use quick capture to add something new, or enjoy the fact that today is under control."
        case .upcoming:
            "Your future queue is clear. Add projects or reminders as you plan ahead."
        case .completed:
            "Complete a task to start building a visible record of progress."
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case critical
    case focus
    case routine

    var label: String {
        switch self {
        case .critical:
            "Critical"
        case .focus:
            "Focus"
        case .routine:
            "Routine"
        }
    }

    var color: Color {
        switch self {
        case .critical:
            Color(hex: 0xBE123C)
        case .focus:
            Color(hex: 0x0F766E)
        case .routine:
            Color(hex: 0x475569)
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical:
            0
        case .focus:
            1
        case .routine:
            2
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case deepWork
    case planning
    case admin
    case personal
    case home
    case wellness

    var title: String {
        switch self {
        case .deepWork:
            "Deep Work"
        case .planning:
            "Planning"
        case .admin:
            "Admin"
        case .personal:
            "Personal"
        case .home:
            "Home"
        case .wellness:
            "Wellness"
        }
    }

    var color: Color {
        switch self {
        case .deepWork:
            Color(hex: 0x1D4ED8)
        case .planning:
            Color(hex: 0x0F766E)
        case .admin:
            Color(hex: 0x0369A1)
        case .personal:
            Color(hex: 0xBE123C)
        case .home:
            Color(hex: 0xB7791F)
        case .wellness:
            Color(hex: 0x2F855A)
        }
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var details: String
    var dueDate: Date
    var estimatedMinutes: Int
    var priority: TaskPriority
    var category: TaskCategory
    var isCompleted: Bool
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        dueDate: Date,
        estimatedMinutes: Int,
        priority: TaskPriority,
        category: TaskCategory,
        isCompleted: Bool = false,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.isPinned = isPinned
    }

    var timeLabel: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(dueDate) {
            return dueDate.formatted(.dateTime.hour().minute())
        }

        return dueDate.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }
}

struct ScheduleItem: Identifiable {
    let id = UUID()
    let title: String
    let startTime: Date
    let durationMinutes: Int
    let location: String
    let tone: DashboardTone
}

struct ProjectSummary: Identifiable {
    let id = UUID()
    let name: String
    let progress: Double
    let nextMilestone: String
    let tone: DashboardTone
}

enum DashboardTone {
    case navy
    case teal
    case amber
    case rose

    var color: Color {
        switch self {
        case .navy:
            Color(hex: 0x1D4ED8)
        case .teal:
            Color(hex: 0x0F766E)
        case .amber:
            Color(hex: 0xB7791F)
        case .rose:
            Color(hex: 0xBE123C)
        }
    }
}

@MainActor
final class OrganizeTodayStore: ObservableObject {
    @Published var tasks: [TaskItem] {
        didSet {
            persistTasks()
        }
    }

    @Published var quickCaptureText = ""
    @Published var selectedFilter: TaskFilter = .today

    let schedule: [ScheduleItem]
    let projects: [ProjectSummary]

    private static let tasksStorageKey = "organize-today.tasks.v1"
    private let calendar = Calendar.current
    private let nowProvider: () -> Date

    init(nowProvider: @escaping () -> Date = Date.init) {
        self.nowProvider = nowProvider

        let referenceDate = nowProvider()
        schedule = ScheduleItem.sampleData(relativeTo: referenceDate)
        projects = ProjectSummary.sampleData()
        tasks = Self.loadTasks() ?? TaskItem.sampleData(relativeTo: referenceDate)
    }

    var filteredTasks: [TaskItem] {
        let referenceDate = nowProvider()
        let endOfToday = endOfDay(for: referenceDate)

        let filtered = tasks.filter { task in
            switch selectedFilter {
            case .today:
                !task.isCompleted && task.dueDate <= endOfToday
            case .upcoming:
                !task.isCompleted && task.dueDate > endOfToday
            case .completed:
                task.isCompleted
            }
        }

        return filtered.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }

            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }

            return lhs.dueDate < rhs.dueDate
        }
    }

    var highlightTask: TaskItem? {
        let endOfToday = endOfDay(for: nowProvider())
        let activeTodayTasks = tasks
            .filter { !$0.isCompleted && $0.dueDate <= endOfToday }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned
                }

                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }

                return lhs.dueDate < rhs.dueDate
            }

        return activeTodayTasks.first
    }

    var todayCompletionRate: Double {
        let endOfToday = endOfDay(for: nowProvider())
        let todaysTasks = tasks.filter { $0.dueDate <= endOfToday }

        guard !todaysTasks.isEmpty else { return 1 }

        let completed = todaysTasks.filter(\.isCompleted).count
        return Double(completed) / Double(todaysTasks.count)
    }

    var remainingTodayCount: Int {
        let endOfToday = endOfDay(for: nowProvider())
        return tasks.filter { !$0.isCompleted && $0.dueDate <= endOfToday }.count
    }

    var completedTodayCount: Int {
        let endOfToday = endOfDay(for: nowProvider())
        return tasks.filter { $0.isCompleted && $0.dueDate <= endOfToday }.count
    }

    var focusMinutesRemaining: Int {
        let endOfToday = endOfDay(for: nowProvider())
        return tasks
            .filter { !$0.isCompleted && $0.dueDate <= endOfToday }
            .map(\.estimatedMinutes)
            .reduce(0, +)
    }

    var upcomingCount: Int {
        let endOfToday = endOfDay(for: nowProvider())
        return tasks.filter { !$0.isCompleted && $0.dueDate > endOfToday }.count
    }

    var nextEvent: ScheduleItem? {
        let referenceDate = nowProvider()
        return schedule.first(where: { $0.startTime >= referenceDate }) ?? schedule.last
    }

    func captureQuickTask() {
        let trimmed = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let dueDate = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: nowProvider()) ?? nowProvider()
        let newTask = TaskItem(
            title: trimmed,
            details: "Captured quickly so you can organize it without losing focus.",
            dueDate: dueDate,
            estimatedMinutes: 20,
            priority: .focus,
            category: .planning
        )

        tasks.insert(newTask, at: 0)
        quickCaptureText = ""
    }

    func toggleCompletion(for task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        tasks[index].isCompleted.toggle()
        if tasks[index].isCompleted {
            tasks[index].isPinned = false
        }
    }

    func resetToSampleData() {
        tasks = TaskItem.sampleData(relativeTo: nowProvider())
    }

    private func endOfDay(for date: Date) -> Date {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        return startOfTomorrow.addingTimeInterval(-1)
    }

    private func persistTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: Self.tasksStorageKey)
    }

    private static func loadTasks() -> [TaskItem]? {
        guard let data = UserDefaults.standard.data(forKey: tasksStorageKey),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            return nil
        }

        return decoded
    }
}

private extension TaskItem {
    static func sampleData(relativeTo referenceDate: Date) -> [TaskItem] {
        [
            TaskItem(
                title: "Finalize weekly priorities",
                details: "Lock in the top three outcomes for the day before inbox work expands.",
                dueDate: date(hour: 9, minute: 30, referenceDate: referenceDate),
                estimatedMinutes: 25,
                priority: .critical,
                category: .planning,
                isPinned: true
            ),
            TaskItem(
                title: "Prep client follow-up notes",
                details: "Summarize decisions, next actions, and attachments before the afternoon call.",
                dueDate: date(hour: 11, minute: 15, referenceDate: referenceDate),
                estimatedMinutes: 35,
                priority: .focus,
                category: .deepWork
            ),
            TaskItem(
                title: "Home reset checklist",
                details: "Laundry, kitchen reset, and restock the desk area before the evening block.",
                dueDate: date(hour: 18, minute: 15, referenceDate: referenceDate),
                estimatedMinutes: 30,
                priority: .routine,
                category: .home
            ),
            TaskItem(
                title: "30-minute workout",
                details: "Keep the routine short and consistent.",
                dueDate: date(hour: 19, minute: 0, referenceDate: referenceDate),
                estimatedMinutes: 30,
                priority: .focus,
                category: .wellness
            ),
            TaskItem(
                title: "Plan next week travel details",
                details: "Compare hotel options and confirm the check-in timeline.",
                dueDate: date(dayOffset: 1, hour: 10, minute: 0, referenceDate: referenceDate),
                estimatedMinutes: 40,
                priority: .focus,
                category: .personal
            ),
            TaskItem(
                title: "Submit reimbursement form",
                details: "Attach receipts and send it before Friday.",
                dueDate: date(dayOffset: 2, hour: 14, minute: 0, referenceDate: referenceDate),
                estimatedMinutes: 15,
                priority: .routine,
                category: .admin
            ),
            TaskItem(
                title: "Morning inbox scan",
                details: "Review new messages and flag anything that needs a real block later.",
                dueDate: date(hour: 8, minute: 45, referenceDate: referenceDate),
                estimatedMinutes: 10,
                priority: .routine,
                category: .admin,
                isCompleted: true
            )
        ]
    }

    static func date(dayOffset: Int = 0, hour: Int, minute: Int, referenceDate: Date) -> Date {
        let calendar = Calendar.current
        let adjustedDay = calendar.date(byAdding: .day, value: dayOffset, to: referenceDate) ?? referenceDate
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: adjustedDay) ?? adjustedDay
    }
}

private extension ScheduleItem {
    static func sampleData(relativeTo referenceDate: Date) -> [ScheduleItem] {
        [
            ScheduleItem(
                title: "Daily planning review",
                startTime: date(hour: 9, minute: 0, referenceDate: referenceDate),
                durationMinutes: 20,
                location: "Focus mode",
                tone: .teal
            ),
            ScheduleItem(
                title: "Project alignment call",
                startTime: date(hour: 13, minute: 0, referenceDate: referenceDate),
                durationMinutes: 45,
                location: "Conference room A",
                tone: .navy
            ),
            ScheduleItem(
                title: "Errand and reset block",
                startTime: date(hour: 17, minute: 30, referenceDate: referenceDate),
                durationMinutes: 60,
                location: "Offline",
                tone: .amber
            )
        ]
    }

    static func date(hour: Int, minute: Int, referenceDate: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: referenceDate) ?? referenceDate
    }
}

private extension ProjectSummary {
    static func sampleData() -> [ProjectSummary] {
        [
            ProjectSummary(
                name: "Q2 Systems Refresh",
                progress: 0.72,
                nextMilestone: "Finalize the routines and clean up the loose ends.",
                tone: .navy
            ),
            ProjectSummary(
                name: "Home Operations",
                progress: 0.54,
                nextMilestone: "Complete storage labels and finish the weekend reset workflow.",
                tone: .amber
            ),
            ProjectSummary(
                name: "Personal Admin",
                progress: 0.38,
                nextMilestone: "Handle forms, travel details, and remaining approvals.",
                tone: .rose
            )
        ]
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
