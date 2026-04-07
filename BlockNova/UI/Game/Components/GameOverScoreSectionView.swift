import SwiftUI

struct GameOverScoreSectionView: View {
    let displayedScore: Int
    let pulse: Bool

    var body: some View {
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
                    color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.35),
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
}
