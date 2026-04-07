import GameKit
import SwiftUI
import UIKit

struct GameCenterPresenterResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> GameCenterPresenterViewController {
        let controller = GameCenterPresenterViewController()
        controller.onResolve = onResolve
        return controller
    }

    func updateUIViewController(_ uiViewController: GameCenterPresenterViewController, context: Context) {
        uiViewController.onResolve = onResolve
    }
}

final class GameCenterPresenterViewController: UIViewController, GKGameCenterControllerDelegate {
    var onResolve: ((UIViewController) -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onResolve?(self)
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
