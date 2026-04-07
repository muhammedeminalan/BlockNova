import SwiftUI

struct LoadingBlockGridView: View {
    let animationStep: Int
    let gridColors: [Color]

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(24), spacing: 8), count: 3)

        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<9, id: \.self) { index in
                let isActive = (animationStep + index) % 9 < 3
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? gridColors[index] : Color.white.opacity(0.12))
                    .frame(width: 24, height: 24)
                    .scaleEffect(isActive ? 1.12 : 0.95)
                    .shadow(
                        color: isActive ? gridColors[index].opacity(0.45) : .clear,
                        radius: isActive ? 8 : 0,
                        x: 0,
                        y: 3
                    )
                    .animation(.easeInOut(duration: 0.28), value: animationStep)
            }
        }
    }
}
