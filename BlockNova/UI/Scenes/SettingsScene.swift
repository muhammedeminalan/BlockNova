// 📁 Scenes/SettingsScene.swift
// Ayarlar sahnesi — ses ve titreşim tercihleri

import SpriteKit
import UIKit

// MARK: - SettingsScene

final class SettingsScene: SKScene, SafeAreaUpdatable {

    // MARK: - Safe Area

    /// Güncel safe area inset'leri — layout hesaplarında kullanılır
    private var safeAreaInsets: UIEdgeInsets = .zero
    /// HomeScene referansı — geri dönüşte aynı sahne kullanılır
    var homeScene: HomeScene?

    // MARK: - Node Referansları

    private var titleLabel: SKLabelNode?
    private var backButtonNode: SKShapeNode?
    private var backButtonLabel: SKLabelNode?
    private var subtitleLabel: SKLabelNode?
    private var topGlowNode: SKShapeNode?

    private var soundCardNode: SKSpriteNode?
    private var hapticCardNode: SKSpriteNode?
    private var soundCardShadow: SKShapeNode?
    private var hapticCardShadow: SKShapeNode?

    private var soundToggleNode: ToggleNode?
    private var hapticToggleNode: ToggleNode?

    private var isSetup = false

    // MARK: - Sahne Girişi

    override func didMove(to view: SKView) {
        // Arka plan rengi — HomeScene ile aynı
        backgroundColor = UIColor(hex: "#0a0a1a")
        C.updateSceneSize(size)
        safeAreaInsets = view.safeAreaInsets

        if !isSetup {
            kurgula()
            isSetup = true
        }
        layoutScene()
    }

    // MARK: - Safe Area Güncellemesi

    func updateSafeAreaInsets(_ insets: UIEdgeInsets) {
        safeAreaInsets = insets
        layoutScene()
    }

    // MARK: - Ana Kurulum

    private func kurgula() {
        kurgulaBaslik()
        kurgulaGeriButonu()
        kurgulaSesKarti()
        kurgulaTitresimKarti()
    }

    private func kurgulaBaslik() {
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = "Ayarlar"
        lbl.fontSize = C.screenH * 0.032
        lbl.fontColor = .white
        lbl.zPosition = C.zUI
        addChild(lbl)
        titleLabel = lbl
    }

    private func kurgulaGeriButonu() {
        let btnW = C.screenW * 0.26
        let btnH = C.screenH * 0.045

        let btn = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: btnH / 2)
        btn.fillColor = UIColor(hex: "#1a1a3e").withAlphaComponent(0.95).sk
        btn.strokeColor = UIColor.white.withAlphaComponent(0.16).sk
        btn.lineWidth = 1
        btn.lineJoin = .round
        btn.isAntialiased = true
        btn.zPosition = C.zUI
        btn.name = "backBtn"
        addChild(btn)
        backButtonNode = btn

        let lbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        lbl.text = "Geri"
        lbl.fontSize = C.screenH * 0.018
        lbl.fontColor = UIColor.white.withAlphaComponent(0.85)
        lbl.horizontalAlignmentMode = .left
        lbl.verticalAlignmentMode = .center
        lbl.position = CGPoint(x: -btnW * 0.20, y: 0)
        lbl.zPosition = 1
        lbl.name = "backBtn"
        btn.addChild(lbl)
        backButtonLabel = lbl
    }

    private func kurgulaSesKarti() {
        let kart = ayarKartiOlustur(
            baslik: "Ses Efektleri",
            toggleName: "soundToggle",
            isOn: SettingsManager.shared.isSoundEnabled
        )
        let shadow = kartGolgeOlustur(for: kart.size)
        addChild(shadow)
        addChild(kart)
        soundCardShadow = shadow
        soundCardNode = kart
    }

    private func kurgulaTitresimKarti() {
        let kart = ayarKartiOlustur(
            baslik: "Titreşim",
            toggleName: "hapticToggle",
            isOn: SettingsManager.shared.isHapticEnabled
        )
        let shadow = kartGolgeOlustur(for: kart.size)
        addChild(shadow)
        addChild(kart)
        hapticCardShadow = shadow
        hapticCardNode = kart
    }

    // MARK: - Kart Yardımcısı

    private func ayarKartiOlustur(baslik: String, toggleName: String, isOn: Bool) -> SKSpriteNode {
        let kartBoyutu = CGSize(width: C.screenW * 0.85, height: C.screenH * 0.09)
        let kart = SKSpriteNode(
            color: .clear,
            size: kartBoyutu
        )
        kart.zPosition = C.zUI

        // Rounded corners: SKShapeNode ile
        let rounded = SKShapeNode(rectOf: kartBoyutu, cornerRadius: kartBoyutu.height * 0.25)
        rounded.fillColor = UIColor(red: 0.09, green: 0.09, blue: 0.22, alpha: 1).sk
        rounded.strokeColor = UIColor.white.withAlphaComponent(0.10).sk
        rounded.lineWidth = 1
        rounded.zPosition = 0
        kart.addChild(rounded)

        // Üst highlight çizgisi — kartlara hafif cam hissi
        let highlightPath = CGMutablePath()
        highlightPath.move(to: CGPoint(x: -kartBoyutu.width / 2 + 12, y: kartBoyutu.height / 2 - 2))
        highlightPath.addLine(to: CGPoint(x: kartBoyutu.width / 2 - 12, y: kartBoyutu.height / 2 - 2))
        let highlight = SKShapeNode(path: highlightPath)
        highlight.strokeColor = UIColor.white.withAlphaComponent(0.08).sk
        highlight.lineWidth = 1
        highlight.zPosition = 0.5
        kart.addChild(highlight)

        // Başlık
        let baslikLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        baslikLabel.text = baslik
        baslikLabel.fontSize = C.screenH * 0.021
        baslikLabel.fontColor = UIColor.white.withAlphaComponent(0.85)
        baslikLabel.horizontalAlignmentMode = .left
        baslikLabel.verticalAlignmentMode = .center
        baslikLabel.position = CGPoint(x: -kartBoyutu.width / 2 + kartBoyutu.height * 0.32, y: 0)
        baslikLabel.zPosition = 1
        kart.addChild(baslikLabel)

        // Toggle
        let toggleBoyutu = CGSize(width: C.screenW * 0.16, height: C.screenH * 0.038)
        let toggle = ToggleNode(size: toggleBoyutu, isOn: isOn)
        toggle.setNodeName(toggleName)
        toggle.position = CGPoint(x: kartBoyutu.width / 2 - toggleBoyutu.width / 2 - kartBoyutu.height * 0.25, y: 0)
        kart.addChild(toggle)

        if toggleName == "soundToggle" {
            soundToggleNode = toggle
        } else if toggleName == "hapticToggle" {
            hapticToggleNode = toggle
        }

        return kart
    }

    private func kartGolgeOlustur(for size: CGSize) -> SKShapeNode {
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2 - 3, width: size.width, height: size.height)
        let shadow = SKShapeNode(rect: rect, cornerRadius: size.height * 0.25)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.25).sk
        shadow.strokeColor = .clear
        shadow.zPosition = C.zUI - 0.2
        return shadow
    }

    // MARK: - Layout

    private func layoutScene() {
        C.updateSceneSize(size)

        let safeBottom = safeAreaInsets.bottom
        let safeTop    = safeAreaInsets.top
        let safeH      = C.screenH - safeTop - safeBottom
        let safeMinY   = safeBottom
        let safeMaxY   = C.screenH - safeTop
        let safeLeft   = safeAreaInsets.left

        // Başlık
        titleLabel?.position = CGPoint(x: C.screenW / 2, y: safeMinY + safeH * 0.86)

        // Geri butonu — sol üst
        backButtonNode?.position = CGPoint(x: safeLeft + C.screenW * 0.16, y: safeMaxY - C.screenH * 0.05)

        // Kartlar
        let soundY = safeMinY + safeH * 0.60
        let hapticY = safeMinY + safeH * 0.46
        soundCardNode?.position = CGPoint(x: C.screenW / 2, y: soundY)
        hapticCardNode?.position = CGPoint(x: C.screenW / 2, y: hapticY)
        soundCardShadow?.position = CGPoint(x: C.screenW / 2, y: soundY)
        hapticCardShadow?.position = CGPoint(x: C.screenW / 2, y: hapticY)

        // Arka plan sade — ekstra efekt yok
    }


    // MARK: - Dokunma Algılama

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)

        if node.name == "backBtn" || node.parent?.name == "backBtn" {
            // Buton geri bildirimi — hafif titresim
            HapticManager.impact(.light)
            // HomeScene yeniden olusmasin — mevcut instance'a don
            guard let home = homeScene else { return }
            home.scaleMode = scaleMode
            view?.presentScene(home, transition: SKTransition.push(with: .right, duration: 0.3))
            return
        }

        if node.name == "soundToggle" || node.parent?.name == "soundToggle" {
            // Buton geri bildirimi — hafif titresim
            HapticManager.impact(.light)
            let yeniDeger = !SettingsManager.shared.isSoundEnabled
            SettingsManager.shared.isSoundEnabled = yeniDeger
            soundToggleNode?.setOn(yeniDeger, animated: true)
            return
        }

        if node.name == "hapticToggle" || node.parent?.name == "hapticToggle" {
            // Buton geri bildirimi — hafif titresim
            HapticManager.impact(.light)
            let yeniDeger = !SettingsManager.shared.isHapticEnabled
            SettingsManager.shared.isHapticEnabled = yeniDeger
            hapticToggleNode?.setOn(yeniDeger, animated: true)
            return
        }
    }
}

// MARK: - ToggleNode

final class ToggleNode: SKNode {

    private let sizeValue: CGSize
    private let bg: SKShapeNode
    private let knob: SKShapeNode
    private let knobSize: CGSize
    private let padding: CGFloat
    private let onColor: SKColor
    private let offColor: SKColor
    private(set) var isOn: Bool

    init(size: CGSize, isOn: Bool) {
        self.sizeValue = size
        self.isOn = isOn
        self.padding = max(2, size.height * 0.12)
        self.onColor = UIColor(red: 0.0, green: 0.8, blue: 0.33, alpha: 1).sk
        self.offColor = UIColor(white: 0.25, alpha: 1).sk

        let bgRect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        self.bg = SKShapeNode(rect: bgRect, cornerRadius: size.height / 2)
        self.bg.lineWidth = 0

        self.knobSize = CGSize(width: size.height - padding * 2, height: size.height - padding * 2)
        let knobRect = CGRect(
            x: -self.knobSize.width / 2,
            y: -self.knobSize.height / 2,
            width: self.knobSize.width,
            height: self.knobSize.height
        )
        self.knob = SKShapeNode(rect: knobRect, cornerRadius: knobSize.height / 2)
        self.knob.fillColor = SKColor.white
        self.knob.strokeColor = .clear

        super.init()

        addChild(bg)
        addChild(knob)
        uygulaDurum(animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func setNodeName(_ name: String) {
        self.name = name
        bg.name = name
        knob.name = name
    }

    func setOn(_ on: Bool, animated: Bool) {
        isOn = on
        uygulaDurum(animated: animated)
    }

    private func uygulaDurum(animated: Bool) {
        let knobX = isOn
            ? sizeValue.width / 2 - (knobSize.width / 2) - padding
            : -sizeValue.width / 2 + (knobSize.width / 2) + padding

        let hedefRenk = isOn ? onColor : offColor

        if animated {
            let hareket = SKAction.moveTo(x: knobX, duration: 0.18)
            hareket.timingMode = .easeOut
            knob.run(hareket)

            let renk = SKAction.run { [weak self] in
                self?.bg.fillColor = hedefRenk
            }
            bg.run(renk)
        } else {
            knob.position = CGPoint(x: knobX, y: 0)
            bg.fillColor = hedefRenk
        }
    }
}
