import SwiftUI

struct HomeHighScoreCardView: View {
    let highScore: Int
    let pulse: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.35),
                                Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0))
            }

            Text("EN YUKSEK SKOR")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))

            Text("\(highScore)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.94, blue: 0.65),
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                            Color(red: 0.0, green: 0.88, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.30), radius: 16, x: 0, y: 8)
                .scaleEffect(pulse ? 1.03 : 0.97)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(
                        autoreverses: true
                    ),
                    value: pulse
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}
