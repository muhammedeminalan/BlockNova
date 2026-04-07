import Combine
import Foundation
import UIKit

@MainActor
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

    private let settingsManager: SettingsManager
    private let onClose: () -> Void

    init(
        settingsManager: SettingsManager? = nil,
        onClose: @escaping () -> Void = {}
    ) {
        let resolvedSettingsManager = settingsManager ?? SettingsManager.shared
        self.settingsManager = resolvedSettingsManager
        self.onClose = onClose
        self.isSoundEnabled = resolvedSettingsManager.isSoundEnabled
        self.isHapticEnabled = resolvedSettingsManager.isHapticEnabled
    }

    func close() {
        HapticManager.impact(.light)
        onClose()
    }
}
