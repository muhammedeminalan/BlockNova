import SwiftUI

struct GameOverActionButtonsView: View {
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
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
                                        Color(red: 0.0, green: 0.86, blue: 0.40),
                                        Color(red: 0.0, green: 0.72, blue: 0.32),
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
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.17), lineWidth: 1)
                            )
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
