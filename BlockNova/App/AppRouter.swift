import Combine
import Foundation
import UIKit

@MainActor
final class AppRouter: ObservableObject {
    enum Screen {
        case loading
        case home
        case game
    }

    @Published var screen: Screen = .loading
    @Published var isSettingsPresented = false
    @Published var gameSessionID = UUID()

    weak var presenter: UIViewController?

    func showHome() {
        isSettingsPresented = false
        screen = .home
    }

    func showGame() {
        isSettingsPresented = false
        gameSessionID = UUID()
        screen = .game
    }

    func openSettings() {
        isSettingsPresented = true
    }

    func closeSettings() {
        isSettingsPresented = false
    }
}
