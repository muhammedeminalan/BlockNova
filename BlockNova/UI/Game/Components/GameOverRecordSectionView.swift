import SwiftUI

struct GameOverRecordSectionView: View {
    let presentation: GameOverPresentation

    @ViewBuilder
    var body: some View {
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
}
