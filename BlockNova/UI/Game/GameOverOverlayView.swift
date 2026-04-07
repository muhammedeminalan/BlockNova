import SwiftUI

struct GameOverOverlayView: View {
    let presentation: GameOverPresentation
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("OYUN BITTI")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)

                VStack(spacing: 6) {
                    Text("\(presentation.score)")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0))
                    Text("PUAN")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                if presentation.isNewRecord {
                    Text("YENI REKOR")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0))
                } else {
                    Text("EN YUKSEK: \(presentation.highScore)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }

                VStack(spacing: 10) {
                    Button(action: onReplay) {
                        Text("TEKRAR OYNA")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(red: 0.08, green: 0.78, blue: 0.33))
                            )
                    }

                    Button(action: onHome) {
                        Text("Ana Menu")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.06, green: 0.07, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.35), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

#Preview("Game Over") {
    GameOverOverlayView(
        presentation: GameOverPresentation(score: 1240, highScore: 1980, isNewRecord: false),
        onReplay: {},
        onHome: {}
    )
}

#Preview("New Record") {
    GameOverOverlayView(
        presentation: GameOverPresentation(score: 2400, highScore: 2400, isNewRecord: true),
        onReplay: {},
        onHome: {}
    )
}
