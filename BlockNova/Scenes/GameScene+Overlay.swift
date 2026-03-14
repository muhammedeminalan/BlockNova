// 📁 Scenes/GameScene+Overlay.swift
// Oyun sonu overlay — premium yeniden tasarım.
//
// TASARIM KARARLARI:
// - Tam ekran koyu dim katmanı: grid tamamen kapanır, odak karta geçer
// - Kompakt kart: ekranı kaplamasın, içerik sıkışık değil ama dolu
// - Skor dairesel gösterim: dramatik ve hatırda kalıcı
// - Skor sayaç animasyonu: 0'dan gerçek değere çıkar, heyecan katar
// - Kart aşağıdan yukarı giriş animasyonu: yumuşak, modern his
// - Tüm boyutlar responsive: sabit px kullanılmaz

import SpriteKit
import UIKit

// MARK: - Overlay Gösterimi

extension GameScene {

    func showGameOverOverlay() {
        // Önceki overlay varsa temizle — üst üste binme önlenir
        overlayNode?.removeFromParent()
        overlayNode = nil

        let overlay = SKNode()
        overlay.zPosition = C.zOverlay

        // KATMAN 1 — Tam ekran koyu arka plan
        // Grid ve oyun alanı tamamen karartılır — dikkat karta çekilir
        let dim = SKSpriteNode(
            color: UIColor.black.withAlphaComponent(0.78).sk,
            size: CGSize(width: C.screenW, height: C.screenH)
        )
        dim.anchorPoint = .zero
        dim.position    = .zero
        dim.zPosition   = 0
        dim.alpha       = 0
        overlay.addChild(dim)

        // Dim katmanı fade in — ani değil, yavaş karartma
        dim.run(SKAction.fadeIn(withDuration: 0.35))

        // KATMAN 2 — Kart
        // Genişlik: ekrana sığacak maksimum
        let kartW = min(C.screenW * 0.84, C.screenW - 32)
        // Yükseklik: içerik miktarına göre dinamik (yeniRekor badge'i varsa daha büyük)
        let isYeniRekor = viewModel.oyunSonuYeniRekorMu
        let kartH = isYeniRekor
            ? min(C.screenH * 0.72, C.screenH - 80)   // YENİ REKOR durumu — daha geniş
            : min(C.screenH * 0.64, C.screenH - 80)   // Normal durum

        olusturKart(overlay: overlay, kartW: kartW, kartH: kartH)

        addChild(overlay)
        overlayNode = overlay
    }

    // MARK: - Kart Oluşturma

    private func olusturKart(overlay: SKNode, kartW: CGFloat, kartH: CGFloat) {
        let ekranOrtaX = C.screenW / 2
        // Safe area varsa ortası, yoksa ekranın ortası
        let ekranOrtaY: CGFloat = safeAreaFrame == .zero
            ? C.screenH / 2
            : safeAreaFrame.midY

        // Giriş animasyonu için başlangıç pozisyonu: ekranın altından gelir
        let basNokta  = CGPoint(x: ekranOrtaX, y: ekranOrtaY - C.screenH * 0.08)
        let hedefNokta = CGPoint(x: ekranOrtaX, y: ekranOrtaY)

        // Hafif gölge — kartı zeminden kaldırır, derinlik katar
        let golgeRect = CGRect(x: -kartW / 2, y: -kartH / 2, width: kartW, height: kartH)
        let golge     = SKShapeNode(rect: golgeRect, cornerRadius: 28)
        golge.fillColor   = UIColor.black.withAlphaComponent(0.35).sk
        golge.strokeColor = .clear
        golge.position    = CGPoint(x: basNokta.x, y: basNokta.y - 6)
        golge.zPosition   = 1
        golge.alpha       = 0
        overlay.addChild(golge)

        // Ana kart
        let kartRect = CGRect(x: -kartW / 2, y: -kartH / 2, width: kartW, height: kartH)
        let kart     = SKShapeNode(rect: kartRect, cornerRadius: 28)
        kart.fillColor   = UIColor(hex: "#0f0f2e").sk
        kart.strokeColor = UIColor.white.withAlphaComponent(0.08).sk
        kart.lineWidth   = 1
        kart.position    = basNokta
        kart.zPosition   = 2
        kart.alpha       = 0
        overlay.addChild(kart)

        // Kart ve gölge giriş animasyonu: aşağıdan yukarı + fade in
        let girisAnimasyon = SKAction.group([
            SKAction.fadeIn(withDuration: 0.35),
            SKAction.move(to: hedefNokta, duration: 0.35)
        ])
        // Ease out hissi için timing function
        girisAnimasyon.timingMode = .easeOut
        kart.run(girisAnimasyon)

        let golgeHedef = CGPoint(x: hedefNokta.x, y: hedefNokta.y - 6)
        let golgeGiris = SKAction.group([
            SKAction.fadeIn(withDuration: 0.35),
            SKAction.move(to: golgeHedef, duration: 0.35)
        ])
        golgeGiris.timingMode = .easeOut
        golge.run(golgeGiris)

        // Kart içeriğini kur — animasyondan kısa süre sonra içerik belirir
        kart.run(SKAction.wait(forDuration: 0.1)) { [weak self] in
            self?.kartIcerigiKur(kart: kart, kartW: kartW, kartH: kartH)
        }
    }

    // MARK: - Kart İçeriği

    // Layout stratejisi: TOP-DOWN FLOW
    // ─────────────────────────────────
    // Cursor (imleç) kartın üst kenarından başlar, her eleman kadar aşağı kayar.
    // Hiçbir eleman sabit px veya C.screenH kullanmaz — her şey kartH oranı.
    // Bu sayede kart ne kadar büyük/küçük olursa olsun içerik asla taşmaz.
    private func kartIcerigiKur(kart: SKShapeNode, kartW: CGFloat, kartH: CGFloat) {
        let isYeniRekor = viewModel.oyunSonuYeniRekorMu
        let guncelSkor  = manager.score
        let guncelRekor = manager.highScore

        // ── BOYUTLAR (kartH'a orantılı) ────────────────────────────────
        let padV          = kartH * 0.06          // üst/alt iç boşluk
        let baslikFontH   = kartH * 0.055         // "— OYUN BİTTİ —" font
        let araKucuk      = kartH * 0.025         // küçük elemanlar arası boşluk
        let araBuyuk      = kartH * 0.035         // büyük elemanlar arası boşluk
        let daireYaricap  = min(kartH * 0.155, kartW * 0.28)
        let puanFontH     = kartH * 0.038
        let rekorFontH    = kartH * 0.052
        let btn1H         = kartH * 0.135
        let btn2H         = kartH * 0.105
        let btnAra        = kartH * 0.028

        // ── CURSOR — üstten aşağıya ────────────────────────────────────
        // cursor = kartın merkezi (0,0)'a göre Y pozisyonu
        // kartın üst kenarı = +kartH/2
        var cursor = kartH / 2 - padV

        // ── 1. BAŞLIK ──────────────────────────────────────────────────
        cursor -= baslikFontH / 2   // label'ın merkezi
        let baslik = SKLabelNode(fontNamed: "AvenirNext-Medium")
        baslik.text      = "— OYUN BİTTİ —"
        baslik.fontSize  = baslikFontH
        baslik.fontColor = UIColor(hex: "#00D4FF").sk
        baslik.horizontalAlignmentMode = .center
        baslik.verticalAlignmentMode   = .center
        baslik.position  = CGPoint(x: 0, y: cursor)
        baslik.zPosition = 1
        baslik.alpha     = 0
        kart.addChild(baslik)
        baslik.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.10),
            SKAction.fadeIn(withDuration: 0.25)
        ]))
        cursor -= baslikFontH / 2   // alt kenarına in
        cursor -= araBuyuk          // daire öncesi boşluk

        // ── 2. SKOR DAİRESİ ────────────────────────────────────────────
        cursor -= daireYaricap      // daire merkezi
        let daireY = cursor
        let daire = SKShapeNode(circleOfRadius: daireYaricap)
        daire.fillColor   = UIColor(hex: "#1a1a3e").sk
        daire.strokeColor = UIColor(hex: "#FFD700").sk
        daire.lineWidth   = 2.0
        daire.position    = CGPoint(x: 0, y: daireY)
        daire.zPosition   = 1
        daire.alpha       = 0
        kart.addChild(daire)
        daire.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.18),
            SKAction.fadeIn(withDuration: 0.25)
        ]))

        let skorLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        skorLabel.text      = "0"
        skorLabel.fontSize  = daireYaricap * 0.85
        skorLabel.fontColor = UIColor(hex: "#FFD700").sk
        skorLabel.horizontalAlignmentMode = .center
        skorLabel.verticalAlignmentMode   = .center
        skorLabel.position  = CGPoint(x: 0, y: daireYaricap * 0.05)
        skorLabel.zPosition = 2
        daire.addChild(skorLabel)

        daire.run(SKAction.wait(forDuration: 0.3)) { [weak self] in
            self?.skorSayacAnimasyonu(label: skorLabel, hedef: guncelSkor)
        }
        cursor -= daireYaricap      // dairenin alt kenarına in
        cursor -= araKucuk

        // ── 3. "PUAN" ETİKETİ ──────────────────────────────────────────
        cursor -= puanFontH / 2
        let puanLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        puanLabel.text      = "PUAN"
        puanLabel.fontSize  = puanFontH
        puanLabel.fontColor = UIColor.white.withAlphaComponent(0.45).sk
        puanLabel.horizontalAlignmentMode = .center
        puanLabel.verticalAlignmentMode   = .center
        puanLabel.position  = CGPoint(x: 0, y: cursor)
        puanLabel.zPosition = 1
        puanLabel.alpha     = 0
        kart.addChild(puanLabel)
        puanLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.25),
            SKAction.fadeIn(withDuration: 0.20)
        ]))
        cursor -= puanFontH / 2
        cursor -= araBuyuk

        // ── 4. YENİ REKOR veya EN YÜKSEK ──────────────────────────────
        cursor -= rekorFontH / 2
        let rekorY = cursor

        if isYeniRekor {
            let rekorLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            rekorLabel.text      = "YENİ REKOR!"
            rekorLabel.fontSize  = rekorFontH
            rekorLabel.fontColor = UIColor(hex: "#FFD700").sk
            rekorLabel.horizontalAlignmentMode = .center
            rekorLabel.verticalAlignmentMode   = .center
            rekorLabel.position  = CGPoint(x: 0, y: rekorY)
            rekorLabel.zPosition = 1
            rekorLabel.alpha     = 0
            kart.addChild(rekorLabel)
            rekorLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.fadeIn(withDuration: 0.2)
            ]))
            let nabiz = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.0,  duration: 0.55),
                SKAction.scale(to: 1.10, duration: 0.55)
            ]))
            rekorLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.6),
                nabiz
            ]))
        } else {
            let hsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            hsLabel.text      = "EN YÜKSEK: \(guncelRekor)"
            hsLabel.fontSize  = rekorFontH * 0.85
            hsLabel.fontColor = UIColor.white.withAlphaComponent(0.55).sk
            hsLabel.horizontalAlignmentMode = .center
            hsLabel.verticalAlignmentMode   = .center
            hsLabel.position  = CGPoint(x: 0, y: rekorY)
            hsLabel.zPosition = 1
            hsLabel.alpha     = 0
            kart.addChild(hsLabel)
            hsLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.35),
                SKAction.fadeIn(withDuration: 0.25)
            ]))
        }
        cursor -= rekorFontH / 2
        cursor -= araBuyuk

        // ── 5. AYIRICI ÇİZGİ ──────────────────────────────────────────
        let ayiriciY = cursor
        let ayiriciPath = CGMutablePath()
        ayiriciPath.move(to:    CGPoint(x: -kartW * 0.35, y: ayiriciY))
        ayiriciPath.addLine(to: CGPoint(x:  kartW * 0.35, y: ayiriciY))
        let ayirici = SKShapeNode(path: ayiriciPath)
        ayirici.strokeColor = UIColor.white.withAlphaComponent(0.12).sk
        ayirici.lineWidth   = 1
        ayirici.zPosition   = 1
        ayirici.alpha       = 0
        kart.addChild(ayirici)
        ayirici.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.30),
            SKAction.fadeIn(withDuration: 0.20)
        ]))
        cursor -= araBuyuk

        // ── 6. BUTON 1 — TEKRAR OYNA ──────────────────────────────────
        cursor -= btn1H / 2
        let btn1Y = cursor
        overlayButonEkle(
            parent:    kart,
            metin:     "TEKRAR OYNA",
            isim:      "restartBtn",
            renkHex:   "#00C853",
            y:         btn1Y,
            genislik:  kartW * 0.82,
            yukseklik: btn1H,
            gecikme:   0.4
        )
        cursor -= btn1H / 2
        cursor -= btnAra

        // ── 7. BUTON 2 — ANA MENÜ ──────────────────────────────────────
        cursor -= btn2H / 2
        let btn2Y = cursor
        overlayIkincilButonEkle(
            parent:    kart,
            metin:     "Ana Menü",
            isim:      "homeBtn",
            y:         btn2Y,
            genislik:  kartW * 0.65,
            yukseklik: btn2H,
            gecikme:   0.5
        )
        // cursor -= btn2H / 2 + padV  → alt kenar = -(kartH/2) ✓
    }

    // MARK: - Skor Sayaç Animasyonu

    /// Skor etiketi 0'dan hedef değere kademeli olarak artarak gider.
    /// "Sayıyor" hissi oyuncuya skor dramatikliği katar.
    private func skorSayacAnimasyonu(label: SKLabelNode, hedef: Int) {
        guard hedef > 0 else {
            label.text = "0"
            return
        }

        // Her adımda ne kadar artacağı: çok küçükse çok uzun sürer, büyükse hızlı biter
        // Yaklaşık 30 adımda tamamlansın
        let adimBuyuklugu = max(1, hedef / 30)
        var gosterilenDeger = 0

        let sayacEylemi = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.022),
            SKAction.run { [weak label] in
                guard let label = label else { return }
                gosterilenDeger += adimBuyuklugu
                if gosterilenDeger >= hedef {
                    gosterilenDeger = hedef
                    // Hedefe ulaştı — sadece sayaç aksiyonunu durdur, diğer aksiyonlar etkilenmez
                    // removeAllActions() yerine key-based silme: label'a eklenen başka aksiyonlar korunur
                    label.removeAction(forKey: "skorSayac")
                }
                label.text = "\(gosterilenDeger)"
            }
        ]))
        label.run(sayacEylemi, withKey: "skorSayac")
    }

    // MARK: - Birincil Buton

    /// Dolu renkli, glass highlight'lı birincil eylem butonu.
    func overlayButonEkle(parent: SKNode, metin: String, isim: String,
                          renkHex: String, y: CGFloat,
                          genislik: CGFloat, yukseklik: CGFloat,
                          gecikme: Double) {
        let koseBoyutu = yukseklik / 2

        // Gölge
        let golgeRect = CGRect(x: -genislik / 2, y: -yukseklik / 2, width: genislik, height: yukseklik)
        let golge     = SKShapeNode(rect: golgeRect, cornerRadius: koseBoyutu)
        golge.fillColor   = UIColor.black.withAlphaComponent(0.28).sk
        golge.strokeColor = .clear
        golge.position    = CGPoint(x: 0, y: y - yukseklik * 0.06)
        golge.zPosition   = 1
        golge.alpha       = 0
        parent.addChild(golge)

        // Buton
        let btnRect = CGRect(x: -genislik / 2, y: -yukseklik / 2, width: genislik, height: yukseklik)
        let btn     = SKShapeNode(rect: btnRect, cornerRadius: koseBoyutu)
        btn.fillColor   = UIColor(hex: renkHex).sk
        btn.strokeColor = .clear
        btn.name        = isim
        btn.position    = CGPoint(x: 0, y: y)
        btn.zPosition   = 2
        btn.alpha       = 0
        parent.addChild(btn)

        // Üst highlight — glass morphism hissi
        let glassW    = genislik * 0.90
        let glassH    = yukseklik * 0.40
        let glassRect = CGRect(x: -glassW / 2, y: 0, width: glassW, height: glassH)
        let glass     = SKShapeNode(rect: glassRect, cornerRadius: koseBoyutu)
        glass.fillColor   = UIColor.white.withAlphaComponent(0.12).sk
        glass.strokeColor = .clear
        glass.zPosition   = 0.5
        glass.name        = isim
        btn.addChild(glass)

        // Buton yazısı — font boyutu buton yüksekliğine orantılı
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        lbl.text                  = metin
        lbl.fontSize              = yukseklik * 0.42
        lbl.fontColor             = .white
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode   = .center
        lbl.position  = .zero
        lbl.zPosition = 1
        lbl.name      = isim
        btn.addChild(lbl)

        // Metnin butona sığıp sığmadığını kontrol et
        klipla(lbl, maxWidth: genislik * 0.84)

        // Fade in animasyonu — gecikmeli
        let fadeIn = SKAction.sequence([
            SKAction.wait(forDuration: gecikme),
            SKAction.fadeIn(withDuration: 0.25)
        ])
        btn.run(fadeIn)
        golge.run(fadeIn)
    }

    // MARK: - İkincil Buton

    /// Şeffaf arka plan, hafif border — ikincil eylem görünümü.
    private func overlayIkincilButonEkle(parent: SKNode, metin: String, isim: String,
                                          y: CGFloat, genislik: CGFloat, yukseklik: CGFloat,
                                          gecikme: Double) {
        let koseBoyutu = yukseklik / 2

        let btnRect = CGRect(x: -genislik / 2, y: -yukseklik / 2, width: genislik, height: yukseklik)
        let btn     = SKShapeNode(rect: btnRect, cornerRadius: koseBoyutu)
        btn.fillColor   = .clear
        btn.strokeColor = UIColor.white.withAlphaComponent(0.30).sk
        btn.lineWidth   = 1
        btn.name        = isim
        btn.position    = CGPoint(x: 0, y: y)
        btn.zPosition   = 2
        btn.alpha       = 0
        parent.addChild(btn)

        let lbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        lbl.text                  = metin
        lbl.fontSize              = yukseklik * 0.40
        lbl.fontColor             = UIColor.white.withAlphaComponent(0.70).sk
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode   = .center
        lbl.position  = .zero
        lbl.zPosition = 1
        lbl.name      = isim
        btn.addChild(lbl)

        btn.run(SKAction.sequence([
            SKAction.wait(forDuration: gecikme),
            SKAction.fadeIn(withDuration: 0.25)
        ]))
    }

    // MARK: - Dokunma Yönetimi

    func handleOverlayTap(_ node: SKNode) {
        switch node.name {
        case "restartBtn":
            butonBasAnimasyonu(node) { [weak self] in
                HapticManager.impact(.medium)
                self?.restartGame()
            }
        case "homeBtn":
            butonBasAnimasyonu(node) { [weak self] in
                HapticManager.impact(.light)
                self?.goToHome()
            }
        default:
            break
        }
    }

    // MARK: - Yardımcı Fonksiyonlar

    /// Buton press animasyonu: hafifçe küçülür, geri döner, sonra aksiyon tetiklenir.
    private func butonBasAnimasyonu(_ node: SKNode, tamamlanma: @escaping () -> Void) {
        // Dokunulan node veya parent'ı bul — label'a dokunulmuş olabilir
        let hedef: SKNode = {
            if let isim = node.name, let ust = node.parent, ust.name == isim { return ust }
            return node
        }()
        hedef.removeAllActions()
        hedef.run(SKAction.sequence([
            SKAction.scale(to: 0.93, duration: 0.07),
            SKAction.scale(to: 1.00, duration: 0.08),
            SKAction.run(tamamlanma)
        ]))
    }

    /// Label metni butonun sınırını aşıyorsa ölçekle — taşma önleme.
    func klipla(_ lbl: SKLabelNode, maxWidth: CGFloat) {
        guard lbl.frame.width > maxWidth, maxWidth > 0 else { return }
        lbl.setScale(maxWidth / lbl.frame.width)
    }
}
