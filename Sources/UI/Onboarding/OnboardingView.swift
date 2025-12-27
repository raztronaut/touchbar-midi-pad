import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0

    let pages = [
        OnboardingPage(
            title: "Welcome to Sleek",
            description: "Turn your MacBook trackpad into an expressive MIDI instrument.",
            icon: "waveform.path.ecg",
            color: DesignSystem.Colors.neonBlue
        ),
        OnboardingPage(
            title: "Connect & Play",
            description:
                "Connect your DAW. Touch the grid. Control modulation with finger placement.",
            icon: "hand.point.up.left.fill",
            color: DesignSystem.Colors.neonPurple
        ),
        OnboardingPage(
            title: "You're Ready",
            description: "Power on the reactor core to begin.",
            icon: "bolt.fill",
            color: DesignSystem.Colors.neonGreen
        ),
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Content
                ZStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        if currentPage == index {
                            VStack(spacing: 20) {
                                Image(systemName: pages[index].icon)
                                    .font(.system(size: 80))
                                    .foregroundColor(pages[index].color)
                                    .shadow(color: pages[index].color.opacity(0.5), radius: 20)

                                Text(pages[index].title)
                                    .font(DesignSystem.Fonts.header)
                                    .foregroundColor(.white)

                                Text(pages[index].description)
                                    .font(DesignSystem.Fonts.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .padding()
                        }
                    }
                }
                .frame(height: 300)
                .animation(.spring(), value: currentPage)

                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 10)

                // Controls
                HStack {
                    if currentPage == pages.count - 1 {
                        Spacer()
                        Button("Get Started") {
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignSystem.Colors.accent)
                        .controlSize(.large)
                        .focusEffectDisabled()
                        Spacer()
                    } else {
                        Button("Skip") {
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .focusEffectDisabled()

                        Spacer()

                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(.bordered)
                        .focusEffectDisabled()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}
