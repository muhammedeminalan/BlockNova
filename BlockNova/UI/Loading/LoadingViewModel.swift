import Combine
import Foundation
import GameKit
import SpriteKit
import UIKit

@MainActor
final class LoadingViewModel: ObservableObject {
    @Published private(set) var statusText = "Yukleniyor"
    @Published private(set) var infoText: String?

    private let minimumLoadDuration: TimeInterval = 1.5
    private var hasStarted = false
    private let presenterProvider: () -> UIViewController?
    private let onFinish: () -> Void

    init(
        presenterProvider: @escaping () -> UIViewController?,
        onFinish: @escaping () -> Void
    ) {
        self.presenterProvider = presenterProvider
        self.onFinish = onFinish
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        Task {
            let startDate = Date()
            await authenticateGameCenter()
            await syncHighScore()
            preloadSounds()

            let elapsed = Date().timeIntervalSince(startDate)
            let remaining = max(0, minimumLoadDuration - elapsed)
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            onFinish()
        }
    }

    private func authenticateGameCenter() async {
        statusText = "Game Center baglaniyor"
        infoText = nil

        await withCheckedContinuation { continuation in
            var resumed = false

            GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
                if let viewController,
                   let presenter = self?.presenterProvider(),
                   presenter.presentedViewController == nil {
                    presenter.present(viewController, animated: true)
                }

                if error != nil {
                    self?.infoText = "Game Center su an baglanamiyor, oyun devam ediyor"
                }

                guard !resumed else { return }
                resumed = true
                continuation.resume()
            }
        }
    }

    private func syncHighScore() async {
        statusText = "Skorlar senkronlaniyor"

        await withCheckedContinuation { continuation in
            CloudManager.shared.syncHighScore { bestScore in
                GameManager.shared.updateHighScoreIfNeeded(bestScore)
                continuation.resume()
            }
        }
    }

    private func preloadSounds() {
        statusText = "Sesler hazirlaniyor"
        let soundFiles = ["pop.wav", "long-pop.wav", "achievement.wav", "game-over.wav"]
        soundFiles.forEach { _ = SKAction.playSoundFileNamed($0, waitForCompletion: false) }
    }
}
