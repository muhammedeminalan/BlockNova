import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let showsReturnToHomeButton: Bool
    let onReturnToHome: (() -> Void)?

    init(
        viewModel: SettingsViewModel,
        showsReturnToHomeButton: Bool = false,
        onReturnToHome: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.showsReturnToHomeButton = showsReturnToHomeButton
        self.onReturnToHome = onReturnToHome
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    header

                    VStack(spacing: 16) {
                        settingsCard

                        if showsReturnToHomeButton {
                            returnToHomeCard
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 12)
                }
                .padding(.top, max(16, proxy.safeAreaInsets.top + 8))
                .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 12))
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.06, blue: 0.15),
                Color(red: 0.03, green: 0.03, blue: 0.10),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear,
                ],
                center: .top,
                startRadius: 40,
                endRadius: 320
            )
        )
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { viewModel.close() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Geri")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                }

                Spacer()
            }

            Text("Ayarlar")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Oyun deneyimini kişiselleştir")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    private var settingsCard: some View {
        card {
            VStack(spacing: 14) {
                SettingsToggleRow(
                    title: "Ses Efektleri",
                    isOn: $viewModel.isSoundEnabled
                )

                Divider().background(Color.white.opacity(0.08))

                SettingsToggleRow(
                    title: "Titreşim",
                    isOn: $viewModel.isHapticEnabled
                )
            }
        }
    }

    private var returnToHomeCard: some View {
        card {
            Button(action: handleReturnToHome) {
                HStack(spacing: 10) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16, weight: .bold))

                    Text("Ana Menüye Dön")
                        .font(.system(size: 16, weight: .bold))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content)
        -> some View
    {
        content()
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }

    private func handleReturnToHome() {
        HapticManager.impact(.medium)
        onReturnToHome?()
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let isOn: Binding<Bool>

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(PremiumToggleStyle())
        }
    }
}

private struct PremiumToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                Capsule()
                    .fill(
                        configuration.isOn
                            ? Color(red: 0.0, green: 0.82, blue: 0.35)
                            : Color.white.opacity(0.2)
                    )
                    .frame(width: 52, height: 30)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    .offset(x: configuration.isOn ? 11 : -11)
                    .animation(
                        .easeOut(duration: 0.18),
                        value: configuration.isOn
                    )
            }
            .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
