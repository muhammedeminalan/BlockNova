import SwiftUI

struct GameOverOverlayView: View {
    let presentation: GameOverPresentation
    let onReplay: () -> Void
    let onHome: () -> Void

    @State private var reveal = false
    @State private var pulse = false
    @State private var displayedScore = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            GameOverBackgroundGlowView()
                .opacity(reveal ? 1.0 : 0.0)

            VStack(spacing: 18) {
                GameOverHeaderView()

                GameOverScoreSectionView(
                    displayedScore: displayedScore,
                    pulse: pulse
                )

                GameOverRecordSectionView(presentation: presentation)

                GameOverActionButtonsView(
                    onReplay: onReplay,
                    onHome: onHome
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 30)
            .frame(maxWidth: 360)
            .frame(minHeight: 520)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: Color.black.opacity(0.45), radius: 36, x: 0, y: 20)
            .scaleEffect(reveal ? 1.0 : 0.92)
            .opacity(reveal ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.82),
                value: reveal
            )
            .padding(.horizontal, 20)
        }
        .onAppear {
            startEntrance()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.22).opacity(0.95),
                        Color(red: 0.06, green: 0.07, blue: 0.18).opacity(0.98),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.48),
                        Color.white.opacity(0.14),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.2
            )
    }

    private func startEntrance() {
        guard !reveal else { return }
        reveal = true
        pulse = true

        displayedScore = 0
        withAnimation(.easeOut(duration: 0.85)) {
            displayedScore = presentation.score
        }
    }
}

#Preview("Game Over") {
    GameOverOverlayView(
        presentation: GameOverPresentation(
            score: 1240,
            highScore: 1980,
            isNewRecord: false
        ),
        onReplay: {},
        onHome: {}
    )
}

#Preview("New Record") {
    GameOverOverlayView(
        presentation: GameOverPresentation(
            score: 2400,
            highScore: 2400,
            isNewRecord: true
        ),
        onReplay: {},
        onHome: {}
    )
}
