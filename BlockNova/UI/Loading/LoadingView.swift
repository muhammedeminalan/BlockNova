import SwiftUI

struct LoadingView: View {
    @StateObject private var viewModel: LoadingViewModel
    @State private var dotCount = 0
    @State private var animationStep = 0
    @State private var dotAnimationTask: Task<Void, Never>?
    @State private var gridAnimationTask: Task<Void, Never>?

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

                LoadingBlockGridView(
                    animationStep: animationStep,
                    gridColors: gridColors
                )
                    .padding(.top, 8)

                Spacer()

                LoadingStatusSectionView(
                    statusText: viewModel.statusText,
                    dotCount: dotCount,
                    infoText: viewModel.infoText
                )
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
        .onDisappear {
            stopAnimations()
        }
    }

    private func startTextAnimation() {
        guard dotAnimationTask == nil else { return }
        dotAnimationTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                dotCount = (dotCount + 1) % 4
            }
        }
    }

    private func startGridAnimation() {
        guard gridAnimationTask == nil else { return }
        gridAnimationTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 160_000_000)
                animationStep = (animationStep + 1) % 9
            }
        }
    }

    private func stopAnimations() {
        dotAnimationTask?.cancel()
        dotAnimationTask = nil
        gridAnimationTask?.cancel()
        gridAnimationTask = nil
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
