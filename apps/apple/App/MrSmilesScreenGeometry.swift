import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum MrSmilesScreenGeometry {
    static func cornerRadius(safeAreaTop: CGFloat, safeAreaBottom: CGFloat) -> CGFloat {
        guard safeAreaBottom > 0 else { return 0 }
        return min(80, max(60, safeAreaTop, safeAreaBottom * 1.8))
    }
}

struct MrSmilesScreenGeometryReader: View {
    @Binding var cornerRadius: CGFloat?

    var body: some View {
        #if canImport(UIKit)
        MrSmilesCornerProbeRepresentable(cornerRadius: $cornerRadius)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        #else
        Color.clear
        #endif
    }
}

#if canImport(UIKit)
private struct MrSmilesCornerProbeRepresentable: UIViewRepresentable {
    @Binding var cornerRadius: CGFloat?

    func makeUIView(context: Context) -> MrSmilesCornerProbe {
        MrSmilesCornerProbe { cornerRadius = $0 }
    }

    func updateUIView(_ uiView: MrSmilesCornerProbe, context: Context) {
        uiView.onRadiusChange = { cornerRadius = $0 }
    }
}

private final class MrSmilesCornerProbe: UIView {
    var onRadiusChange: (CGFloat) -> Void
    private var lastRadius: CGFloat?

    init(onRadiusChange: @escaping (CGFloat) -> Void) {
        self.onRadiusChange = onRadiusChange
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        if #available(iOS 26.0, *) {
            cornerConfiguration = .uniformCorners(radius: .containerConcentric(minimum: 0))
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard window != nil, bounds.width > 0, bounds.height > 0 else { return }
        if #available(iOS 26.0, *) {
            let radius = effectiveRadius(corner: .allCorners)
            guard radius != lastRadius else { return }
            lastRadius = radius
            Task { @MainActor [weak self] in
                guard let self, self.lastRadius == radius else { return }
                self.onRadiusChange(radius)
            }
        }
    }
}
#endif
