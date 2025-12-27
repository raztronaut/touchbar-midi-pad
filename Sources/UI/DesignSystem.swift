import SwiftUI

/// The core design system for Sleek, implementing the "macOS 26" aesthetic.
public struct DesignSystem {

    // MARK: - Colors
    public struct Colors {
        /// Primary background for window/panels. Adapts to scheme.
        public static let background = Color("SleekBackground")  // Needs Asset Catalog or programmatic

        // Programmatic Neon Palette
        public static let neonBlue = Color(red: 0.0, green: 0.9, blue: 1.0)
        public static let neonPink = Color(red: 1.0, green: 0.0, blue: 0.8)
        public static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.4)
        public static let neonPurple = Color(red: 0.8, green: 0.2, blue: 1.0)

        /// Active accent color
        public static let accent = neonBlue

        /// Text colors
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary

        /// Surface Colors (Glass)
        public static let glassSurface = Color.white.opacity(0.1)
    }

    // MARK: - Gradients
    public struct Gradients {
        public static let sidebar = LinearGradient(
            colors: [Color.black.opacity(0.4), Color.black.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )

        public static let reactorCore = AngularGradient(
            colors: [.red, .orange, .yellow, .red],
            center: .center
        )

        public static let borderGlow = LinearGradient(
            colors: [Colors.neonBlue, Colors.neonPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Layout
    public struct Layout {
        public static let cornerRadius: CGFloat = 16
        public static let padding: CGFloat = 20
        public static let sidebarWidth: CGFloat = 80  // Slightly wider for sleekness
    }

    // MARK: - Fonts
    public struct Fonts {
        public static func futuristic(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return .system(size: size, weight: weight, design: .rounded)
        }

        public static let branding = Font.system(size: 10, weight: .bold, design: .monospaced)

        public static let header = futuristic(size: 32, weight: .bold)
        public static let body = futuristic(size: 18, weight: .regular)
    }
}

// MARK: - Modifiers

/// "Tahoe" Style Material Background using NSVisualEffectView
struct TahoeMaterial: ViewModifier {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectView(material: material, blendingMode: blendingMode)
                    .opacity(opacity)
            )
    }
}

/// SwiftUI Wrapper for NSVisualEffectView
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

extension View {
    public func tahoeBackground(
        material: NSVisualEffectView.Material = .hudWindow,
        blending: NSVisualEffectView.BlendingMode = .behindWindow
    ) -> some View {
        self.modifier(TahoeMaterial(material: material, blendingMode: blending))
    }

    public func glow(color: Color = DesignSystem.Colors.accent, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
}
