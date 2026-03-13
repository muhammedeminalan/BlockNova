// 📁 Scenes/HomeScene.swift
// Uygulama acilisinda gosterilen ana menu sahnesi.
// Logo, dekoratif animasyonlu bloklar, "OYNA" butonu ve rekor skoru icerir.
// Tum boyutlar scene size + safe area bilgisine gore hesaplanir — responsive tasarim.

import SpriteKit
import UIKit

// MARK: - HomeScene
final class HomeScene: SKScene, SafeAreaUpdatable {

    // MARK: - Safe Area Durumu

    /// Scene icin guncel safe area inset'leri — layout hesaplarinin temel girdisi
    private var safeAreaInsets: UIEdgeInsets = .zero
    /// Scene icinde kullanilabilir alan — panellerin ve UI'nin guvenli kalmasi icin
    private var safeAreaFrame: CGRect = .zero

    // MARK: - Arka Plan Node'lari

    /// Alt kisimdaki glow katmani — derinlik hissi icin tutulur
    private var glowNode: SKSpriteNode?

    // MARK: - Dekoratif Bloklar

    /// Dekoratif bloklar icin layout oranlarini saklar — safe area degisince yeniden konumlanir
    private var decorativeBlocks: [(node: SKSpriteNode, xRatio: CGFloat, yRatio: CGFloat)] = []

    // MARK: - Logo ve UI

    /// Ana baslik etiketi — layout degisiminde yeniden konumlanir
    private var titleLabel: SKLabelNode?
    /// Alt baslik etiketi — layout degisiminde yeniden konumlanir
    private var subtitleLabel: SKLabelNode?
    /// Oyna butonu node'u — layout degisiminde boyut/konum guncellenir
    private var playButtonNode: SKShapeNode?
    /// Oyna butonu yazisi — layout degisiminde font/konum guncellenir
    private var playButtonLabel: SKLabelNode?
    /// Rekor etiketi — layout degisiminde yeniden konumlanir
    private var highScoreLabel: SKLabelNode?
    /// Liderlik tablosu butonu — layout degisiminde boyut/konum guncellenir
    private var leaderboardButtonNode: SKShapeNode?
    /// Liderlik butonu yazisi — layout degisiminde font/konum guncellenir
    private var leaderboardButtonLabel: SKLabelNode?

    // MARK: - Kurulum Bayragi

    /// Sahneyi bir kere kurmak icin kullanilir — tekrar eden node olusumunu onler
    private var isSceneSetup: Bool = false

    // MARK: - Sahne Kurulumu

    override func didMove(to view: SKView) {
        // Arka plan koyu renk — bloklar ve metinler one ciksin
        backgroundColor = C.bgColor.sk

        // Scene size bilgisi merkezi hesaplar icin guncellenir
        C.updateSceneSize(size)

        // Safe area bilgisini view'dan al — ilk layout icin baz deger olur
        safeAreaInsets = view.safeAreaInsets

        // Sahne kurulumunu sadece bir kez yap
        if !isSceneSetup {
            setupBackground()
            setupDecorativeBlocks()
            setupLogo()
            setupPlayButton()
            setupLeaderboardButton()  // Liderlik butonu OYNA butonunun hemen altına eklenir
            setupHighScoreLabel()
            isSceneSetup = true
        }

        // Safe area bilgisine gore tum node konumlarini guncelle
        layoutScene()
    }

    // MARK: - Safe Area Guncelleme

    /// GameViewController'dan gelen safe area inset'lerini alir ve layout'u yeniler
    func updateSafeAreaInsets(_ insets: UIEdgeInsets) {
        // Insets saklanir — layout hesaplarinin temel girdisi
        safeAreaInsets = insets
        // Insets degisince layout yeniden hesaplanir
        layoutScene()
    }

    // MARK: - Layout

    /// Tum node'lari safe area'ya gore yeniden konumlandirir
    private func layoutScene() {
        // Scene size degisimi olursa merkez hesaplar guncellensin
        C.updateSceneSize(size)

        // Safe area frame hesapla — ust/alt/yan guvenli alanlari dikkate al
        let safeWidth  = max(0, size.width  - safeAreaInsets.left - safeAreaInsets.right)
        let safeHeight = max(0, size.height - safeAreaInsets.top  - safeAreaInsets.bottom)
        safeAreaFrame = CGRect(
            x: safeAreaInsets.left,
            y: safeAreaInsets.bottom,
            width: safeWidth,
            height: safeHeight
        )

        // Arka plan glow boyutu ve konumu safe area'ya gore guncellenir
        if let glowNode {
            glowNode.size = CGSize(width: size.width * 1.5, height: size.height * 0.5)
            glowNode.position = CGPoint(
                x: size.width / 2,
                y: safeAreaFrame.minY + safeAreaFrame.height * 0.15
            )
        }

        // Dekoratif bloklar safe area icinde kalacak sekilde yeniden konumlanir
        layoutDecorativeBlocks()

        // Logo konumu safe area merkezine gore ayarlanir
        if let titleLabel {
            titleLabel.fontSize = C.screenH * 0.055
            titleLabel.position = CGPoint(
                x: safeAreaFrame.midX,
                y: safeAreaFrame.minY + safeAreaFrame.height * 0.74
            )
        }
        if let subtitleLabel {
            subtitleLabel.fontSize = C.screenH * 0.020
            subtitleLabel.position = CGPoint(
                x: safeAreaFrame.midX,
                y: safeAreaFrame.minY + safeAreaFrame.height * 0.74 - C.screenH * 0.055
            )
        }

        // Oyna butonunun boyutu ve konumu safe area'ya gore ayarlanir
        layoutPlayButton()

        // Liderlik butonu OYNA butonunun altında konumlanir
        layoutLeaderboardButton()

        // Rekor etiketi liderlik butonunun altinda sabitlenir
        if let highScoreLabel {
            highScoreLabel.fontSize = C.screenH * 0.020
            let btnY = safeAreaFrame.minY + safeAreaFrame.height * 0.38
            let btnH = C.screenH * 0.072
            // Liderlik butonu da alta eklendi — rekor etiketi daha asagiya iner
            let margin = C.screenH * 0.028 + btnH + C.screenH * 0.018
            highScoreLabel.position = CGPoint(
                x: safeAreaFrame.midX,
                y: btnY - btnH - margin
            )
        }
    }

    /// Dekoratif bloklarin pozisyonlarini safe area'ya gore ayarlar
    private func layoutDecorativeBlocks() {
        // Dekoratif blok yoksa gereksiz is yapma
        guard !decorativeBlocks.isEmpty else { return }

        // Blok boyutu scene genisligine gore responsive kalir
        let blockSize = C.cellSize * 0.9

        // Her blok kendi oranina gore yeni konuma tasinir
        for item in decorativeBlocks {
            item.node.size = CGSize(width: blockSize, height: blockSize)
            let x = safeAreaFrame.minX + item.xRatio * safeAreaFrame.width
            let y = safeAreaFrame.minY + item.yRatio * safeAreaFrame.height
            item.node.position = CGPoint(x: x, y: y)
        }
    }

    /// Liderlik butonunun boyut ve pozisyonunu gunceller — OYNA butonunun hemen altina konumlanir
    private func layoutLeaderboardButton() {
        guard let leaderboardButtonNode else { return }

        // Buton boyutlari OYNA butonu ile eslesir — tutarli UI
        let btnW = C.screenW * 0.52
        let btnH = C.screenH * 0.072
        // OYNA buton Y degeri — liderlik butonu bunun hemen altina gider
        let playBtnY = safeAreaFrame.minY + safeAreaFrame.height * 0.38
        let spacing  = C.screenH * 0.018  // Butonlar arasi bosluk
        let btnY     = playBtnY - btnH - spacing

        // Rounded rect path guncelle — SKShapeNode boyutu path ile kontrol edilir
        let rect = CGRect(x: -btnW / 2, y: -btnH / 2, width: btnW, height: btnH)
        leaderboardButtonNode.path = CGPath(
            roundedRect: rect,
            cornerWidth: btnH / 2,
            cornerHeight: btnH / 2,
            transform: nil
        )
        leaderboardButtonNode.position = CGPoint(x: safeAreaFrame.midX, y: btnY)

        // Buton yazisi font boyutu ve ortasi guncellenir
        if let leaderboardButtonLabel {
            leaderboardButtonLabel.fontSize = C.screenH * 0.030
            leaderboardButtonLabel.position = .zero
        }
    }

    /// Oyna butonunun boyut ve pozisyonunu gunceller
    private func layoutPlayButton() {
        guard let playButtonNode else { return }

        // Buton boyutlari scene boyutuna gore responsive kalir
        let btnW = C.screenW * 0.52
        let btnH = C.screenH * 0.072
        let btnY = safeAreaFrame.minY + safeAreaFrame.height * 0.38

        // Rounded rect path guncelle — SKShapeNode boyutu path ile kontrol edilir
        let rect = CGRect(x: -btnW / 2, y: -btnH / 2, width: btnW, height: btnH)
        playButtonNode.path = CGPath(
            roundedRect: rect,
            cornerWidth: btnH / 2,
            cornerHeight: btnH / 2,
            transform: nil
        )
        playButtonNode.position = CGPoint(x: safeAreaFrame.midX, y: btnY)

        // Buton yazisi font boyutu ve ortasi guncellenir
        if let playButtonLabel {
            playButtonLabel.fontSize = C.screenH * 0.030
            playButtonLabel.position = .zero
        }
    }

    // MARK: - Arka Plan

    /// Koyu gradient hissi icin arka plana hafif bir dekoratif katman ekler
    private func setupBackground() {
        // Alt kisma hafif parlama efekti — derinlik icin
        let glow = SKSpriteNode(
            color: UIColor(red: 0.15, green: 0.15, blue: 0.35, alpha: 0.4).sk,
            size: CGSize(width: C.screenW * 1.5, height: C.screenH * 0.5)
        )
        glow.zPosition = C.zBackground
        addChild(glow)
        glowNode = glow
    }

    // MARK: - Dekoratif Bloklar

    /// Arka planda yuzen renkli bloklar — gorsel zenginlik, oyunun tadini verir
    private func setupDecorativeBlocks() {
        let colors: [UIColor] = [
            C.colorSingle, C.colorH2, C.colorH3,
            C.colorV2, C.colorV3, C.colorSquare,
            C.colorL, C.colorJ
        ]

        // Drift miktarlari ekran boyutuna gore — sabit px kullanilmaz
        let driftXRange = C.screenW * 0.06
        let driftYRange = C.screenH * 0.05

        for (i, color) in colors.enumerated() {
            let cell = SKSpriteNode(
                color: color.withAlphaComponent(0.30).sk,
                size: CGSize(width: C.cellSize * 0.9, height: C.cellSize * 0.9)
            )
            cell.zPosition = C.zBackground + 0.5
            addChild(cell)

            // Safe area icinde rastgele oranlar — layout yeniden hesaplaninca ayni oranda kalir
            let xRatio = CGFloat.random(in: 0.08...0.92)
            let yRatio = CGFloat.random(in: 0.28...0.70)
            decorativeBlocks.append((node: cell, xRatio: xRatio, yRatio: yRatio))

            // Her blok kendi ritmiyle hareket eder — kaotik degil, rahat
            let delay    = Double(i) * 0.35
            let dur      = Double.random(in: 3.5...6.0)
            let driftX   = CGFloat.random(in: -driftXRange...driftXRange)
            let driftY   = CGFloat.random(in: -driftYRange...driftYRange)
            let drift     = SKAction.moveBy(x: driftX, y: driftY, duration: dur)
            let driftBack = drift.reversed()
            let rotate    = SKAction.rotate(byAngle: .pi / 5, duration: dur)
            let rotBack   = rotate.reversed()

            let loop = SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.repeatForever(SKAction.sequence([drift, driftBack])),
                    SKAction.repeatForever(SKAction.sequence([rotate, rotBack]))
                ])
            ]))
            cell.run(loop)
        }
    }

    // MARK: - Logo

    /// Oyun basligi — ekranin ust %75'ine konumlandirilir
    private func setupLogo() {
        // Ana baslik
        let title = SKLabelNode(fontNamed: C.fontBold)
        title.text      = "BLOCK NOVA"
        title.fontSize  = C.screenH * 0.055
        title.fontColor = .white
        title.zPosition = C.zUI
        addChild(title)
        titleLabel = title

        // Hafif sallanma — logo canli gorunsun
        let wobble = SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle:  0.025, duration: 0.9),
            SKAction.rotate(byAngle: -0.025, duration: 0.9)
        ]))
        title.run(wobble)

        // Alt yazi
        let sub = SKLabelNode(fontNamed: C.fontMedium)
        sub.text      = "Surdur. Yerlestir. Patlat!"
        sub.fontSize  = C.screenH * 0.020
        sub.fontColor = UIColor.white.withAlphaComponent(0.55).sk
        sub.zPosition = C.zUI
        addChild(sub)
        subtitleLabel = sub
    }

    // MARK: - Oyna Butonu

    /// Yesil rounded buton — ekranin %38'ine konumlandirilir
    private func setupPlayButton() {
        // Buton arka plani
        let rect = CGRect(x: -1, y: -1, width: 2, height: 2)
        let btn  = SKShapeNode(rect: rect, cornerRadius: 1)
        btn.fillColor   = UIColor(hex: "#00c853").sk
        btn.strokeColor = .clear
        btn.zPosition   = C.zUI
        btn.name        = "playButton"
        addChild(btn)
        playButtonNode = btn

        // Buton yazisi
        let lbl = SKLabelNode(fontNamed: C.fontBold)
        lbl.text                  = "OYNA"
        lbl.fontSize              = C.screenH * 0.030
        lbl.fontColor             = .white
        lbl.verticalAlignmentMode = .center
        lbl.name                  = "playButton"
        btn.addChild(lbl)
        playButtonLabel = lbl

        // Pulse animasyonu — "tikla beni" cagrisi
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.055, duration: 0.75),
            SKAction.scale(to: 1.000, duration: 0.75)
        ]))
        btn.run(pulse)
    }

    // MARK: - Liderlik Tablosu Butonu

    /// Mavi tonda rounded buton — OYNA butonuyla uyumlu stil
    private func setupLeaderboardButton() {
        // Buton arka plani — mavi ton kullanilir: oyundan farkli ama uyumlu
        let rect = CGRect(x: -1, y: -1, width: 2, height: 2)
        let btn  = SKShapeNode(rect: rect, cornerRadius: 1)
        btn.fillColor   = UIColor(hex: "#1565c0").sk  // Koyu mavi — yesilden ayirt eder
        btn.strokeColor = .clear
        btn.zPosition   = C.zUI
        btn.name        = "leaderboardButton"
        addChild(btn)
        leaderboardButtonNode = btn

        // Buton yazisi
        let lbl = SKLabelNode(fontNamed: C.fontBold)
        lbl.text                  = "LIDERLIK"
        lbl.fontSize              = C.screenH * 0.030
        lbl.fontColor             = .white
        lbl.verticalAlignmentMode = .center
        lbl.name                  = "leaderboardButton"
        btn.addChild(lbl)
        leaderboardButtonLabel = lbl
    }

    // MARK: - Rekor Etiketi

    /// Kaydedilmis en yuksek skoru gosterir
    private func setupHighScoreLabel() {
        let hs = UserDefaults.standard.integer(forKey: C.highScoreKey)
        let lbl = SKLabelNode(fontNamed: C.fontMedium)
        lbl.text      = "EN YUKSEK: \(hs)"
        lbl.fontSize  = C.screenH * 0.020
        lbl.fontColor = C.goldColor.sk
        lbl.zPosition = C.zUI
        addChild(lbl)
        highScoreLabel = lbl
    }

    // MARK: - Dokunus

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc  = touch.location(in: self)
        let node = atPoint(loc)

        // Butonun kendisi veya icindeki label'a dokunulmus olabilir
        if node.name == "playButton" || node.parent?.name == "playButton" {
            // Haptic: menuden oyuna gecis hissi
            HapticManager.selectionChanged()
            goToGame()
        }

        // Liderlik butonuna dokunulursa Game Center ekrani ac
        if node.name == "leaderboardButton" || node.parent?.name == "leaderboardButton" {
            HapticManager.selectionChanged()
            // rootViewController üzerinden GKGameCenterViewController sunulur
            if let rootVC = view?.window?.rootViewController {
                GameManager.showLeaderboard(from: rootVC)
            }
        }
    }

    // MARK: - Sahne Gecisi

    /// GameScene'e fade gecisiyle gecer
    private func goToGame() {
        let game = GameScene(size: size)
        game.scaleMode = scaleMode
        view?.presentScene(game, transition: SKTransition.fade(withDuration: 0.4))
    }
}
