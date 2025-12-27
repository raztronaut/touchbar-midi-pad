import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = PadGridViewModel()
    @State private var showSettings = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            // Global Background: Deep Mesh-like Gradient
            // Global Background: Deep Mesh-like Gradient
            // We REMOVE the opaque gradient to allow window transparency (Tahoe Style)
            // But we keep a subtle tint? Or we rely on the Window's VisualEffectView.
            // For "Blue Outline" fix, we apply .focusEffectDisabled() to the root or buttons.

            HStack(spacing: 0) {
                // Sidebar (Left)
                VStack(spacing: 20) {
                    // Window Controls / Traffic Light Area
                    // Xcode-style: ~52pt unified bar height.
                    // We just need clear space for the traffic lights.
                    Color.clear.frame(height: 38)
                    // Power Button (Reactor Core)
                    Button(
                        action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                                viewModel.togglePower()
                            }
                        },
                        label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        viewModel.isPoweredOn
                                            ? AnyShapeStyle(DesignSystem.Gradients.reactorCore)
                                            : AnyShapeStyle(Color.gray.opacity(0.3))
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(
                                        color: viewModel.isPoweredOn ? .red : .clear, radius: 10
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )

                                Image(systemName: "power")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                    .scaleEffect(viewModel.isPoweredOn ? 1.05 : 1.0)
                    .help("Power")

                    // Randomize Button
                    Button(
                        action: {
                            withAnimation { viewModel.randomizeSamples() }
                        },
                        label: {
                            Image(systemName: "shuffle")
                                .font(.system(size: 20))
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                .frame(width: 40, height: 40)
                                .tahoeBackground(material: .contentBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                    )
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                    .help("Randomize Kit")

                    Spacer()

                    // Settings Button (Orb)
                    Button(
                        action: { showSettings.toggle() },
                        label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(width: 44, height: 44)
                                .tahoeBackground(material: .hudWindow)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .shadow(radius: 5)
                        }
                    )
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                    .popover(isPresented: $showSettings) {
                        SettingsView(viewModel: viewModel)
                    }

                    // Footer / Branding
                    VStack(spacing: 4) {
                        Text("Sleek v1.0.0")
                        Text("© Razi Syed")
                    }
                    .font(DesignSystem.Fonts.branding)
                    .foregroundColor(Color.white.opacity(0.3))
                    .padding(.bottom, 20)
                }
                .frame(width: DesignSystem.Layout.sidebarWidth)
                .padding(.top, 10)
                // Sidebar Transparency
                .tahoeBackground(material: .sidebar)
                // CRITICAL: This allows the sidebar material to go behind traffic lights
                .ignoresSafeArea(.all, edges: .top)
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(Color.white.opacity(0.05)),
                    alignment: .trailing
                )

                // Grid (Right)
                GeometryReader { geo in
                    let height = geo.size.height

                    // We need to feed it: Top Row items (8..11), Mid (4..7), Bot (0..3).
                    let sortedPads = [
                        viewModel.pads.filter { $0.id >= 8 },  // Top
                        viewModel.pads.filter { $0.id >= 4 && $0.id < 8 },  // Mid
                        viewModel.pads.filter { $0.id < 4 },  // Bot
                    ].flatMap { $0 }

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4),
                        spacing: 14
                    ) {
                        ForEach(sortedPads) { pad in
                            PadView(model: pad, excessiveVisuals: viewModel.useExcessiveVisuals)
                                .frame(height: (height - 60) / 3)
                        }
                    }
                    .padding(30)
                    .opacity(viewModel.isPoweredOn ? 1.0 : 0.3)  // Dim when off
                    .blur(radius: viewModel.isPoweredOn ? 0 : 5)
                    .animation(.easeInOut, value: viewModel.isPoweredOn)
                }
                .tahoeBackground(material: .windowBackground)  // Ensure content area has material
                .ignoresSafeArea(.all, edges: .top)  // Extend behind title bar
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: Binding(get: { !hasSeenOnboarding }, set: { _ in })) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
    }
}

// Extracted Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: PadGridViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(DesignSystem.Fonts.futuristic(size: 16, weight: .bold))
            Divider()

            Toggle("Excessive Visuals", isOn: $viewModel.useExcessiveVisuals)
                .toggleStyle(.switch)

            Button("Rescan Audio Samples") {
                viewModel.reloadSamples()
            }
            .buttonStyle(.bordered)
            .tint(DesignSystem.Colors.accent)
            .focusEffectDisabled()
        }
        .padding()
        .frame(width: 220)
        .tahoeBackground(material: .popover)
    }
}
