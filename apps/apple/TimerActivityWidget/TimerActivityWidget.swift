#if os(iOS)
import ActivityKit
import SwiftUI
import WidgetKit

@main
struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerActivityView(context: context)
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            let content = TimerActivityView(context: context)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text("Little While")
                            .font(.subheadline.weight(.medium))
                    } icon: {
                        content.symbol
                    }
                    .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.attributes.goalSeconds / 60) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        HStack(alignment: .lastTextBaseline) {
                            content.countdown
                                .font(.system(size: 38, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .leading)

                            content.status
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        content.progress
                            .tint(.white)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                content.symbol
                    .font(.system(size: 14, weight: .medium))
            } compactTrailing: {
                if content.hasFinished {
                    Text("Done")
                        .font(.caption.weight(.medium))
                } else {
                    content.countdown
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .monospacedDigit()
                        .frame(width: 52)
                        .minimumScaleFactor(0.75)
                }
            } minimal: {
                content.ring
                    .frame(width: 23, height: 23)
            }
            .keylineTint(.white.opacity(0.6))
        }
    }
}

private struct TimerActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var hasFinished: Bool {
        context.state.isComplete || (context.isStale && !context.state.isPaused)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text("Little While")
                        .font(.subheadline.weight(.medium))
                } icon: {
                    symbol
                }

                Spacer()

                Text("\(context.attributes.goalSeconds / 60) min goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 16) {
                countdown
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.75)

                status
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            progress
                .tint(.primary)
        }
        .padding(20)
        .accessibilityElement(children: .combine)
    }

    var symbol: some View {
        Image(systemName: hasFinished ? "checkmark.circle.fill" : (context.state.isPaused ? "pause.fill" : "timer"))
            .accessibilityHidden(true)
    }

    var status: some View {
        Text(hasFinished ? "Time’s up" : (context.state.isPaused ? "Paused" : "Focusing"))
    }

    @ViewBuilder
    var countdown: some View {
        if hasFinished {
            Text("00:00")
        } else if !context.state.isPaused, let deadline = context.state.deadline {
            Text(
                timerInterval: deadline.addingTimeInterval(-Double(context.attributes.goalSeconds))...deadline,
                countsDown: true,
                showsHours: false,
            )
            .contentTransition(.numericText(countsDown: true))
        } else {
            Text(
                Duration.seconds(max(0, context.state.remainingSeconds).rounded(.up))
                    .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))),
            )
        }
    }

    @ViewBuilder
    var progress: some View {
        if hasFinished {
            ProgressView(value: 1)
        } else if !context.state.isPaused, let deadline = context.state.deadline {
            ProgressView(
                timerInterval: deadline.addingTimeInterval(-Double(context.attributes.goalSeconds))...deadline,
                countsDown: false,
            ) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
        } else {
            ProgressView(value: 1 - context.state.remainingSeconds / Double(max(1, context.attributes.goalSeconds)))
        }
    }

    @ViewBuilder
    var ring: some View {
        if hasFinished {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 21, weight: .regular))
                .accessibilityLabel("Timer complete")
        } else if context.state.isPaused {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 2)

                Image(systemName: "pause.fill")
                    .font(.system(size: 9, weight: .semibold))
            }
            .accessibilityLabel("Timer paused")
        } else {
            progress
                .progressViewStyle(.circular)
                .tint(.white)
                .accessibilityLabel("Timer progress")
        }
    }
}
#endif
