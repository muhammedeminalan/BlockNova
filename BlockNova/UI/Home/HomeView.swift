import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    let onPlay: () -> Void
    let onOpenLeaderboard: () -> Void
    let onOpenSettings: () -> Void

    init(
        viewModel: HomeViewModel,
        onPlay: @escaping () -> Void,
        onOpenLeaderboard: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onPlay = onPlay
        self.onOpenLeaderboard = onOpenLeaderboard
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 18) {
                    header

                    highScoreCard

                    primaryButton

                    VStack(spacing: 12) {
                        secondaryButton(
                            title: "Liderlik",
                            systemImage: "trophy.fill",
                            tint: Color(red: 0.0, green: 0.83, blue: 1.0),
                            action: onOpenLeaderboard
                        )

                        secondaryButton(
                            title: "Ayarlar",
                            systemImage: "gearshape.fill",
                            tint: Color.white.opacity(0.9),
                            action: onOpenSettings
                        )
                    }

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 24)
                .padding(.top, max(12, proxy.safeAreaInsets.top + 8))
                .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 14))
            }
        }
        .onAppear { viewModel.refreshHighScore() }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.14),
                    Color(red: 0.02, green: 0.02, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 140, y: -180)

            Circle()
                .fill(Color(red: 0.0, green: 0.78, blue: 0.33).opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -160, y: 200)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.10),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.screen)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("BLOCK")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
                Text("NOVA")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0))
            }

            Text("Surdur · Yerlestir · Patlat")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var highScoreCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: "crown.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("EN YUKSEK SKOR")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.6))
                Text("\(viewModel.highScore)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .frame(maxWidth: 320)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var primaryButton: some View {
        Button(action: onPlay) {
            Text("OYNA")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(red: 0.0, green: 0.78, blue: 0.33))
                        .shadow(color: Color(red: 0.0, green: 0.78, blue: 0.33).opacity(0.4), radius: 18, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.white.opacity(0.18))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 16)
                                .mask(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(),
        onPlay: {},
        onOpenLeaderboard: {},
        onOpenSettings: {}
    )
}
