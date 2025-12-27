import SwiftUI

struct PadView: View {
    let model: PadModel
    let excessiveVisuals: Bool

    var body: some View {
        ZStack {
            // Background (Inactive Glass)
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.black.opacity(0.2))  // Darker base for contrast
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .stroke(
                            model.isPressed ? model.color : Color.white.opacity(0.1),
                            lineWidth: model.isPressed ? 2 : 1
                        )
                )
                // We use a manual ultra-thin look here for performance in grids
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .fill(Material.thin)
                        .opacity(0.5)
                )

            // Active State (Glow)
            if model.isPressed {
                if !excessiveVisuals {
                    // Simple Mode: Static Colors (No Pressure Dynamics)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(model.color)
                        .opacity(0.6)
                        .blur(radius: 5)

                    RoundedRectangle(cornerRadius: 12)
                        .stroke(model.color, lineWidth: 2)
                        .shadow(color: model.color, radius: 10)
                } else {
                    // Excessive Mode: Dynamic Pressure
                    // Hard Press (1.0) -> Hotter (Redder) + Brighter
                    // Soft Press (0.0) -> Cooler + Fainter

                    let hueShift = Angle(degrees: Double(model.pressure * 20))  // +20deg shift on max pressure
                    let saturation = 1.0 + Double(model.pressure * 0.5)  // Boost saturation

                    RoundedRectangle(cornerRadius: 12)
                        .fill(model.color)
                        .hueRotation(hueShift)
                        .saturation(saturation)
                        .opacity(Double(0.4 + (model.pressure * 0.6)))
                        .blur(radius: 5)

                    RoundedRectangle(cornerRadius: 12)
                        .stroke(model.color, lineWidth: 2 + (CGFloat(model.pressure) * 2))
                        .hueRotation(hueShift)
                        // Wide breathing glow
                        .shadow(color: model.color, radius: CGFloat(10 + (model.pressure * 30)))
                        // Hot white core
                        .shadow(color: Color.white.opacity(Double(model.pressure)), radius: 2)
                }
            }

            // Text Label
            Text(model.name)
                .font(DesignSystem.Fonts.futuristic(size: 14, weight: .bold))
                .foregroundColor(model.isPressed ? .white : DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(4)
                .shadow(color: model.isPressed ? model.color : .clear, radius: 8)
        }
        .scaleEffect(model.isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.5), value: model.isPressed)
    }
}
