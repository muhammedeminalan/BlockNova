import Combine
import SpriteKit
import SwiftUI
import UIKit

struct GameContainerView: View {
    let onReturnToHome: () -> Void
    let onOpenSettings: () -> Void

    @StateObject private var bridge = GameContainerBridge()
    @State private var gameOverPresentation: GameOverPresentation?
    @State private var activeComboEffects: [ComboEffectPresentation] = []
    @State private var recentVariantsByLevel: [ComboEffectPresentation.Level: [Int]] = [:]
    @State private var score: Int = 0
    @State private var highScore: Int = 0

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
                },
                onComboEffectTriggered: { presentation in
                    enqueueComboEffect(presentation)
                },
                onScoreChanged: { currentScore, currentHighScore in
                    score = currentScore
                    highScore = currentHighScore
                }
            )
            .ignoresSafeArea()

            InGameHUDView(
                score: score,
                highScore: highScore,
                onSettingsTap: onOpenSettings
            )
            .zIndex(0.9)

            ForEach(activeComboEffects) { combo in
                ComboEffectOverlayView(
                    presentation: combo,
                    onFinished: {
                        removeComboEffect(withID: combo.id)
                    }
                )
                .zIndex(1)
                .allowsHitTesting(false)
            }

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

    private func enqueueComboEffect(_ presentation: ComboEffectPresentation) {
        let variant = nextVariant(for: presentation.level)
        let enriched = ComboEffectPresentation(
            level: presentation.level,
            points: presentation.points,
            styleVariant: variant,
            streak: presentation.streak,
            customTitle: presentation.customTitle
        )

        // Neden: Ekranda sadece son event kalsin, buyuk overlay birikmesin.
        activeComboEffects = [enriched]
    }

    private func removeComboEffect(withID id: UUID) {
        activeComboEffects.removeAll { $0.id == id }
    }

    private func nextVariant(for level: ComboEffectPresentation.Level) -> Int {
        let totalVariantCount = 6
        let history = recentVariantsByLevel[level] ?? []
        let lastTwo = Set(history.suffix(2))

        let candidates = (0..<totalVariantCount).filter { !lastTwo.contains($0) }
        let selected = (candidates.isEmpty ? Array(0..<totalVariantCount) : candidates).randomElement() ?? 0

        var updated = history
        updated.append(selected)
        if updated.count > 4 {
            updated.removeFirst(updated.count - 4)
        }
        recentVariantsByLevel[level] = updated

        return selected
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
    let onComboEffectTriggered: (ComboEffectPresentation) -> Void
    let onScoreChanged: (Int, Int) -> Void

    func makeUIViewController(context: Context) -> GameContainerViewController {
        let controller = GameContainerViewController()
        controller.bridge = bridge
        controller.onReturnToHome = onReturnToHome
        controller.onGameOverChanged = onGameOverChanged
        controller.onComboEffectTriggered = onComboEffectTriggered
        controller.onScoreChanged = onScoreChanged
        return controller
    }

    func updateUIViewController(_ uiViewController: GameContainerViewController, context: Context) {
        uiViewController.bridge = bridge
        uiViewController.onReturnToHome = onReturnToHome
        uiViewController.onGameOverChanged = onGameOverChanged
        uiViewController.onComboEffectTriggered = onComboEffectTriggered
        uiViewController.onScoreChanged = onScoreChanged
    }
}

final class GameContainerViewController: UIViewController {
    var onReturnToHome: (() -> Void)?
    var onGameOverChanged: ((GameOverPresentation?) -> Void)?
    var onComboEffectTriggered: ((ComboEffectPresentation) -> Void)?
    var onScoreChanged: ((Int, Int) -> Void)?
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
        scene.onComboEffectTriggered = { [weak self] comboEffect in
            self?.onComboEffectTriggered?(comboEffect)
        }
        scene.onScoreChanged = { [weak self] score, highScore in
            DispatchQueue.main.async {
                self?.onScoreChanged?(score, highScore)
            }
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
