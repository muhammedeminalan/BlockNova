import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    let onPlay: () -> Void
    let onOpenLeaderboard: () -> Void
    let onOpenSettings: () -> Void

    @State private var reveal = false
    @State private var pulse = false

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

                VStack(spacing: 18) {
                    Spacer(minLength: max(12, proxy.safeAreaInsets.top + 6))

                    header

                    highScoreCard

                    primaryButton

                    secondaryButtons

                    Spacer(minLength: max(18, proxy.safeAreaInsets.bottom + 10))
                }
                .padding(.horizontal, 22)
                .scaleEffect(reveal ? 1.0 : 0.94)
                .opacity(reveal ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.83),
                    value: reveal
                )
            }
        }
        .onAppear {
            viewModel.refreshHighScore()
            startEntranceIfNeeded()
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.14),
                    Color(red: 0.02, green: 0.03, blue: 0.10),
                    Color(red: 0.01, green: 0.02, blue: 0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 150, y: -240)

            Circle()
                .fill(Color(red: 0.0, green: 0.82, blue: 0.35).opacity(0.17))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -150, y: 250)

            AngularGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.white.opacity(0.04),
                    Color.clear,
                ]),
                center: .center
            )
            .blur(radius: 40)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("BLOCK")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("NOVA")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.94, blue: 1.0),
                                Color(red: 0.0, green: 0.78, blue: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("Surdur · Yerlestir · Patlat")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
        }
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
    }

    private var highScoreCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.35),
                                Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0))
            }

            Text("EN YUKSEK SKOR")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))

            Text("\(viewModel.highScore)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.94, blue: 0.65),
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                            Color(red: 0.0, green: 0.88, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.30), radius: 16, x: 0, y: 8)
                .scaleEffect(pulse ? 1.03 : 0.97)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(
                        autoreverses: true
                    ),
                    value: pulse
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var primaryButton: some View {
        Button(action: onPlay) {
            Text("OYNA")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.88, blue: 0.42),
                                    Color(red: 0.0, green: 0.74, blue: 0.33),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: Color(red: 0.0, green: 0.82, blue: 0.35)
                                .opacity(0.45),
                            radius: 20,
                            x: 0,
                            y: 12
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var secondaryButtons: some View {
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
                tint: .white,
                action: onOpenSettings
            )
        }
    }

    private func secondaryButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func startEntranceIfNeeded() {
        guard !reveal else { return }
        reveal = true
        pulse = true
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
