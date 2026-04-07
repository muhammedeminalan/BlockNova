import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var highScore: Int

    init() {
        highScore = CloudManager.shared.loadHighScore()
    }

    func refreshHighScore() {
        highScore = CloudManager.shared.loadHighScore()
    }
}
