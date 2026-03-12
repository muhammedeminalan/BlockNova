// 📁 App/GameViewController.swift
// SKView'i barindiran UIViewController.
// Storyboard'daki mevcut SKView kullanilir — yeni SKView OLUSTURULMAZ.
// Iki SKView ust uste gelirse gesture tanimayicilari cakisir ve
// sistemin dokunus tanima zaman asimi hatasi olusur.

import UIKit
import SpriteKit

// MARK: - SafeAreaUpdatable
/// Scene tarafinda safe area bilgisini almak icin minimal protokol
protocol SafeAreaUpdatable: AnyObject {
    /// Safe area inset'lerini scene'e aktarir ve layout'un guncellenmesini saglar
    func updateSafeAreaInsets(_ insets: UIEdgeInsets)
}

final class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Storyboard view'i zaten SKView olarak ayarli (Main.storyboard'da customClass="SKView")
        // Yeni SKView olusturma — dokunus performansi ve stabilite icin kritik
        guard let skView = view as? SKView else { return }

        // Ilk sahne: HomeScene
        let scene = HomeScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill

        // SpriteKit performans ayarlari
        skView.ignoresSiblingOrder = true
        skView.showsFPS       = false  // Uretimde kapali
        skView.showsNodeCount = false
        // Gorunmeyen node'lari render etme — hafif performans iyilestirmesi
        skView.shouldCullNonVisibleNodes = true
        skView.presentScene(scene)

        // Ilk layout icin safe area ve scene boyutu bilgisini gonder
        updateSceneLayout()
    }

    /// View boyutu degisirse scene size ve layout guncellensin
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Boyut degisimi safe area degisikliginden bagimsiz olabilir
        updateSceneLayout()
    }

    /// Safe area degistiginde scene'e ilet — notch ve home indicator icin kritik
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateSceneLayout()
    }

    /// Sadece dikey mod — oyun dikey tasarlandi
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    /// Status bar gizli — tam ekran oyun icin
    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// Home indicator gizli (iPhone X ve sonrasi)
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - Layout Senkronizasyonu

    /// SKView'in size + safe area bilgisini aktif scene'e aktarir
    private func updateSceneLayout() {
        guard let skView = view as? SKView else { return }

        // Scene boyutu SKView bounds ile senkron olmali — responsive hesaplar icin
        let newSize = skView.bounds.size
        if let scene = skView.scene, scene.size != newSize {
            scene.size = newSize
        }

        // Constants icindeki responsive hesaplar scene size'a gore guncellenir
        C.updateSceneSize(newSize)

        // Safe area inset'lerini scene'e gonder — panelleri guvenli alana tasir
        if let safeScene = skView.scene as? SafeAreaUpdatable {
            safeScene.updateSafeAreaInsets(skView.safeAreaInsets)
        }
    }
}
