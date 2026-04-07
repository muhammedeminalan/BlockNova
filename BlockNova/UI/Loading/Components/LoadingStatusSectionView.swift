import SwiftUI

struct LoadingStatusSectionView: View {
    let statusText: String
    let dotCount: Int
    let infoText: String?

    var body: some View {
        VStack(spacing: 8) {
            Text("\(statusText)\(String(repeating: ".", count: dotCount))")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))

            if let infoText {
                Text(infoText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.52))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
    }
}
