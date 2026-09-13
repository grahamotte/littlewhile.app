import SwiftUI

struct GlassIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.primary)
                .frame(width: 50, height: 50)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(CircularGlass())
        .accessibilityLabel(label)
    }
}

struct GlassActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .tint(.primary)
                .buttonBorderShape(.capsule)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .buttonBorderShape(.capsule)
        }
    }

    private var button: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
    }
}

private struct CircularGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
    }
}
