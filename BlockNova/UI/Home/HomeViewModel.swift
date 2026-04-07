import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var highScore: Int
    private var cancellables = Set<AnyCancellable>()

    init() {
        highScore = CloudManager.shared.loadHighScore()
        NotificationCenter.default.publisher(for: .highScoreUpdated)
            .compactMap { $0.userInfo?["score"] as? Int }
            .receive(on: RunLoop.main)
            .sink { [weak self] score in
                guard let self else { return }
                self.highScore = max(self.highScore, score)
            }
            .store(in: &cancellables)
    }

    func refreshHighScore() {
        highScore = CloudManager.shared.loadHighScore()
    }
}
