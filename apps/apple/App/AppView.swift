import SwiftUI

struct AppView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: RunStore
    @State private var companion: TimerCompanion?
    @State private var sheet: TimerSheet?
    @State private var showingRestart = false

    init(store: RunStore? = nil) {
        _store = State(initialValue: store ?? RunStore())
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let snapshot = TimerSnapshot(run: store.currentRun, at: .now)
            let theme = TimerThemes.resolve(store.currentRun.theme)

            theme.screen(snapshot)
                .environment(\.colorScheme, theme.colorScheme)
                .overlay(alignment: .top) {
                    controls(snapshot: snapshot)
                        .environment(\.colorScheme, theme.colorScheme)
                }
                .onChange(of: snapshot.status) { _, status in
                    if status == .complete {
                        store.refresh()
                        Task {
                            await companion?.complete(run: store.currentRun)
                        }
                    }
                }
                .sensoryFeedback(.success, trigger: snapshot.status == .complete) { _, completed in
                    completed
                }
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .settings:
                RunSettingsView(currentRun: store.currentRun) { minutes, theme in
                    store.createRun(minutes: minutes, theme: theme)
                    synchronizeCompanion()
                }
                .presentationDragIndicator(.visible)
            case .history:
                RunHistoryView(store: store)
                    .presentationDragIndicator(.visible)
            }
        }
        .confirmationDialog("Start this run over?", isPresented: $showingRestart, titleVisibility: .visible) {
            Button("Start over") {
                store.restart()
                synchronizeCompanion()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will stay in History. A fresh run with the same time and theme will be ready to start.")
        }
        .alert("Alarm couldn’t be confirmed", isPresented: Binding(
            get: { companion?.alarmIssue != nil },
            set: { if !$0 { companion?.alarmIssue = nil } },
        )) {
            Button("OK", role: .cancel) { companion?.alarmIssue = nil }
        } message: {
            Text(companion?.alarmIssue ?? "")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refresh()
                synchronizeCompanion()
            }
        }
        .task {
            if companion == nil {
                companion = TimerCompanion()
            }
            store.refresh()
            await companion?.synchronize(run: store.currentRun)
        }
    }

    private func controls(snapshot: TimerSnapshot) -> some View {
        HStack(spacing: 12) {
            GlassIconButton(symbol: "clock.arrow.circlepath", label: "History") {
                sheet = .history
            }
            Spacer()
            GlassIconButton(symbol: "slider.horizontal.3", label: "Run settings") {
                sheet = .settings
            }
            GlassIconButton(symbol: snapshot.controlSymbol, label: snapshot.controlLabel) {
                if snapshot.status == .complete {
                    store.restart()
                } else {
                    store.toggle()
                }
                synchronizeCompanion(userInitiated: store.currentRun.isRunning)
            }
            .contextMenu {
                Button("Start over", systemImage: "arrow.counterclockwise") {
                    showingRestart = true
                }
                .disabled(!store.currentRun.hasStarted)
            }
            .accessibilityHint("Touch and hold for the start over option.")
            .accessibilityAction(named: "Start over") {
                showingRestart = true
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private func synchronizeCompanion(userInitiated: Bool = false) {
        Task {
            await companion?.synchronize(run: store.currentRun, userInitiated: userInitiated)
        }
    }
}

private enum TimerSheet: String, Identifiable {
    case settings
    case history

    var id: Self { self }
}
