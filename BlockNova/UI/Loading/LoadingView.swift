import SwiftUI

struct LoadingView: View {
    @StateObject private var viewModel: LoadingViewModel
    @State private var dotCount = 0

    private let autoStart: Bool

    init(viewModel: LoadingViewModel, autoStart: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.autoStart = autoStart
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

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.102)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 6) {
                    Text("BLOCK")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("NOVA")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(Color(red: 0, green: 0.831, blue: 1))
                }

                Text("\(viewModel.statusText)\(String(repeating: ".", count: dotCount))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                if let infoText = viewModel.infoText {
                    Text(infoText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
        }
        .onAppear {
            if autoStart {
                viewModel.startIfNeeded()
            }
            startDotAnimation()
        }
    }

    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}
