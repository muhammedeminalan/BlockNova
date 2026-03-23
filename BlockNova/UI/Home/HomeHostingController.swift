import SpriteKit
import SwiftUI
import UIKit

final class HomeHostingController: UIHostingController<HomeView> {
    private let viewModel: HomeViewModel

    init(skView: SKView) {
        let viewModel = HomeViewModel()
        self.viewModel = viewModel
        super.init(rootView: HomeView(viewModel: viewModel))
        self.viewModel.setPresenter(self)
        self.viewModel.setSKView(skView)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        return nil
    }
}
