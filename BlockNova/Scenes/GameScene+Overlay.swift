// 📁 Scenes/GameScene+Overlay.swift
// Oyun sonu overlay inşası ve etkileşimi.
// GameScene ana dosyasını ince tutar — tüm overlay node mantığı burada.

import SpriteKit
import UIKit

// MARK: - Overlay Inşası

extension GameScene {

    /// Yarı saydam overlay + skor kartı oluşturur ve sahneye ekler.
    /// Yeni scene geçişi YOK — geçiş kasması yapar; overlay sahneye eklenir.
    func showGameOverOverlay() {
        let overlay = SKNode()
        overlay.zPosition = C.zOverlay
        overlay.alpha = 0

        // Karartma katmanı — dikkat kartta toplansın
        let dim = SKSpriteNode(
            color: UIColor.black.withAlphaComponent(0.85).sk,
            size: CGSize(width: C.screenW, height: C.screenH)
        )
        dim.anchorPoint = .zero
        dim.position = .zero
        overlay.addChild(dim)

        // Kart boyutları responsive
        let cardW  = C.screenW * 0.80
        let cardH  = C.screenH * 0.44
        let cardX  = C.screenW / 2
        // Kart Y safe area merkezine alın — alt paneli ve notch'ı ihlal etmesin
        let safeCenterY = safeAreaFrame == .zero ? C.screenH / 2 : safeAreaFrame.midY
        let corner = cardH * 0.12

        let cardRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
        let card = SKShapeNode(rect: cardRect, cornerRadius: corner)
        card.fillColor   = UIColor(hex: "#1a1a36").sk
        card.strokeColor = UIColor.white.withAlphaComponent(0.12).sk
        card.lineWidth   = C.screenW * 0.0022
        card.position    = CGPoint(x: cardX, y: safeCenterY)
        overlay.addChild(card)

        // Hafif gölge — derinlik hissi
        let shadow = SKShapeNode(rect: cardRect, cornerRadius: corner)
        shadow.fillColor   = UIColor.black.withAlphaComponent(0.25).sk
        shadow.strokeColor = .clear
        shadow.position    = CGPoint(x: cardX, y: safeCenterY - C.screenH * 0.01)
        shadow.zPosition   = -0.5
        overlay.addChild(shadow)

        // Dikey içerik aralıkları
        let contentTop = cardH / 2 - cardH * 0.16
        let spacing    = cardH * 0.12

        // Font boyutları — kart yüksekliğine orantılı, taşma olmaz
        let titleSize = min(C.screenH * 0.034, cardH * 0.12)
        let scoreSize = min(C.screenH * 0.070, cardH * 0.22)
        let ptsSize   = min(C.screenH * 0.018, cardH * 0.06)
        let hsSize    = min(C.screenH * 0.022, cardH * 0.07)

        // "OYUN BİTTİ"
        let title = makeLabel("OYUN BITTI", font: C.fontBold, size: titleSize, color: .white)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: contentTop)
        card.addChild(title)

        // Skor
        let bilgi = viewModel.oyunSonuBilgisi
        let scoreLbl = makeLabel(bilgi.skor, font: C.fontBold, size: scoreSize, color: C.goldColor.sk)
        scoreLbl.verticalAlignmentMode = .center
        scoreLbl.position = CGPoint(x: 0, y: contentTop - spacing)
        card.addChild(scoreLbl)

        let ptsLbl = makeLabel("PUAN", font: C.fontMedium, size: ptsSize,
                               color: UIColor.white.withAlphaComponent(0.5).sk)
        ptsLbl.verticalAlignmentMode = .center
        ptsLbl.position = CGPoint(x: 0, y: contentTop - spacing * 1.75)
        card.addChild(ptsLbl)

        // Rekor
        let hsLbl = makeLabel(bilgi.rekor, font: C.fontMedium, size: hsSize, color: C.goldColor.sk)
        hsLbl.verticalAlignmentMode = .center
        hsLbl.position = CGPoint(x: 0, y: contentTop - spacing * 2.55)
        card.addChild(hsLbl)

        // Uzun metinlerde taşmayı önle
        let maxW = cardW * 0.78
        [title, scoreLbl, hsLbl].forEach { lbl in
            if lbl.frame.width > maxW { lbl.setScale(maxW / lbl.frame.width) }
        }

        // Ayırıcı çizgi
        let sepPath  = CGMutablePath()
        let sepLeft  = -cardW / 2 + cardW * 0.10
        let sepRight =  cardW / 2 - cardW * 0.10
        let sepY     = -cardH / 2 + cardH * 0.28
        sepPath.move(to: CGPoint(x: sepLeft, y: sepY))
        sepPath.addLine(to: CGPoint(x: sepRight, y: sepY))
        let sep = SKShapeNode(path: sepPath)
        sep.strokeColor = UIColor.white.withAlphaComponent(0.12).sk
        sep.lineWidth   = C.screenW * 0.0016
        card.addChild(sep)

        // Butonlar
        let btnW = cardW * 0.76
        let btnH = C.screenH * 0.060
        addOverlayButton(to: card, text: "YENIDEN OYNA", name: "restartBtn",
                         color: UIColor(hex: "#00c853"),
                         y: -cardH / 2 + cardH * 0.22, w: btnW, h: btnH)
        addOverlayButton(to: card, text: "ANA MENU", name: "homeBtn",
                         color: UIColor(hex: "#1565c0"),
                         y: -cardH / 2 + cardH * 0.08, w: btnW, h: btnH)

        addChild(overlay)
        overlayNode = overlay

        // Fade + scale pop girişi
        overlay.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.35),
            SKAction.sequence([
                SKAction.scale(to: 0.96, duration: 0.0),
                SKAction.scale(to: 1.0,  duration: 0.18)
            ])
        ]))
    }

    // MARK: - Buton Yardımcısı

    /// Overlay kart içine standart yuvarlak buton ekler
    func addOverlayButton(to parent: SKNode, text: String, name: String,
                          color: UIColor, y: CGFloat, w: CGFloat, h: CGFloat) {
        let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
        let btn  = SKShapeNode(rect: rect, cornerRadius: h / 2)
        btn.fillColor   = color.sk
        btn.strokeColor = .clear
        btn.name        = name
        btn.position    = CGPoint(x: 0, y: y)
        parent.addChild(btn)

        let lbl = makeLabel(text, font: C.fontBold, size: C.screenH * 0.022, color: .white)
        lbl.verticalAlignmentMode = .center
        lbl.name = name
        btn.addChild(lbl)
    }

    // MARK: - Dokunuş

    /// Overlay üzerindeki dokunuşu yönlendirir
    func handleOverlayTap(_ node: SKNode) {
        switch node.name {
        case "restartBtn":
            HapticManager.impact(.light)
            restartGame()
        case "homeBtn":
            HapticManager.impact(.light)
            goToHome()
        default: break
        }
    }
}
