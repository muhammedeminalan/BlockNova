import SwiftUI

struct GameOverHeaderView: View {
    var body: some View {
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
}
