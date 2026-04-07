import UIKit

protocol SafeAreaUpdatable: AnyObject {
    func updateSafeAreaInsets(_ insets: UIEdgeInsets)
}
