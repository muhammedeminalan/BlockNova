import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    let onPlay: () -> Void
    let onOpenLeaderboard: () -> Void
    let onOpenSettings: () -> Void

    @State private var reveal = false
    @State private var pulse = false

    init(
        viewModel: HomeViewModel,
        onPlay: @escaping () -> Void,
        onOpenLeaderboard: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onPlay = onPlay
        self.onOpenLeaderboard = onOpenLeaderboard
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                HomeBackgroundView()
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer(minLength: max(12, proxy.safeAreaInsets.top + 6))

                    HomeHeaderView()

                    HomeHighScoreCardView(
                        highScore: viewModel.highScore,
                        pulse: pulse
                    )

                    HomePrimaryPlayButton(action: onPlay)

                    secondaryButtons

                    Spacer(minLength: max(18, proxy.safeAreaInsets.bottom + 10))
                }
                .padding(.horizontal, 22)
                .scaleEffect(reveal ? 1.0 : 0.94)
                .opacity(reveal ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.83),
                    value: reveal
                )
            }
        }
        .onAppear {
            viewModel.refreshHighScore()
            startEntranceIfNeeded()
        }
    }

    private var secondaryButtons: some View {
        VStack(spacing: 12) {
            HomeSecondaryButton(
                title: "Liderlik",
                systemImage: "trophy.fill",
                tint: Color(red: 0.0, green: 0.83, blue: 1.0),
                action: onOpenLeaderboard
            )

            HomeSecondaryButton(
                title: "Ayarlar",
                systemImage: "gearshape.fill",
                tint: .white,
                action: onOpenSettings
            )
        }
    }

    private func startEntranceIfNeeded() {
        guard !reveal else { return }
        reveal = true
        pulse = true
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(),
        onPlay: {},
        onOpenLeaderboard: {},
        onOpenSettings: {}
    )
}
