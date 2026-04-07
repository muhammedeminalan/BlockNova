import SwiftUI

struct LoadingView: View {
    @StateObject private var viewModel: LoadingViewModel
    @State private var dotCount = 0
    @State private var animationStep = 0

    private let autoStart: Bool

    private let gridColors: [Color] = [
        Color(red: 1.0, green: 0.28, blue: 0.33),
        Color(red: 0.20, green: 0.80, blue: 0.39),
        Color(red: 0.0, green: 0.83, blue: 1.0),
        Color(red: 0.63, green: 0.31, blue: 0.94),
        Color(red: 1.0, green: 0.84, blue: 0.0),
        Color(red: 0.20, green: 0.51, blue: 1.0),
        Color(red: 1.0, green: 0.42, blue: 0.0),
        Color(red: 1.0, green: 0.31, blue: 0.71),
        Color(red: 0.0, green: 0.80, blue: 0.39),
    ]

    init(viewModel: LoadingViewModel, autoStart: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.autoStart = autoStart
    }

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.102)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 40)

                HStack(spacing: 6) {
                    Text("BLOCK")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("NOVA")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(Color(red: 0, green: 0.831, blue: 1))
                }

                loadingBlockGrid
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 8) {
                    Text("\(viewModel.statusText)\(String(repeating: ".", count: dotCount))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))

                    if let infoText = viewModel.infoText {
                        Text(infoText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.52))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                }
                .padding(.bottom, 46)
            }
        }
        .onAppear {
            if autoStart {
                viewModel.startIfNeeded()
            }
            startTextAnimation()
            startGridAnimation()
        }
    }

    private var loadingBlockGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(24), spacing: 8), count: 3)

        return LazyVGrid(columns: columns, spacing: 8) {
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

    private func startTextAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }

    private func startGridAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.16, repeats: true) { _ in
            animationStep = (animationStep + 1) % 9
        }
    }
}

#Preview {
    LoadingView(
        viewModel: LoadingViewModel(
            presenterProvider: { nil },
            onFinish: {}
        ),
        autoStart: false
    )
}
