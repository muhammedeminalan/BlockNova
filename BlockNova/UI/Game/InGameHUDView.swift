import SwiftUI

struct InGameHUDView: View {
    let score: Int
    let highScore: Int
    let onSettingsTap: () -> Void

    @State private var displayedScore: Double = 0
    @State private var scorePulseScale: CGFloat = 1
    @State private var scoreGlowOpacity: Double = 0
    @State private var gradientPhase: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let topInset = max(10, proxy.safeAreaInsets.top + 2)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Text("♛")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.yellow.opacity(0.95))

                        Text(plainNumber(highScore))
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

                    ZStack {
                        scoreText
                            .foregroundStyle(Color.white.opacity(0.22))

                        scoreGradient
                            .mask(scoreText)
                            .shadow(
                                color: Color.cyan.opacity(
                                    scoreGlowOpacity * 0.55
                                ),
                                radius: 10,
                                x: 0,
                                y: 0
                            )

                        scoreText
                            .foregroundStyle(Color.white.opacity(0.12))
                            .blur(radius: 0.8)
                            .opacity(scoreGlowOpacity * 0.85)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 64,
                        maxHeight: 64,
                        alignment: .center
                    )
                    .scaleEffect(scorePulseScale)
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
            .onAppear {
                displayedScore = Double(score)
            }
            .onChange(of: score) { newScore in
                animateScoreChange(to: newScore)
            }
        }
    }

    private var scoreText: some View {
        AnimatedCounterTextView(
            value: displayedScore,
            fontSize: 56,
            formatter: plainNumber
        )
    }

    private var scoreGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.96, blue: 0.78),
                Color(red: 1.00, green: 0.82, blue: 0.28),
                Color(red: 0.36, green: 0.95, blue: 1.00),
                Color.white,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .hueRotation(.degrees(gradientPhase * 40))
    }

    private func animateScoreChange(to newScore: Int) {
        if newScore <= Int(displayedScore) {
            displayedScore = Double(newScore)
            return
        }

        withAnimation(.interpolatingSpring(stiffness: 210, damping: 24)) {
            displayedScore = Double(newScore)
            scorePulseScale = 1.05
        }
        withAnimation(.easeOut(duration: 0.28).delay(0.05)) {
            scorePulseScale = 1
        }

        withAnimation(.easeOut(duration: 0.22)) {
            scoreGlowOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.52).delay(0.08)) {
            scoreGlowOpacity = 0
        }

        // Neden: Skor artisinda sabit renk hissini kirip daha canli his vermek.
        withAnimation(.linear(duration: 0.55)) {
            gradientPhase += 1
        }
    }

    private func plainNumber(_ value: Int) -> String {
        String(value)
    }
}

private struct AnimatedCounterTextView: View, Animatable {
    var value: Double
    let fontSize: CGFloat
    let formatter: (Int) -> String

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(formatter(max(0, Int(value.rounded()))))
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .minimumScaleFactor(0.55)
            .lineLimit(1)
            .monospacedDigit()
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
