import Combine
import Foundation
import SpriteKit
import UIKit

final class HomeViewModel: ObservableObject {
    @Published private(set) var highScore: Int

    weak var presenter: UIViewController?
    weak var skView: SKView?

    init() {
        highScore = CloudManager.shared.loadHighScore()
    }

    func setPresenter(_ presenter: UIViewController) {
        self.presenter = presenter
    }

    func setSKView(_ skView: SKView) {
        self.skView = skView
    }

    func refreshHighScore() {
        highScore = CloudManager.shared.loadHighScore()
    }

    func play() {
        HapticManager.impact(.medium)
        guard let skView = skView else { return }

        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = skView.scene?.scaleMode ?? .aspectFill
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
        presenter?.dismiss(animated: false)
    }

    func openLeaderboard() {
        HapticManager.impact(.light)
        guard let presenter = presenter else { return }
        GameManager.showLeaderboard(from: presenter)
    }

    func openSettings() {
        HapticManager.impact(.light)
        guard let presenter = presenter else { return }
        guard presenter.presentedViewController == nil else { return }
        let settings = SettingsHostingController()
        presenter.present(settings, animated: true)
    }
}
