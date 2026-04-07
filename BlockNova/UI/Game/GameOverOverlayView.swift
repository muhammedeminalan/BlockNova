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

            backgroundGlow
                .opacity(reveal ? 1.0 : 0.0)

            VStack(spacing: 18) {
                header

                scoreSection

                recordSection

                buttonSection
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

    private var backgroundGlow: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 55)
                .offset(x: 120, y: -220)

            Circle()
                .fill(Color(red: 0.0, green: 0.82, blue: 0.35).opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: -130, y: 220)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("OYUN BITTI")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.white)

            Text("Bir tur daha dene ve rekoru zorla")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
    }

    private var scoreSection: some View {
        VStack(spacing: 8) {
            Text("\(displayedScore)")
                .font(.system(size: 58, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.94, blue: 0.65),
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(
                        0.35
                    ),
                    radius: 18,
                    x: 0,
                    y: 8
                )
                .scaleEffect(pulse ? 1.02 : 0.98)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: pulse
                )

            Text("PUAN")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var recordSection: some View {
        if presentation.isNewRecord {
            Text("YENI REKOR")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.16)
                )
                .clipShape(Capsule())
        } else {
            Text("EN YUKSEK: \(presentation.highScore)")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button(action: onReplay) {
                Text("TEKRAR OYNA")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 0.0,
                                            green: 0.86,
                                            blue: 0.40
                                        ),
                                        Color(
                                            red: 0.0,
                                            green: 0.72,
                                            blue: 0.32
                                        ),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(red: 0.0, green: 0.82, blue: 0.35)
                                    .opacity(0.45),
                                radius: 18,
                                x: 0,
                                y: 10
                            )
                    )
            }

            Button(action: onHome) {
                Text("Ana Menu")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.09))
                            .overlay(
                                RoundedRectangle(
                                    cornerRadius: 16,
                                    style: .continuous
                                )
                                .stroke(Color.white.opacity(0.17), lineWidth: 1)
                            )
                    )
            }
        }
        .buttonStyle(.plain)
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
