import SwiftUI

struct ContentView: View {
    @StateObject private var store = OrganizeTodayStore()
    @FocusState private var isQuickCaptureFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        overviewCard
                        quickCaptureCard
                        filterChips
                        taskListCard
                        supportingCards
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.72))

                Text("Organize Today")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("A focused command center for tasks, projects, and the next move that matters.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let nextEvent = store.nextEvent {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text(nextEvent.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(nextEvent.startTime.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.72))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private var overviewCard: some View {
        HeroCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today at a glance")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.88))

                        Text(store.remainingTodayCount == 0 ? "You are clear for the day." : "\(store.remainingTodayCount) active priorities still need attention.")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Use quick capture to keep momentum without losing structure.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.76))
                    }

                    Spacer(minLength: 16)

                    ProgressRing(progress: store.todayCompletionRate)
                }

                HStack(spacing: 12) {
                    HeroMetric(title: "Done", value: "\(store.completedTodayCount)", subtitle: "completed")
                    HeroMetric(title: "Focus", value: "\(store.focusMinutesRemaining)m", subtitle: "remaining")
                    HeroMetric(title: "Upcoming", value: "\(store.upcomingCount)", subtitle: "later")
                }

                if let highlightTask = store.highlightTask {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top focus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.72))

                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(highlightTask.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Text(highlightTask.details)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.76))
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 12)

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(highlightTask.timeLabel)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Text("\(highlightTask.estimatedMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.72))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var quickCaptureCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Quick capture")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(hex: 0x0F172A))

                Text("Drop in a task now. New items are scheduled for today with a focused default estimate.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: 0x475569))

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 12) {
                        quickCaptureField
                        quickCaptureButton
                    }

                    VStack(spacing: 12) {
                        quickCaptureField
                        quickCaptureButton
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TaskFilter.allCases) { filter in
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            store.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(store.selectedFilter == filter ? .white : Color(hex: 0xE2E8F0))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(store.selectedFilter == filter ? Color(hex: 0xB7791F) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(store.selectedFilter == filter ? 0.0 : 0.12), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var taskListCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.selectedFilter.sectionTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color(hex: 0x0F172A))

                        Text("\(store.filteredTasks.count) item\(store.filteredTasks.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: 0x64748B))
                    }

                    Spacer()

                    if store.selectedFilter == .completed, !store.filteredTasks.isEmpty {
                        Button("Reset Samples", action: store.resetToSampleData)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: 0x8C5A17))
                            .buttonStyle(.plain)
                    }
                }

                if store.filteredTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.selectedFilter.emptyStateTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color(hex: 0x0F172A))

                        Text(store.selectedFilter.emptyStateMessage)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: 0x64748B))
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.filteredTasks) { task in
                            TaskRow(task: task) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    store.toggleCompletion(for: task)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var supportingCards: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) {
                agendaCard
                projectsCard
            }

            VStack(spacing: 20) {
                agendaCard
                projectsCard
            }
        }
    }

    private var agendaCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Agenda")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(hex: 0x0F172A))

                ForEach(store.schedule) { item in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.startTime.formatted(.dateTime.hour().minute()))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(hex: 0x0F172A))

                            Text("\(item.durationMinutes) min")
                                .font(.caption)
                                .foregroundStyle(Color(hex: 0x64748B))
                        }
                        .frame(width: 72, alignment: .leading)

                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(item.tone.color)
                            .frame(width: 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color(hex: 0x0F172A))

                            Text(item.location)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: 0x64748B))
                        }
                    }
                    .padding(14)
                    .background(item.tone.color.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var projectsCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Projects")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(hex: 0x0F172A))

                ForEach(store.projects) { project in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(project.name)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color(hex: 0x0F172A))

                            Spacer()

                            Text(project.progress.formatted(.percent.precision(.fractionLength(0))))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(project.tone.color)
                        }

                        Text(project.nextMilestone)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: 0x64748B))

                        ProgressView(value: project.progress)
                            .tint(project.tone.color)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    }
                    .padding(14)
                    .background(project.tone.color.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func addQuickTask() {
        store.captureQuickTask()
        isQuickCaptureFocused = false
    }

    private var quickCaptureField: some View {
        TextField("Add a task, errand, or reminder", text: $store.quickCaptureText, axis: .vertical)
            .textFieldStyle(.plain)
            .focused($isQuickCaptureFocused)
            .lineLimit(1...3)
            .submitLabel(.done)
            .onSubmit(addQuickTask)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var quickCaptureButton: some View {
        Button(action: addQuickTask) {
            Label("Add", systemImage: "plus")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xB7791F), Color(hex: 0x8C5A17)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color(hex: 0xF4EFE4).opacity(0.97))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.52), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 18)
    }
}

private struct HeroCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x19324D), Color(hex: 0x0F766E)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 28, x: 0, y: 18)
    }
}

private struct HeroMetric: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 12)

            Circle()
                .trim(from: 0, to: max(progress, 0.04))
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: 0xF4EFE4), Color(hex: 0xD69E2E), Color(hex: 0xF4EFE4)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text("complete")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
        }
        .frame(width: 92, height: 92)
    }
}

private struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(task.isCompleted ? Color(hex: 0x2F855A) : Color(hex: 0x94A3B8))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    Text(task.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color(hex: 0x0F172A))
                        .strikethrough(task.isCompleted, color: Color(hex: 0x64748B))
                        .opacity(task.isCompleted ? 0.55 : 1)

                    if task.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0xB7791F))
                    }
                }

                if !task.details.isEmpty {
                    Text(task.details)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: 0x475569))
                        .lineLimit(2)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        TaskBadge(text: task.category.title, tint: task.category.color)
                        TaskBadge(text: task.priority.label, tint: task.priority.color)
                        TaskBadge(text: task.timeLabel, tint: Color(hex: 0x64748B))
                        TaskBadge(text: "\(task.estimatedMinutes) min", tint: Color(hex: 0x1D4ED8))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            TaskBadge(text: task.category.title, tint: task.category.color)
                            TaskBadge(text: task.priority.label, tint: task.priority.color)
                        }

                        HStack(spacing: 8) {
                            TaskBadge(text: task.timeLabel, tint: Color(hex: 0x64748B))
                            TaskBadge(text: "\(task.estimatedMinutes) min", tint: Color(hex: 0x1D4ED8))
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct TaskBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B1320), Color(hex: 0x132238), Color(hex: 0x1E293B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: 0xB7791F).opacity(0.32))
                .frame(width: 300, height: 300)
                .blur(radius: 18)
                .offset(x: -140, y: -250)

            Circle()
                .fill(Color(hex: 0x0F766E).opacity(0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 16)
                .offset(x: 140, y: -120)

            Circle()
                .fill(Color(hex: 0x1D4ED8).opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 24)
                .offset(x: 120, y: 300)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
