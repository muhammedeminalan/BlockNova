import SwiftUI
import UIKit

final class SettingsHostingController: UIHostingController<SettingsView> {
    private let viewModel: SettingsViewModel

    init() {
        let viewModel = SettingsViewModel()
        self.viewModel = viewModel
        super.init(rootView: SettingsView(viewModel: viewModel))
        self.viewModel.setPresenter(self)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
        isModalInPresentation = true
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        return nil
    }
}
