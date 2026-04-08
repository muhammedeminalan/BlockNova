import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            content
            GameCenterPresenterResolver { presenter in
                router.presenter = presenter
            }
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
        }
        .fullScreenCover(isPresented: $router.isSettingsPresented) {
            SettingsView(
                viewModel: SettingsViewModel(
                    onClose: { router.closeSettings() }
                )
            )
            .interactiveDismissDisabled()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch router.screen {
        case .loading:
            LoadingView(
                viewModel: LoadingViewModel(
                    presenterProvider: { [weak router] in router?.presenter },
                    onFinish: { [weak router] in
                        Task { @MainActor in
                            router?.showHome()
                        }
                    }
                )
            )
        case .home:
            HomeView(
                viewModel: HomeViewModel(),
                onPlay: {
                    HapticManager.impact(.medium)
                    router.showGame()
                },
                onOpenLeaderboard: {
                    HapticManager.impact(.light)
                    guard let presenter = router.presenter else { return }
                    GameManager.showLeaderboard(from: presenter)
                },
                onOpenSettings: {
                    HapticManager.impact(.light)
                    router.openSettings()
                }
            )
        case .game:
            GameContainerView(
                onReturnToHome: {
                    router.showHome()
                },
                onOpenSettings: {
                    HapticManager.impact(.light)
                    router.openSettings()
                }
            )
            .id(router.gameSessionID)
        }
    }
}
