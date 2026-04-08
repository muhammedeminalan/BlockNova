import SwiftUI

struct ComboEffectOverlayView: View {
    let presentation: ComboEffectPresentation
    let onFinished: () -> Void

    @State private var cardOpacity: CGFloat = 0
    @State private var cardScale: CGFloat = 0.8
    @State private var cardRotation: CGFloat = 0
    @State private var cardOffsetY: CGFloat = 0
    @State private var glowScale: CGFloat = 0.6
    @State private var glowOpacity: CGFloat = 0
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: CGFloat = 0
    @State private var trailOpacity: CGFloat = 0
    @State private var pointsOpacity: CGFloat = 0
    @State private var pointsOffsetY: CGFloat = 12
    @State private var streakOpacity: CGFloat = 0
    @State private var flashOpacity: CGFloat = 0
    @State private var shakeX: CGFloat = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let safeHeight = max(
                0,
                proxy.size.height - proxy.safeAreaInsets.top
                    - proxy.safeAreaInsets.bottom
            )
            let safeCenterY = proxy.safeAreaInsets.top + (safeHeight * 0.5)

            ZStack {
                if flashOpacity > 0.001 {
                    Rectangle()
                        .fill(Color.white.opacity(flashOpacity))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                profile.glowColor.opacity(0.72),
                                profile.glowColor.opacity(0.00),
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 190
                        )
                    )
                    .frame(width: 260, height: 260)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)

                Circle()
                    .stroke(
                        profile.glowColor.opacity(0.78),
                        lineWidth: profile.ringLineWidth
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                profile.glowColor.opacity(0.0),
                                profile.glowColor.opacity(
                                    profile.trailBaseOpacity
                                ),
                                profile.glowColor.opacity(0.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 300, height: 28)
                    .scaleEffect(
                        x: 0.9,
                        y: 1.0 + CGFloat(presentation.streak - 1) * 0.06
                    )
                    .blur(radius: 6)
                    .opacity(trailOpacity)

                cardView
            }
            .offset(x: shakeX)
            .position(x: proxy.size.width * 0.5, y: safeCenterY)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
    }

    private var cardView: some View {
        VStack(spacing: 8) {
            Text(presentation.title)
                .font(
                    .system(
                        size: profile.titleSize,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: profile.titleGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: profile.glowColor.opacity(0.50),
                    radius: 20,
                    x: 0,
                    y: 8
                )

            Text("+\(presentation.points)")
                .font(
                    .system(
                        size: profile.pointsSize,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .foregroundStyle(profile.pointsColor)
                .opacity(pointsOpacity)
                .offset(y: pointsOffsetY)

            if let streakText = presentation.streakText {
                Text(streakText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(profile.streakTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(profile.streakBadgeBackground.opacity(0.95))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        Color.white.opacity(0.25),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .opacity(streakOpacity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.17), lineWidth: 1)
                )
        )
        .rotationEffect(.degrees(cardRotation))
        .scaleEffect(cardScale)
        .offset(y: cardOffsetY)
        .opacity(cardOpacity)
    }

    private var profile: ComboVisualProfile {
        ComboVisualProfile(
            level: presentation.level,
            variant: presentation.styleVariant,
            streak: presentation.streak
        )
    }

    private func startAnimation() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            resetState()

            if profile.anticipationDuration > 0 {
                withAnimation(.easeIn(duration: profile.anticipationDuration)) {
                    cardScale = profile.anticipationScale
                    cardOffsetY = profile.hiddenOffsetY + 8
                }
                try? await Task.sleep(
                    nanoseconds: profile.anticipationDuration.nanoseconds
                )
            }

            withAnimation(
                .interpolatingSpring(
                    stiffness: profile.entryStiffness,
                    damping: profile.entryDamping
                )
            ) {
                cardOpacity = 1
                cardScale = 1
                cardRotation = 0
                cardOffsetY = profile.visibleOffsetY
            }

            withAnimation(.easeOut(duration: profile.glowInDuration)) {
                glowOpacity = 0.95
                glowScale = profile.glowEndScale
                ringOpacity = 1
                ringScale = profile.ringEndScale
                trailOpacity = profile.trailBaseOpacity
            }

            withAnimation(.easeOut(duration: 0.22).delay(0.04)) {
                pointsOpacity = 1
                pointsOffsetY = 0
                if presentation.streak >= 2 {
                    streakOpacity = 1
                }
            }

            if profile.flashPeakOpacity > 0 {
                withAnimation(.easeOut(duration: 0.05)) {
                    flashOpacity = profile.flashPeakOpacity
                }
                try? await Task.sleep(nanoseconds: 45_000_000)
                withAnimation(.easeOut(duration: 0.12)) {
                    flashOpacity = 0
                }
            }

            if profile.shakeAmplitude > 0 {
                await runShake(
                    amplitude: profile.shakeAmplitude,
                    steps: profile.shakeSteps
                )
            }

            try? await Task.sleep(nanoseconds: profile.holdDuration.nanoseconds)

            withAnimation(.easeIn(duration: profile.exitDuration)) {
                cardOpacity = 0
                cardScale = 0.90
                cardRotation = profile.exitRotation
                cardOffsetY = profile.visibleOffsetY - 48
                glowOpacity = 0
                ringOpacity = 0
                trailOpacity = 0
                pointsOpacity = 0
                pointsOffsetY = -10
                streakOpacity = 0
                flashOpacity = 0
            }

            try? await Task.sleep(
                nanoseconds: (profile.exitDuration + 0.08).nanoseconds
            )
            onFinished()
        }
    }

    private func resetState() {
        cardOpacity = 0
        cardScale = profile.entryScale
        cardRotation = profile.entryRotation
        cardOffsetY = profile.hiddenOffsetY
        glowScale = 0.62
        glowOpacity = 0
        ringScale = 0.3
        ringOpacity = 0
        trailOpacity = 0
        pointsOpacity = 0
        pointsOffsetY = 12
        streakOpacity = 0
        flashOpacity = 0
        shakeX = 0
    }

    private func runShake(amplitude: CGFloat, steps: Int) async {
        guard steps > 0 else { return }
        let singleStep: UInt64 = 18_000_000
        for step in 0..<steps {
            let direction: CGFloat = step.isMultiple(of: 2) ? 1 : -1
            let progress = CGFloat(step) / CGFloat(max(1, steps - 1))
            let damping = 1 - (progress * 0.6)
            withAnimation(.linear(duration: 0.018)) {
                shakeX = direction * amplitude * damping
            }
            try? await Task.sleep(nanoseconds: singleStep)
        }
        withAnimation(.easeOut(duration: 0.05)) {
            shakeX = 0
        }
    }
}

private struct ComboVisualProfile {
    let titleGradient: [Color]
    let glowColor: Color
    let pointsColor: Color
    let streakTextColor: Color
    let streakBadgeBackground: Color
    let titleSize: CGFloat
    let pointsSize: CGFloat
    let entryScale: CGFloat
    let entryRotation: CGFloat
    let hiddenOffsetY: CGFloat
    let visibleOffsetY: CGFloat
    let anticipationDuration: Double
    let anticipationScale: CGFloat
    let entryStiffness: CGFloat
    let entryDamping: CGFloat
    let glowInDuration: Double
    let glowEndScale: CGFloat
    let ringEndScale: CGFloat
    let ringLineWidth: CGFloat
    let trailBaseOpacity: CGFloat
    let flashPeakOpacity: CGFloat
    let shakeAmplitude: CGFloat
    let shakeSteps: Int
    let holdDuration: Double
    let exitDuration: Double
    let exitRotation: CGFloat

    init(level: ComboEffectPresentation.Level, variant: Int, streak: Int) {
        let sign: CGFloat = variant.isMultiple(of: 2) ? 1 : -1
        let variantSwing: CGFloat = [6, 9, 12, 7, 10, 13][variant % 6]
        let streakBoost = min(CGFloat(streak - 1), 6)

        switch level {
        case .line:
            titleGradient =
                [
                    [Color.white, Color(red: 0.76, green: 0.95, blue: 1.0)],
                    [
                        Color(red: 0.90, green: 1.0, blue: 1.0),
                        Color(red: 0.42, green: 0.92, blue: 1.0),
                    ],
                    [Color.white, Color(red: 0.72, green: 0.90, blue: 1.0)],
                ][variant % 3]
            glowColor = Color(red: 0.0, green: 0.84, blue: 1.0)
            pointsColor = .white
            streakTextColor = .white
            streakBadgeBackground = Color(red: 0.0, green: 0.62, blue: 0.78)
            titleSize = 34
            pointsSize = 23
            entryScale = 0.82
            entryRotation = sign * (variantSwing * 0.35)
            hiddenOffsetY = 28
            visibleOffsetY = -18
            anticipationDuration = 0
            anticipationScale = 1
            entryStiffness = 320
            entryDamping = 26
            glowInDuration = 0.20
            glowEndScale = 1.18 + (streakBoost * 0.03)
            ringEndScale = 1.30 + (streakBoost * 0.02)
            ringLineWidth = 2.3
            trailBaseOpacity = 0.18
            flashPeakOpacity = 0
            shakeAmplitude = 0
            shakeSteps = 0
            holdDuration = 0.18
            exitDuration = 0.20
            exitRotation = -sign * 4
        case .double:
            titleGradient =
                [
                    [
                        Color(red: 1.0, green: 0.95, blue: 0.68),
                        Color(red: 1.0, green: 0.82, blue: 0.0),
                    ],
                    [
                        Color(red: 1.0, green: 0.90, blue: 0.58),
                        Color(red: 1.0, green: 0.70, blue: 0.0),
                    ],
                    [
                        Color(red: 1.0, green: 0.98, blue: 0.72),
                        Color(red: 1.0, green: 0.76, blue: 0.16),
                    ],
                ][variant % 3]
            glowColor = Color(red: 1.0, green: 0.76, blue: 0.0)
            pointsColor = Color(red: 1.0, green: 0.94, blue: 0.78)
            streakTextColor = Color(red: 1.0, green: 0.96, blue: 0.80)
            streakBadgeBackground = Color(red: 0.72, green: 0.44, blue: 0.0)
            titleSize = 41
            pointsSize = 25
            entryScale = 0.72
            entryRotation = sign * (variantSwing * 0.65)
            hiddenOffsetY = 36
            visibleOffsetY = -27
            anticipationDuration = 0
            anticipationScale = 1
            entryStiffness = 360
            entryDamping = 24
            glowInDuration = 0.22
            glowEndScale = 1.42 + (streakBoost * 0.04)
            ringEndScale = 1.54 + (streakBoost * 0.03)
            ringLineWidth = 3.0
            trailBaseOpacity = 0.34
            flashPeakOpacity = 0
            shakeAmplitude = 4 + (streakBoost * 0.4)
            shakeSteps = 6
            holdDuration = 0.30
            exitDuration = 0.24
            exitRotation = sign * 8
        case .mega:
            titleGradient =
                [
                    [
                        Color(red: 0.88, green: 1.0, blue: 1.0),
                        Color(red: 0.08, green: 0.90, blue: 1.0),
                    ],
                    [
                        Color(red: 0.95, green: 0.88, blue: 1.0),
                        Color(red: 0.18, green: 0.72, blue: 1.0),
                    ],
                    [
                        Color(red: 0.82, green: 1.0, blue: 0.98),
                        Color(red: 0.03, green: 0.84, blue: 1.0),
                    ],
                ][variant % 3]
            glowColor = Color(red: 0.06, green: 0.88, blue: 1.0)
            pointsColor = Color(red: 0.86, green: 1.0, blue: 1.0)
            streakTextColor = Color(red: 0.82, green: 1.0, blue: 1.0)
            streakBadgeBackground = Color(red: 0.10, green: 0.56, blue: 0.82)
            titleSize = 47
            pointsSize = 27
            entryScale = 0.62
            entryRotation = sign * variantSwing
            hiddenOffsetY = 44
            visibleOffsetY = -34
            anticipationDuration = 0.08
            anticipationScale = 0.86
            entryStiffness = 420
            entryDamping = 22
            glowInDuration = 0.25
            glowEndScale = 1.70 + (streakBoost * 0.05)
            ringEndScale = 1.90 + (streakBoost * 0.05)
            ringLineWidth = 4.0
            trailBaseOpacity = 0.46
            flashPeakOpacity = 0.30
            shakeAmplitude = 7 + (streakBoost * 0.6)
            shakeSteps = 9
            holdDuration = 0.38
            exitDuration = 0.28
            exitRotation = -sign * 12
        }
    }
}

extension Double {
    fileprivate var nanoseconds: UInt64 {
        UInt64((self * 1_000_000_000).rounded())
    }
}
