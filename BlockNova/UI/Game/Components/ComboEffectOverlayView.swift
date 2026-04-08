import SwiftUI

struct ComboEffectOverlayView: View {
    let presentation: ComboEffectPresentation
    let onFinished: () -> Void

    @State private var isVisible = false
    @State private var isGlowVisible = false
    @State private var pointsVisible = false

    var body: some View {
        GeometryReader { proxy in
            let safeHeight = max(0, proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
            let safeCenterY = proxy.safeAreaInsets.top + (safeHeight * 0.5)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                style.glowColor.opacity(0.55),
                                style.glowColor.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: 160
                        )
                    )
                    .frame(width: 230, height: 230)
                    .scaleEffect(isGlowVisible ? style.glowEndScale : 0.55)
                    .opacity(isGlowVisible ? 0.9 : 0.0)

                VStack(spacing: 8) {
                    Text(presentation.title)
                        .font(.system(size: style.titleSize, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: style.titleGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: style.glowColor.opacity(0.45), radius: 18, x: 0, y: 8)

                    Text("+\(presentation.points)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .opacity(pointsVisible ? 1.0 : 0.0)
                        .offset(y: pointsVisible ? 0 : 12)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.34))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                )
                .rotationEffect(.degrees(isVisible ? 0 : style.entryRotation))
                .scaleEffect(isVisible ? 1.0 : style.entryScale)
                .offset(y: isVisible ? style.visibleOffsetY : style.hiddenOffsetY)
                .opacity(isVisible ? 1.0 : 0.0)
            }
            .position(x: proxy.size.width * 0.5, y: safeCenterY)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear {
            playAnimation()
        }
    }

    private var style: ComboStyle {
        ComboStyle(level: presentation.level, variant: presentation.styleVariant)
    }

    private func playAnimation() {
        withAnimation(.spring(response: style.entryResponse, dampingFraction: style.entryDamping)) {
            isVisible = true
            isGlowVisible = true
        }

        withAnimation(.easeOut(duration: 0.24).delay(0.06)) {
            pointsVisible = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            withAnimation(.easeIn(duration: 0.26)) {
                isVisible = false
                isGlowVisible = false
                pointsVisible = false
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            onFinished()
        }
    }
}

private struct ComboStyle {
    let titleGradient: [Color]
    let glowColor: Color
    let titleSize: CGFloat
    let entryScale: CGFloat
    let entryRotation: CGFloat
    let hiddenOffsetY: CGFloat
    let visibleOffsetY: CGFloat
    let glowEndScale: CGFloat
    let entryResponse: CGFloat
    let entryDamping: CGFloat

    init(level: ComboEffectPresentation.Level, variant: Int) {
        switch level {
        case .line:
            titleGradient = [Color.white, Color(red: 0.78, green: 0.96, blue: 1.0)]
            glowColor = Color(red: 0.0, green: 0.83, blue: 1.0)
            titleSize = 36
            entryScale = 0.56
            entryRotation = variant == 0 ? -8 : 8
            hiddenOffsetY = 26
            visibleOffsetY = -22
            glowEndScale = variant == 2 ? 1.38 : 1.25
            entryResponse = 0.34
            entryDamping = 0.76
        case .double:
            titleGradient = [Color(red: 1.0, green: 0.94, blue: 0.62), Color(red: 1.0, green: 0.82, blue: 0.0)]
            glowColor = Color(red: 1.0, green: 0.76, blue: 0.0)
            titleSize = 42
            entryScale = 0.50
            entryRotation = variant == 1 ? -12 : 10
            hiddenOffsetY = 34
            visibleOffsetY = -28
            glowEndScale = variant == 0 ? 1.5 : 1.42
            entryResponse = 0.32
            entryDamping = 0.74
        case .mega:
            titleGradient = [Color(red: 0.84, green: 1.0, blue: 1.0), Color(red: 0.05, green: 0.88, blue: 1.0)]
            glowColor = Color(red: 0.06, green: 0.86, blue: 1.0)
            titleSize = 46
            entryScale = 0.44
            entryRotation = variant == 2 ? -9 : 9
            hiddenOffsetY = 42
            visibleOffsetY = -34
            glowEndScale = variant == 1 ? 1.75 : 1.62
            entryResponse = 0.30
            entryDamping = 0.71
        }
    }
}
