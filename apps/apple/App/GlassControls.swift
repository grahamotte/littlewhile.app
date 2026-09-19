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
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .modifier(CapsuleGlass())
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

private struct CapsuleGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
    }
}
