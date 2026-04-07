import SwiftUI

struct GameOverBackgroundGlowView: View {
    var body: some View {
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
}
