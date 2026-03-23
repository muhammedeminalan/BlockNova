import Combine
import Foundation
import StoreKit
import UIKit

final class SettingsViewModel: ObservableObject {
    @Published var isSoundEnabled: Bool {
        didSet {
            HapticManager.impact(.light)
            settingsManager.isSoundEnabled = isSoundEnabled
        }
    }

    @Published var isHapticEnabled: Bool {
        didSet {
            HapticManager.impact(.light)
            settingsManager.isHapticEnabled = isHapticEnabled
        }
    }

    weak var presenter: UIViewController?

    private let settingsManager: SettingsManager

    init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
        self.isSoundEnabled = settingsManager.isSoundEnabled
        self.isHapticEnabled = settingsManager.isHapticEnabled
    }

    var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    func setPresenter(_ presenter: UIViewController) {
        self.presenter = presenter
    }


    func openLeaderboard() {
        HapticManager.impact(.light)
        guard let presenter = presenter else { return }
        GameManager.showLeaderboard(from: presenter)
    }

    func openPrivacyPolicy() {
        HapticManager.impact(.light)
        // TODO: Gizlilik politikasi URL'si netlesince burada ac.
    }

    func rateApp() {
        HapticManager.impact(.light)
        guard let scene = presenter?.view.window?.windowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    func close() {
        HapticManager.impact(.light)
        presenter?.dismiss(animated: true)
    }
}
