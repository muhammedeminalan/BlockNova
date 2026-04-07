import SwiftUI

struct HomeHeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("BLOCK")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("NOVA")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.94, blue: 1.0),
                                Color(red: 0.0, green: 0.78, blue: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("Surdur · Yerlestir · Patlat")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
        }
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
    }
}
