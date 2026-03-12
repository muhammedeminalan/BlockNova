// 📁 Scenes/GameScene+Overlay.swift
// Oyun sonu overlay inşası ve etkileşim yönetimi.
//
// TASARIM KARARLARI:
// - Kart yüksekliği içerik miktarına göre dinamik hesaplanır → hiçbir zaman sığmama olmaz
// - Tüm Y pozisyonları üstten aşağı sabit aralıklarla yerleştirilir (flow layout) →
//   eleman eklenince diğerleri kendi payından yer almaz, bütün alan yeniden bölüşülür
// - Butonlar her zaman kartın altına sabitlenir → içerik ne kadar olursa olsun kart dışına çıkmaz
// - Tek bir overlayNode yönetimi → üst üste bindirme imkansız

import SpriteKit
import UIKit

// MARK: - Overlay Inşası

extension GameScene {

    /// Oyun sonu overlay'ini oluşturur ve sahneye ekler.
    /// Zaten açık overlay varsa önce kaldırılır — üst üste bindirme önlenir.
    func showGameOverOverlay() {
        // Önceden açık overlay varsa temizle — tekrar tetiklenme koruması
        overlayNode?.removeFromParent()
        overlayNode = nil

        let overlay = SKNode()
        overlay.zPosition = C.zOverlay
        overlay.alpha     = 0

        // ── ARKA PLAN KARARTMASI ───────────────────────────────────────────
        let dim = SKSpriteNode(
            color: UIColor(red: 0.02, green: 0.02, blue: 0.10, alpha: 0.88).sk,
            size: CGSize(width: C.screenW, height: C.screenH)
        )
        dim.anchorPoint = .zero
        dim.position    = .zero
        dim.zPosition   = 0
        overlay.addChild(dim)

        // ── KART BOYUTLARI ─────────────────────────────────────────────────
        let isNewRecord = viewModel.oyunSonuYeniRekorMu

        let cardW = C.screenW * 0.82

        // Buton bölgesi için gereken sabit alan: 2 buton + aralarındaki boşluk + alt/üst padding
        // Bu alan sabit tutulur; içerik alanı kalan yüksekliğe sığdırılır
        let btnH     = clamp(C.screenH * 0.058, lo: 44, hi: 62)  // buton yüksekliği (pt)
        let btnGap   = clamp(C.screenH * 0.016, lo: 10, hi: 18)  // iki buton arası
        let btnPadB  = clamp(C.screenH * 0.026, lo: 16, hi: 28)  // alt kenar boşluğu
        let btnPadT  = clamp(C.screenH * 0.022, lo: 14, hi: 24)  // butonların üstündeki boşluk
        let buttonZoneH = btnPadB + btnH + btnGap + btnH + btnPadT

        // İçerik satırları: başlık, [badge], büyük skor, "PUAN", rekor
        // Her satırın yüksekliği hesaplanır; toplam içerik alanı buna göre belirlenir
        let titleSize  = clamp(C.screenH * 0.028, lo: 17, hi: 26)
        let badgeSize  = titleSize * 0.80
        let scoreSize  = clamp(C.screenH * 0.064, lo: 42, hi: 72)
        let ptsSize    = clamp(C.screenH * 0.015, lo: 10, hi: 16)
        let hsSize     = clamp(C.screenH * 0.018, lo: 12, hi: 18)

        let lineGap    = clamp(C.screenH * 0.012, lo: 8,  hi: 14)  // satırlar arası
        let topPad     = clamp(C.screenH * 0.030, lo: 18, hi: 30)  // kartın üstünden başlık mesafesi

        // İçerik bölgesi toplam yüksekliği (üstten alta)
        var contentH = topPad + titleSize
        if isNewRecord { contentH += lineGap * 0.5 + badgeSize }
        contentH += lineGap + scoreSize + ptsSize * 0.4 + lineGap + hsSize

        // Kart yüksekliği = içerik + separator payı + buton bölgesi
        // min/max ile SE–ProMax arası sağlıklı aralıkta kalır
        let sepH    = clamp(C.screenH * 0.012, lo: 8, hi: 14)  // separator + çevresi boşluğu
        let cardH   = clamp(contentH + sepH + buttonZoneH,
                            lo: C.screenH * 0.46,
                            hi: C.screenH * 0.62)
        let corner  = clamp(cardH * 0.07, lo: 14, hi: 26)

        // ── KART POZİSYONU ─────────────────────────────────────────────────
        let safeMidY: CGFloat = safeAreaFrame == .zero
            ? C.screenH / 2
            : safeAreaFrame.midY + C.screenH * 0.015

        let cardX = C.screenW / 2

        // ── GÖLGE ──────────────────────────────────────────────────────────
        let shadowRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
        let shadow     = SKShapeNode(rect: shadowRect, cornerRadius: corner)
        shadow.fillColor   = UIColor.black.withAlphaComponent(0.40).sk
        shadow.strokeColor = .clear
        shadow.position    = CGPoint(x: cardX, y: safeMidY - C.screenH * 0.016)
        shadow.zPosition   = 1
        overlay.addChild(shadow)

        // ── ANA KART ──────────────────────────────────────────────────────
        let cardRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
        let card     = SKShapeNode(rect: cardRect, cornerRadius: corner)
        card.fillColor   = UIColor(red: 0.10, green: 0.10, blue: 0.26, alpha: 1.0).sk
        card.strokeColor = UIColor(red: 0.35, green: 0.55, blue: 1.00, alpha: 0.28).sk
        card.lineWidth   = max(0.8, C.screenW * 0.0018)
        card.position    = CGPoint(x: cardX, y: safeMidY)
        card.zPosition   = 2
        overlay.addChild(card)

        // ── İÇERİK (flow layout: üstten aşağı) ───────────────────────────
        buildCardContent(
            in: card,
            cardW: cardW, cardH: cardH,
            titleSize: titleSize, badgeSize: badgeSize,
            scoreSize: scoreSize, ptsSize: ptsSize, hsSize: hsSize,
            btnH: btnH, btnGap: btnGap, btnPadB: btnPadB,
            lineGap: lineGap, topPad: topPad,
            isNewRecord: isNewRecord
        )

        // ── EKLE & ANİMASYON ──────────────────────────────────────────────
        addChild(overlay)
        overlayNode = overlay

        overlay.position = CGPoint(x: 0, y: -C.screenH * 0.022)
        overlay.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.28),
            SKAction.move(to: .zero, duration: 0.20)
        ]))
    }

    // MARK: - Kart İçeriği (Flow Layout)

    /// Kart içeriğini üstten aşağıya sabit aralıklarla yerleştirir.
    /// Tüm boyutlar dışarıdan geçirilir — bu fonksiyon sadece node oluşturur ve konumlar.
    private func buildCardContent(
        in card: SKShapeNode,
        cardW: CGFloat, cardH: CGFloat,
        titleSize: CGFloat, badgeSize: CGFloat,
        scoreSize: CGFloat, ptsSize: CGFloat, hsSize: CGFloat,
        btnH: CGFloat, btnGap: CGFloat, btnPadB: CGFloat,
        lineGap: CGFloat, topPad: CGFloat,
        isNewRecord: Bool
    ) {
        let bilgi       = viewModel.oyunSonuBilgisi
        let maxContentW = cardW * 0.84  // yatay taşma sınırı

        // Y referansı: kartın tepesinden (cardH/2) aşağı doğru ilerleyeceğiz
        // SpriteKit'te Y yukarı artar; içerik için tersine gideceğiz
        var cursorY = cardH / 2 - topPad

        // ── BAŞLIK ─────────────────────────────────────────────────────────
        let title = makeLabel("OYUN BİTTİ", font: C.fontBold, size: titleSize,
                              color: UIColor(red: 0.72, green: 0.82, blue: 1.00, alpha: 1.0).sk)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: cursorY - titleSize * 0.5)
        card.addChild(title)
        klipla(title, maxWidth: maxContentW)
        cursorY -= titleSize

        // ── YENİ REKOR BADGE ───────────────────────────────────────────────
        if isNewRecord {
            cursorY -= lineGap * 0.6
            let badge = makeLabel("★ YENİ REKOR", font: C.fontBold, size: badgeSize,
                                  color: C.goldColor.sk)
            badge.verticalAlignmentMode = .center
            badge.position = CGPoint(x: 0, y: cursorY - badgeSize * 0.5)
            card.addChild(badge)
            klipla(badge, maxWidth: maxContentW * 0.88)
            cursorY -= badgeSize
        }

        // ── BÜYÜK SKOR ─────────────────────────────────────────────────────
        cursorY -= lineGap
        let scoreLbl = makeLabel(bilgi.skor, font: C.fontBold, size: scoreSize,
                                 color: C.goldColor.sk)
        scoreLbl.verticalAlignmentMode = .center
        scoreLbl.position = CGPoint(x: 0, y: cursorY - scoreSize * 0.5)
        card.addChild(scoreLbl)
        klipla(scoreLbl, maxWidth: maxContentW)
        cursorY -= scoreSize

        // ── "PUAN" ALT ETİKETİ ─────────────────────────────────────────────
        // Skor ile aynı ilgi merkezinde ama küçük ve soluk
        let ptsLbl = makeLabel("PUAN", font: C.fontMedium, size: ptsSize,
                               color: UIColor.white.withAlphaComponent(0.40).sk)
        ptsLbl.verticalAlignmentMode = .center
        ptsLbl.position = CGPoint(x: 0, y: cursorY - ptsSize * 0.1)
        card.addChild(ptsLbl)
        cursorY -= ptsSize * 0.8

        // ── REKOR SATIRI ────────────────────────────────────────────────────
        cursorY -= lineGap * 1.1
        let hsLbl = makeLabel(bilgi.rekor, font: C.fontMedium, size: hsSize,
                              color: UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 0.78).sk)
        hsLbl.verticalAlignmentMode = .center
        hsLbl.position = CGPoint(x: 0, y: cursorY - hsSize * 0.5)
        card.addChild(hsLbl)
        klipla(hsLbl, maxWidth: maxContentW)

        // ── AYIRICI ÇİZGİ ──────────────────────────────────────────────────
        // Buton bölgesinin tam üstüne yerleştirilir — sabit pozisyon
        let btnZoneTopY  = -(cardH / 2) + btnPadB + btnH + btnGap + btnH
        let sepY         = btnZoneTopY  // separator buton bölgesinin hemen üstü
        let sepPadX      = cardW * 0.10
        let sepPath      = CGMutablePath()
        sepPath.move(to:    CGPoint(x: -cardW / 2 + sepPadX, y: sepY))
        sepPath.addLine(to: CGPoint(x:  cardW / 2 - sepPadX, y: sepY))
        let sep = SKShapeNode(path: sepPath)
        sep.strokeColor = UIColor.white.withAlphaComponent(0.09).sk
        sep.lineWidth   = max(0.5, C.screenW * 0.0012)
        card.addChild(sep)

        // ── BUTONLAR (alttan yukarı — asla sığmama olmaz) ──────────────────
        let btnW = cardW * 0.80

        // Alt buton: "ANA MENÜ"
        let btn2Y = -(cardH / 2) + btnPadB + btnH * 0.5
        addOverlayButton(to: card, text: "ANA MENÜ", name: "homeBtn",
                         primaryColor: UIColor(hex: "#2962FF"),
                         y: btn2Y, w: btnW, h: btnH)

        // Üst buton: "TEKRAR OYNA"
        let btn1Y = btn2Y + btnH + btnGap
        addOverlayButton(to: card, text: "TEKRAR OYNA", name: "restartBtn",
                         primaryColor: UIColor(hex: "#00C853"),
                         y: btn1Y, w: btnW, h: btnH)
    }

    // MARK: - Buton Yardımcısı

    /// Overlay kart içine yuvarlak buton ekler. Gölge + parlama kenarlığı içerir.
    func addOverlayButton(to parent: SKNode, text: String, name: String,
                          primaryColor: UIColor, y: CGFloat, w: CGFloat, h: CGFloat) {
        let corner = h * 0.50
        let rect   = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)

        // Alt gölge — derinlik hissi verir
        let shadowBtn = SKShapeNode(rect: rect, cornerRadius: corner)
        shadowBtn.fillColor   = UIColor.black.withAlphaComponent(0.28).sk
        shadowBtn.strokeColor = .clear
        shadowBtn.position    = CGPoint(x: 0, y: y - h * 0.06)
        parent.addChild(shadowBtn)

        // Ana buton
        let btn = SKShapeNode(rect: rect, cornerRadius: corner)
        btn.fillColor   = primaryColor.sk
        btn.strokeColor = UIColor.white.withAlphaComponent(0.16).sk
        btn.lineWidth   = max(0.8, w * 0.003)
        btn.name        = name
        btn.position    = CGPoint(x: 0, y: y)
        parent.addChild(btn)

        // Etiket
        let fontSize = clamp(C.screenH * 0.021, lo: 14, hi: 22)
        let lbl      = makeLabel(text, font: C.fontBold, size: fontSize, color: .white)
        lbl.verticalAlignmentMode = .center
        lbl.name = name
        btn.addChild(lbl)
        klipla(lbl, maxWidth: w * 0.84)
    }

    // MARK: - Dokunuş Yönetimi

    /// Overlay üzerindeki dokunuşu buton ismine göre yönlendirir
    func handleOverlayTap(_ node: SKNode) {
        switch node.name {
        case "restartBtn":
            animateButtonPress(node) { [weak self] in
                HapticManager.impact(.light)
                self?.restartGame()
            }
        case "homeBtn":
            animateButtonPress(node) { [weak self] in
                HapticManager.impact(.light)
                self?.goToHome()
            }
        default: break
        }
    }

    // MARK: - Yardımcılar

    /// İki boyut kısıtlaması arasından küçüğünü seçer — hem screenH hem kart oranına uyar
    func sizeKisitli(tercih: CGFloat, kart: CGFloat) -> CGFloat { min(tercih, kart) }

    /// Etiket genişliği maxWidth'i aşarsa ölçekler — kesin taşma önleyici
    func klipla(_ lbl: SKLabelNode, maxWidth: CGFloat) {
        guard lbl.frame.width > maxWidth, maxWidth > 0 else { return }
        lbl.setScale(maxWidth / lbl.frame.width)
    }

    /// Değeri [lo, hi] aralığında sınırlar — responsive değerlerin güvenli tavan/taban kontrolü
    private func clamp(_ value: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        max(lo, min(hi, value))
    }

    /// Butona hafif bas-bırak animasyonu yapar, tamamlanınca closure çağırır
    private func animateButtonPress(_ node: SKNode, completion: @escaping () -> Void) {
        let target: SKNode = {
            if node.name != nil, let p = node.parent, p.name == node.name { return p }
            return node
        }()
        target.removeAllActions()
        target.run(SKAction.sequence([
            SKAction.scale(to: 0.93, duration: 0.07),
            SKAction.scale(to: 1.00, duration: 0.08),
            SKAction.run(completion)
        ]))
    }
}
