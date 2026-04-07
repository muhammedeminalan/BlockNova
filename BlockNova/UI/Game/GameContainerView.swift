import Combine
import SpriteKit
import SwiftUI
import UIKit

struct GameContainerView: View {
    let onReturnToHome: () -> Void

    @StateObject private var bridge = GameContainerBridge()
    @State private var gameOverPresentation: GameOverPresentation?

    var body: some View {
        ZStack {
            GameSceneHostController(
                bridge: bridge,
                onReturnToHome: onReturnToHome,
                onGameOverChanged: { presentation in
                    // Oyun sonu katmaninda scene pause kalmamali.
                    if presentation != nil {
                        bridge.setPaused(false)
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        gameOverPresentation = presentation
                    }
                }
            )
            .ignoresSafeArea()

            if let presentation = gameOverPresentation {
                GameOverOverlayView(
                    presentation: presentation,
                    onReplay: {
                        HapticManager.impact(.medium)
                        bridge.setPaused(false)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            gameOverPresentation = nil
                        }
                        bridge.restartGame()
                    },
                    onHome: {
                        HapticManager.impact(.light)
                        bridge.setPaused(false)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            gameOverPresentation = nil
                        }
                        bridge.goHome()
                    }
                )
                .zIndex(2)
            }
        }
    }
}

@MainActor
final class GameContainerBridge: ObservableObject {
    var restartAction: () -> Void = {}
    var homeAction: () -> Void = {}
    var setPausedAction: (Bool) -> Void = { _ in }

    func restartGame() {
        restartAction()
    }

    func goHome() {
        homeAction()
    }

    func setPaused(_ paused: Bool) {
        setPausedAction(paused)
    }
}

private struct GameSceneHostController: UIViewControllerRepresentable {
    @ObservedObject var bridge: GameContainerBridge
    let onReturnToHome: () -> Void
    let onGameOverChanged: (GameOverPresentation?) -> Void

    func makeUIViewController(context: Context) -> GameContainerViewController {
        let controller = GameContainerViewController()
        controller.bridge = bridge
        controller.onReturnToHome = onReturnToHome
        controller.onGameOverChanged = onGameOverChanged
        return controller
    }

    func updateUIViewController(_ uiViewController: GameContainerViewController, context: Context) {
        uiViewController.bridge = bridge
        uiViewController.onReturnToHome = onReturnToHome
        uiViewController.onGameOverChanged = onGameOverChanged
    }
}

final class GameContainerViewController: UIViewController {
    var onReturnToHome: (() -> Void)?
    var onGameOverChanged: ((GameOverPresentation?) -> Void)?
    weak var bridge: GameContainerBridge?

    private weak var gameScene: GameScene?

    override func loadView() {
        view = SKView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        scene.onReturnToHome = { [weak self] in
            self?.onGameOverChanged?(nil)
            self?.onReturnToHome?()
        }
        scene.onGameOverChanged = { [weak self] presentation in
            self?.onGameOverChanged?(presentation)
        }

        gameScene = scene
        wireBridgeActions()

        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.shouldCullNonVisibleNodes = true
        skView.presentScene(scene)
        skView.gestureRecognizers?.forEach { skView.removeGestureRecognizer($0) }

        updateSceneLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSceneLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateSceneLayout()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    private func wireBridgeActions() {
        bridge?.restartAction = { [weak self] in
            self?.gameScene?.restartGame()
            self?.onGameOverChanged?(nil)
        }

        bridge?.homeAction = { [weak self] in
            self?.gameScene?.goToHome()
        }

        bridge?.setPausedAction = { [weak self] paused in
            guard let skView = self?.view as? SKView else { return }
            skView.isPaused = paused
        }
    }

    private func updateSceneLayout() {
        guard let skView = view as? SKView else { return }

        let newSize = skView.bounds.size
        if let scene = skView.scene, scene.size != newSize {
            scene.size = newSize
        }

        C.updateSceneSize(newSize)

        if let safeAreaScene = skView.scene as? SafeAreaUpdatable {
            safeAreaScene.updateSafeAreaInsets(skView.safeAreaInsets)
        }
    }
}
