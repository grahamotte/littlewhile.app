import SwiftUI

struct RunHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    let store: RunStore

    var body: some View {
        VStack(spacing: 0) {
            header

            if store.history.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.history) { run in
                        historyRow(run)
                            .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    store.deleteRun(id: run.id)
                                }
                            }
                            .contextMenu {
                                Button("Delete run", systemImage: "trash", role: .destructive) {
                                    store.deleteRun(id: run.id)
                                }
                            }
                            .accessibilityAction(named: Text("Delete run")) {
                                store.deleteRun(id: run.id)
                            }
                    }

                    Text("Every little while counts.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("History")
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))

                Text("Time you made for yourself.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            GlassIconButton(symbol: "xmark", label: "Close history") {
                dismiss()
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 30)
        .padding(.bottom, 26)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 35, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 92, height: 92)
                .background(.primary.opacity(0.04), in: Circle())
                .padding(.bottom, 4)
                .accessibilityHidden(true)

            Text("A little time adds up.")
                .font(.system(.title2, design: .rounded, weight: .medium))

            Text("When you set your next timer,\nyour previous run will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
    }

    private func historyRow(_ run: FocusRun) -> some View {
        let now = Date.now
        let complete = run.isComplete(at: now)

        return VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(run.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(Duration.seconds(run.elapsed(at: now)).formatted(.time(pattern: .minuteSecond)))
                            .font(.system(.title2, design: .rounded, weight: .medium))

                        Text("of \(Duration.seconds(run.goalSeconds).formatted(.time(pattern: .minuteSecond)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .monospacedDigit()
                }

                Spacer(minLength: 0)

                Image(systemName: complete ? "checkmark" : "clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(complete ? Color.primary : Color.secondary)
                    .frame(width: 34, height: 34)
                    .background(.primary.opacity(0.05), in: Circle())
                    .accessibilityHidden(true)
            }

            ProgressView(value: run.fraction(at: now))
                .tint(.primary.opacity(0.65))
                .accessibilityLabel("Run progress")

            HStack {
                Text(TimerThemes.resolve(run.theme).name)

                Spacer()

                Text(complete ? "Completed" : (run.hasStarted ? "Finished early" : "Not started"))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}
