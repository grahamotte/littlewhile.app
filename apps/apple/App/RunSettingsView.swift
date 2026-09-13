import SwiftUI

struct RunSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme: String
    @State private var visibleTheme: String?
    @State private var selectedMinute: Int
    @State private var visibleMinute: Int?
    @State private var didPositionSelectors = false

    let onSet: (Int, String) -> Void

    init(currentRun: FocusRun, onSet: @escaping (Int, String) -> Void) {
        _selectedTheme = State(initialValue: TimerThemes.resolve(currentRun.theme).id)
        _visibleTheme = State(initialValue: nil)
        _selectedMinute = State(initialValue: min(120, max(1, currentRun.goalSeconds / 60)))
        _visibleMinute = State(initialValue: nil)
        self.onSet = onSet
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    themeSelector
                    minuteSelector
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GlassActionButton(title: "Set") {
                onSet(selectedMinute, selectedTheme)
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 22)
            .background(.background)
        }
        .sensoryFeedback(.selection, trigger: selectedMinute)
        .sensoryFeedback(.selection, trigger: selectedTheme)
        .task {
            await Task.yield()
            visibleTheme = selectedTheme
            visibleMinute = selectedMinute
            await Task.yield()
            didPositionSelectors = true
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text("Settings")
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))

            Spacer(minLength: 0)

            GlassIconButton(symbol: "xmark", label: "Close settings") {
                dismiss()
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 30)
        .padding(.bottom, 16)
    }

    private var themeSelector: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Theme")
                .font(.headline)
                .padding(.horizontal, 28)

            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 22) {
                        ForEach(TimerThemes.all, id: \.id) { theme in
                            Button {
                                selectedTheme = theme.id
                                visibleTheme = theme.id
                            } label: {
                                VStack(spacing: 13) {
                                    theme.preview
                                        .frame(width: 176, height: 176)
                                        .clipShape(RoundedRectangle(cornerRadius: 26))
                                        .padding(5)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 31)
                                                .strokeBorder(
                                                    selectedTheme == theme.id ? Color.primary : Color.clear,
                                                    lineWidth: 2,
                                                )
                                        }
                                        .overlay(alignment: .bottomTrailing) {
                                            if selectedTheme == theme.id {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(.background)
                                                    .frame(width: 24, height: 24)
                                                    .background(.primary, in: Circle())
                                                    .padding(13)
                                            }
                                        }

                                    Text(theme.name)
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(theme.name) theme")
                            .accessibilityValue(selectedTheme == theme.id ? "Selected" : "Not selected")
                            .accessibilityAddTraits(selectedTheme == theme.id ? .isSelected : [])
                            .id(theme.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, max(24, (geometry.size.width - 186) / 2), for: .scrollContent)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $visibleTheme, anchor: .center)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.07),
                            .init(color: .black, location: 0.93),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing,
                    )
                }
            }
            .frame(height: 220)
        }
    }

    private var minuteSelector: some View {
        VStack(spacing: 18) {
            Text("Duration")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(selectedMinute)")
                    .font(.system(size: 52, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("min")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)

            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 0) {
                        ForEach(1...120, id: \.self) { minute in
                            VStack(spacing: 10) {
                                Capsule()
                                    .fill(.primary.opacity(minute.isMultiple(of: 5) ? 0.5 : 0.18))
                                    .frame(width: 1.5, height: minute.isMultiple(of: 5) ? 38 : 22)
                                    .frame(height: 38, alignment: .top)

                                if minute.isMultiple(of: 5) {
                                    Text("\(minute)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .fixedSize()
                                }
                            }
                            .frame(width: 14)
                            .id(minute)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, max(0, geometry.size.width / 2 - 7), for: .scrollContent)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $visibleMinute, anchor: .center)
                .onChange(of: visibleMinute) { _, minute in
                    if didPositionSelectors, let minute {
                        selectedMinute = minute
                    }
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.primary)
                        .frame(width: 3, height: 46)
                        .offset(y: -4)
                        .allowsHitTesting(false)
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.18),
                            .init(color: .black, location: 0.82),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing,
                    )
                }
            }
            .frame(height: 74)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Timer duration")
            .accessibilityValue("\(selectedMinute) \(selectedMinute == 1 ? "minute" : "minutes")")
            .accessibilityHint("Swipe up or down to adjust by one minute")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    selectedMinute = min(120, selectedMinute + 1)
                    visibleMinute = selectedMinute
                case .decrement:
                    selectedMinute = max(1, selectedMinute - 1)
                    visibleMinute = selectedMinute
                @unknown default:
                    break
                }
            }
        }
    }
}
