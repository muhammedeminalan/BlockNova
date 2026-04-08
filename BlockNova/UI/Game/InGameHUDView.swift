import SwiftUI

struct InGameHUDView: View {
    let score: Int
    let highScore: Int
    let onSettingsTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let topInset = max(10, proxy.safeAreaInsets.top + 2)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Text("♛")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.yellow.opacity(0.95))

                        Text("\(highScore)")
                            .font(
                                .system(
                                    size: 24,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Color.yellow.opacity(0.95))
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, topInset)

                    Text("\(score)")
                        .font(
                            .system(size: 56, weight: .heavy, design: .rounded)
                        )
                        .foregroundStyle(Color.white.opacity(0.96))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .padding(.top, 4)

                    Spacer()
                }
                // Neden: Skor katmani sadece bilgi gostersin, surukleme dokunusunu bloklamasin.
                .allowsHitTesting(false)

                HStack {
                    Spacer()

                    Button(action: onSettingsTap) {
                        ZStack {
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .fill(Color.black.opacity(0.22))
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .stroke(Color.cyan.opacity(0.55), lineWidth: 1.4)

                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.yellow.opacity(0.95))
                        }
                        .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, topInset - 1)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        InGameHUDView(
            score: 8760,
            highScore: 20000,
            onSettingsTap: {}
        )
    }
}
