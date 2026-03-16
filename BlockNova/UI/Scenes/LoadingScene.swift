// 📁 Scenes/LoadingScene.swift
// LaunchScreen'den hemen sonra gösterilen yükleme sahnesi.
// Game Center auth ve ses preload burada yapılır.
// Minimum 1.5 saniye gösterilir, sonra HomeScene'e geçer.

import SpriteKit
import GameKit

// MARK: - LoadingScene

final class LoadingScene: SKScene {

    // MARK: - Node'lar

    private var loadingLabel: SKLabelNode!

    // MARK: - Durum

    // En az bu kadar süre göster — çok hızlı geçiş kullanıcıya kaba gelir
    private let minimumLoadTime: TimeInterval = 1.5
    // Minimum süre doldu mu? — her iki koşul da sağlanınca geçiş yapılır
    private var minimumTimePassed = false

    // MARK: - Kurulum

    override func didMove(to view: SKView) {
        // Arka plan: #0a0a1a — LaunchScreen ve HomeScene ile birebir aynı, geçiş dikkat çekmez
        backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.102, alpha: 1)
        // C.updateSceneSize: responsive hesaplar sahne boyutuna göre calissın
        C.updateSceneSize(size)

        setupLogo()
        setupBlockAnimation()
        setupLoadingLabel()
        startPreloading()
    }

    // MARK: - Logo

    private func setupLogo() {
        // size kullanılır — didMove sırasında frame sıfır gelebilir, size her zaman doğru
        let w = size.width
        let h = size.height
        // fontBoyutu: yükseklik ve genişliğin küçüğüne oranlanır
        // Bu iPhone SE (küçük) ile Pro Max (büyük) arasında taşma yaşatmaz
        let fontBoyutu = min(w, h) * 0.12

        // BLOCK: .right hizalı — sağ kenarı pivot, merkeze yaslar
        let blockLabel = SKLabelNode(text: "BLOCK")
        blockLabel.fontName  = "AvenirNext-Heavy"
        blockLabel.fontSize  = fontBoyutu
        blockLabel.fontColor = .white
        blockLabel.horizontalAlignmentMode = .right
        blockLabel.verticalAlignmentMode   = .baseline

        // NOVA: .left hizalı — sol kenarı pivot, merkeze yaslar
        let novaLabel = SKLabelNode(text: "NOVA")
        novaLabel.fontName  = "AvenirNext-Heavy"
        novaLabel.fontSize  = fontBoyutu
        novaLabel.fontColor = UIColor(red: 0, green: 0.831, blue: 1, alpha: 1)
        novaLabel.horizontalAlignmentMode = .left
        novaLabel.verticalAlignmentMode   = .baseline

        // İki kelime arasındaki boşluğun yarısı — ortada buluşur
        let yarimBosluk: CGFloat = w * 0.018
        let logoY = h * 0.62  // Ekranın üst %38'inde — grid ve yükleme yazısına alan bırakır

        blockLabel.position = CGPoint(x: w / 2 - yarimBosluk, y: logoY)
        novaLabel.position  = CGPoint(x: w / 2 + yarimBosluk, y: logoY)

        // Staggered fade-in: önce BLOCK, 0.15sn sonra NOVA — canlılık katar
        blockLabel.alpha = 0
        novaLabel.alpha  = 0
        addChild(blockLabel)
        addChild(novaLabel)

        blockLabel.run(SKAction.fadeIn(withDuration: 0.4))
        novaLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.fadeIn(withDuration: 0.4)
        ]))
    }

    // MARK: - Blok Grid Animasyonu

    // 3x3 mini grid — hücreler sırayla farklı renklere dönüşüp geri döner
    // colorize aksiyonu texture'siz node'da çalışmaz;
    // SKAction.run ile .color dogrudan atanır
    private func setupBlockAnimation() {
        let gridNode = SKNode()
        // size kullanılır — frame.midX/midY didMove'da sıfır gelebilir
        gridNode.position = CGPoint(x: size.width / 2, y: size.height * 0.46)
        addChild(gridNode)

        // cellSize: genişliğe orantılı — her cihazda grid aynı görsel orana sahip
        let cellSize: CGFloat  = size.width * 0.055
        let padding:  CGFloat  = cellSize * 0.15  // sabit px değil, hücreyle orantılı boşluk
        let gridDim            = 3

        // Her hücre için farklı renk — görsel çeşitlilik
        let colors: [UIColor] = [
            UIColor(red: 1,    green: 0.28, blue: 0.33, alpha: 1), // kırmızı
            UIColor(red: 0.20, green: 0.80, blue: 0.39, alpha: 1), // yeşil
            UIColor(red: 0,    green: 0.83, blue: 1,    alpha: 1), // cyan
            UIColor(red: 0.63, green: 0.31, blue: 0.94, alpha: 1), // mor
            UIColor(red: 1,    green: 0.84, blue: 0,    alpha: 1), // sarı
            UIColor(red: 0.20, green: 0.51, blue: 1,    alpha: 1), // mavi
            UIColor(red: 1,    green: 0.42, blue: 0,    alpha: 1), // turuncu
            UIColor(red: 1,    green: 0.31, blue: 0.71, alpha: 1), // pembe
            UIColor(red: 0,    green: 0.80, blue: 0.39, alpha: 1), // yeşil 2
        ]

        let emptyColor = UIColor(white: 0.15, alpha: 1)
        let totalSize  = CGFloat(gridDim) * (cellSize + padding) - padding
        var index      = 0

        for row in 0..<gridDim {
            for col in 0..<gridDim {
                let cell = SKSpriteNode(color: emptyColor.sk,
                                       size: CGSize(width: cellSize, height: cellSize))
                let x = CGFloat(col) * (cellSize + padding) - totalSize / 2 + cellSize / 2
                let y = CGFloat(gridDim - 1 - row) * (cellSize + padding) - totalSize / 2 + cellSize / 2
                cell.position = CGPoint(x: x, y: y)
                gridNode.addChild(cell)

                let targetColor = colors[index % colors.count]
                // Her hücre kendi gecikmesiyle başlar — dalga efekti oluşturur
                let delay    = Double(index) * 0.12
                // Tüm hücreler dolduktan sonra kısa bekleme, sonra boşalma
                let waitFull = Double(gridDim * gridDim) * 0.12 + 0.3

                // texture yok, colorize çalışmaz — run bloğu içinde .color doğrudan set edilir
                let fillSeq = SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.run  { cell.color = targetColor.sk },
                    SKAction.scale(to: 1.1, duration: 0.08),
                    SKAction.scale(to: 1.0, duration: 0.05),
                    SKAction.wait(forDuration: waitFull),
                    SKAction.run  { cell.color = emptyColor.sk },
                    SKAction.wait(forDuration: 0.2)
                ])

                // repeatForever: yükleme bitene kadar döngüde kalır
                cell.run(SKAction.repeatForever(fillSeq))
                index += 1
            }
        }
    }

    // MARK: - Yükleniyor Yazısı

    private func setupLoadingLabel() {
        loadingLabel = SKLabelNode(text: "Yükleniyor")
        loadingLabel.fontName  = "AvenirNext-Medium"
        // size kullanılır — frame.height didMove'da 0 olabilir
        loadingLabel.fontSize  = size.height * 0.018
        loadingLabel.fontColor = UIColor(white: 1, alpha: 0.4).sk
        // Ekranın alt %32'sinde — grid animasyonu ile yükleniyor yazısı arasında nefes alanı var
        loadingLabel.position  = CGPoint(x: size.width / 2, y: size.height * 0.32)
        loadingLabel.horizontalAlignmentMode = .center
        loadingLabel.verticalAlignmentMode   = .center
        addChild(loadingLabel)

        // Nokta animasyonu: 0 → 1 → 2 → 3 nokta — kullanıcıya bir şeyler olduğunu hissettirir
        var dotCount = 0
        loadingLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                dotCount = (dotCount + 1) % 4
                self?.loadingLabel.text = "Yükleniyor" + String(repeating: ".", count: dotCount)
            }
        ])))
    }

    // MARK: - Preload

    private func startPreloading() {
        // Game Center authentication — LoadingScene içinde yapılır,
        // GameViewController'daki çağrı kaldırılmadı: ikisi güvenle bir arada çalışır
        authenticateGameCenter()

        // Sesleri belleğe al — SoundManager zaten init'te yapıyor,
        // ek olarak SKAction oluşturarak iOS ses önbelleğini ısıtır
        preloadSounds()

        // Minimum gösterim süresi: 1.5sn dolunca geçiş bayrağını kaldır ve geç
        run(SKAction.sequence([
            SKAction.wait(forDuration: minimumLoadTime),
            SKAction.run { [weak self] in
                self?.minimumTimePassed = true
                self?.transitionToHome()
            }
        ]))
    }

    // MARK: - Game Center Auth

    private func authenticateGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, _ in
            if let vc = vc {
                // Apple'ın kendi giriş ekranını göster — LoadingScene üzerinde açılır
                self?.view?.window?.rootViewController?.present(vc, animated: true)
            }
            // Başarılı, reddedilmiş ya da hata — LoadingScene devam eder, crash yok
        }
    }

    // MARK: - Ses Preload

    private func preloadSounds() {
        // SKAction nesneleri oluşturulunca iOS ses motoru dosyayı belleğe alır.
        // İlk çalmada gecikme olmaz — özellikle düşük RAM'li cihazlarda fark edilir.
        let soundFiles = ["pop.wav", "long-pop.wav", "achievement.wav", "game-over.wav"]
        soundFiles.forEach { _ = SKAction.playSoundFileNamed($0, waitForCompletion: false) }
    }

    // MARK: - HomeScene'e Geçiş

    private func transitionToHome() {
        guard minimumTimePassed else { return }

        // Fade geçiş: ani kesim yerine yumuşak — gözü yormaz
        let transition = SKTransition.fade(withDuration: 0.5)
        let homeScene  = HomeScene(size: size)
        homeScene.scaleMode = scaleMode
        view?.presentScene(homeScene, transition: transition)
    }
}
