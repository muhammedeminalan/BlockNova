import SwiftUI

struct HomeBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.14),
                    Color(red: 0.02, green: 0.03, blue: 0.10),
                    Color(red: 0.01, green: 0.02, blue: 0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 150, y: -240)

            Circle()
                .fill(Color(red: 0.0, green: 0.82, blue: 0.35).opacity(0.17))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -150, y: 250)

            AngularGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.white.opacity(0.04),
                    Color.clear,
                ]),
                center: .center
            )
            .blur(radius: 40)
        }
    }
}
