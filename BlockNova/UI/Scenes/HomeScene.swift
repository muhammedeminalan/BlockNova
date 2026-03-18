// 📁 Scenes/HomeScene.swift
// Uygulama açılışında gösterilen premium ana menü sahnesi.
// Apple Arcade kalitesinde koyu, modern tasarım.
// Tüm boyutlar screenW / screenH üzerinden responsive hesaplanır.

import SpriteKit
import UIKit

// MARK: - HomeScene

final class HomeScene: SKScene, SafeAreaUpdatable {

    // MARK: - Safe Area

    /// Güncel safe area inset'leri — layout hesaplarında kullanılır
    private var safeAreaInsets: UIEdgeInsets = .zero

    // MARK: - Node Referansları (layout güncellemeleri için saklanır)

    /// "BLOCK" yazısı — logo sol parçası
    private var blockLabel: SKLabelNode?
    /// "NOVA" yazısı — logo sağ parçası (cyan)
    private var novaLabel: SKLabelNode?
    /// "Sürdür · Yerleştir · Patlat" alt tagline
    private var taglineLabel: SKLabelNode?

    /// Skor kartı arka plan shape'i
    private var scoreCardNode: SKShapeNode?
    /// "EN YÜKSEK" başlık etiketi
    private var scoreTitleLabel: SKLabelNode?
    /// Skor değeri etiketi
    private var scoreValueLabel: SKLabelNode?
    /// Kartın üstündeki altın çizgi
    private var scoreCardLine: SKShapeNode?

    /// OYNA butonu shape node'u
    private var playButtonNode: SKShapeNode?
    /// OYNA buton etiketi
    private var playButtonLabel: SKLabelNode?

    /// LİDERLİK butonu shape node'u
    private var leaderButtonNode: SKShapeNode?
    /// LİDERLİK buton etiketi
    private var leaderButtonLabel: SKLabelNode?

    /// AYARLAR butonu sprite node'u
    private var settingsButtonNode: SKSpriteNode?
    /// AYARLAR buton etiketi
    private var settingsButtonLabel: SKLabelNode?

    /// Versiyon etiketi
    private var versionLabel: SKLabelNode?

    /// Sahne bir kez kurulsun — safe area değişince sadece layout güncellenir
    private var isSetup = false

    // Ayarlar ekranini yeni scene olarak ac — HomeScene yeniden olusmaz

    // MARK: - Sahne Girişi

    override func didMove(to view: SKView) {
        // Arka plan rengini en koyu lacivert yap — diğer katmanlar üstüne biner
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

    /// GameViewController'dan gelen inset değişikliğini alır, layout'u yeniler
    func updateSafeAreaInsets(_ insets: UIEdgeInsets) {
        safeAreaInsets = insets
        layoutScene()
    }

    // MARK: - Ana Kurulum

    /// Tüm node'ları oluşturur. Sadece bir kez çağrılır.
    private func kurgula() {
        kurgulaArkaplan()
        kurgulaHareketliBloklar()
        kurgulaLogo()
        kurgulaSkorkart()
        kurgulaOynaButonu()
        kurgulaLiderlikButonu()
        kurgulaAyarlarButonu()
        kurgulaVersiyon()
        girisAnimasyonu()
    }

    // MARK: - Arka Plan

    /// İki katmanlı gradient simülasyonu:
    /// Alt katman çok koyu, üst katman biraz daha açık + yarı saydam.
    /// Bu iki ton derinlik ve premium his verir.
    private func kurgulaArkaplan() {
        // Alt gradient katmanı — ekranı tamamen kaplar, koyu ton
        let alt = SKSpriteNode(color: UIColor(hex: "#0f0f2e"), size: CGSize(width: C.screenW, height: C.screenH))
        alt.position  = CGPoint(x: C.screenW / 2, y: C.screenH / 2)
        alt.zPosition = C.zBackground
        alt.alpha     = 0.5  // Biraz saydam: alttaki koyu renk görünsün, karışım gradient etkisi yaratır
        addChild(alt)
    }

    // MARK: - Hareketli Blok Arka Planı

    /// 22 adet küçük yuvarlak kare — yavaş yukarı kayarak sonsuz döngüde hareket eder.
    /// Alpha düşük tutulur: dikkat çekmeden canlılık katar.
    private func kurgulaHareketliBloklar() {
        // Oyunun kendi blok renkleri kullanılır — tema bütünlüğü için
        let renkler: [UIColor] = [
            C.colorSingle, C.colorH2, C.colorH3,
            C.colorV2,     C.colorV3, C.colorSquare,
            C.colorL,      C.colorJ,  C.colorT,
            C.colorS,      C.colorZ,
            C.colorH4,     C.colorV4, C.colorRect2x3
        ]

        for i in 0..<22 {
            // Her blok rastgele boyut — 28...52 arası
            let boyut = CGFloat.random(in: 28...52)
            // Rengi döngüsel seç — her renk birden fazla blokta kullanılabilir
            let renk  = renkler[i % renkler.count].withAlphaComponent(CGFloat.random(in: 0.12...0.22))

            let blok = SKSpriteNode(color: renk.sk, size: CGSize(width: boyut, height: boyut))
            // Yuvarlak görünüm: SKSpriteNode'un köşelerini yumuşatmak için
            // maskNode ile yuvarlatma yerine küçük overlay tekniği — çözüm: texture yok,
            // basit çözüm olarak alpha blend ile köşe hissi verilir (bloklar küçük ve uzakta)
            blok.zPosition = C.zBackground + 0.5

            // Ekrana rastgele dağıt — hem X hem Y tamamen rasgele
            let baslangicX = CGFloat.random(in: 0...C.screenW)
            let baslangicY = CGFloat.random(in: -C.screenH * 0.1 ... C.screenH * 1.1)
            blok.position  = CGPoint(x: baslangicX, y: baslangicY)

            addChild(blok)

            // Yukarı hareket: yavaş, 12-22 saniyede ekranı baştan sona geçer
            let yukariHareket = SKAction.moveBy(x: 0, y: C.screenH * 1.2, duration: Double.random(in: 12...22))
            // Ekran üstüne çıkınca anında alta sıfırla — kesintisiz döngü
            let sifirla        = SKAction.moveBy(x: 0, y: -C.screenH * 1.2, duration: 0)
            let dongü          = SKAction.repeatForever(SKAction.sequence([yukariHareket, sifirla]))
            blok.run(dongü)

            // Hafif sallanma rotasyonu — robotik değil, organik his
            let donusMiktari = CGFloat.random(in: -0.3...0.3)
            let donus        = SKAction.rotate(byAngle: .pi * donusMiktari, duration: Double.random(in: 8...16))
            blok.run(SKAction.repeatForever(SKAction.sequence([donus, donus.reversed()])))
        }
    }

    // MARK: - Logo

    /// "BLOCK NOVA" iki ayrı label yan yana.
    /// "BLOCK" sağa hizalı, "NOVA" sola hizalı — ikisi ekran ortasında buluşur.
    /// Font boyutu min(screenW, screenH) ile hesaplanır: dar veya geniş cihazda taşmaz.
    private func kurgulaLogo() {
        // "BLOCK" — horizontalAlignmentMode .left: toplam genişlik hesaplanacağı için sol pivot kullanılır
        let block = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        block.text                    = "BLOCK"
        block.fontSize                = logoFontBoyutu()
        block.fontColor               = .white
        block.horizontalAlignmentMode = .left    // Sol kenar pivot — toplam genişlik ile ortalanır
        block.verticalAlignmentMode   = .baseline
        block.zPosition               = C.zUI
        block.alpha                   = 0
        block.name                    = "logoBlock"
        addChild(block)
        blockLabel = block

        // "NOVA" — horizontalAlignmentMode .left: metnin sol kenarı pivot noktasında
        let nova = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nova.text                    = "NOVA"
        nova.fontSize                = logoFontBoyutu()
        nova.fontColor               = UIColor(hex: "#00D4FF")
        nova.horizontalAlignmentMode = .left     // Sol kenar pivot — toplam genislik ile ortalanir
        nova.verticalAlignmentMode   = .baseline
        nova.zPosition               = C.zUI
        nova.alpha                   = 0
        nova.name                    = "logoNova"
        addChild(nova)
        novaLabel = nova

        // Tagline — "Sürdür · Yerleştir · Patlat"
        let tagline = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tagline.text                    = "Sürdür · Yerleştir · Patlat"
        tagline.fontSize                = taglineFontBoyutu()
        tagline.fontColor               = UIColor.white.withAlphaComponent(0.5)
        tagline.horizontalAlignmentMode = .center
        tagline.verticalAlignmentMode   = .baseline
        tagline.zPosition               = C.zUI
        tagline.alpha                   = 0
        addChild(tagline)
        taglineLabel = tagline
    }

    // MARK: - Responsive Font Hesaplamaları

    /// Logo font boyutu: screenW ve screenH'nin küçüğünün %12'si.
    /// Bu oran iPhone SE'den iPad'e kadar tüm cihazlarda güvenli sığar.
    private func logoFontBoyutu() -> CGFloat {
        return min(C.screenW, C.screenH) * 0.12
    }

    /// Tagline font boyutu: logo ile orantılı, çok küçük veya büyük olmaz.
    private func taglineFontBoyutu() -> CGFloat {
        return min(C.screenW, C.screenH) * 0.032
    }

    // MARK: - Skor Kartı

    /// Altın çizgi + koyu panel + başlık + değer.
    /// Önceki oyundan kalan en yüksek skoru gösterir.
    /// Başlık üstte küçük, değer altta büyük — dikey düzen, taşma yok.
    private func kurgulaSkorkart() {
        let kartW = C.screenW * 0.72
        let kartH = C.screenH * 0.13  // Yeterince yüksek: büyük rakam + başlık sığsın

        // Kart arka planı: rounded rect shape
        let kartRect = CGRect(x: -kartW / 2, y: -kartH / 2, width: kartW, height: kartH)
        let kart     = SKShapeNode(rect: kartRect, cornerRadius: 20)
        kart.fillColor   = UIColor(hex: "#1a1a3e").withAlphaComponent(0.85).sk
        kart.strokeColor = UIColor.white.withAlphaComponent(0.08).sk
        kart.lineWidth   = 1
        kart.zPosition   = C.zUI
        kart.alpha       = 0  // Giriş animasyonu
        addChild(kart)
        scoreCardNode = kart

        // Kartın üstündeki altın ince çizgi — kartın top edge'inde
        let cizgiPath = CGMutablePath()
        cizgiPath.move(to:    CGPoint(x: -kartW / 2, y: kartH / 2))
        cizgiPath.addLine(to: CGPoint(x:  kartW / 2, y: kartH / 2))
        let cizgi     = SKShapeNode(path: cizgiPath)
        cizgi.strokeColor = UIColor(hex: "#FFD700").withAlphaComponent(0.5).sk
        cizgi.lineWidth   = 1.5
        cizgi.zPosition   = C.zUI + 0.1
        kart.addChild(cizgi)
        scoreCardLine = cizgi

        // "EN YÜKSEK" başlık — kartın üst bölümünde ortalı, küçük altın yazı
        let baslik = SKLabelNode(fontNamed: "AvenirNext-Medium")
        baslik.text                    = "EN YÜKSEK"
        baslik.fontSize                = C.screenH * 0.016
        baslik.fontColor               = UIColor(hex: "#FFD700").sk
        baslik.horizontalAlignmentMode = .center
        baslik.verticalAlignmentMode   = .baseline
        // Kartın dikey ortasının biraz üstüne — başlık üstte, rakam altta
        baslik.position  = CGPoint(x: 0, y: kartH * 0.12)
        baslik.zPosition = 1
        kart.addChild(baslik)
        scoreTitleLabel = baslik

        // Skor değeri — başlığın altında, ortalı, büyük beyaz rakam
        let hs = CloudManager.shared.loadHighScore()
        let deger = SKLabelNode(fontNamed: "AvenirNext-Bold")
        deger.text                    = "\(hs)"
        deger.fontSize                = C.screenH * 0.042
        deger.fontColor               = .white
        deger.horizontalAlignmentMode = .center
        deger.verticalAlignmentMode   = .top
        // Başlığın hemen altına yerleşir — dikey hizalama ile taşma önlenir
        deger.position  = CGPoint(x: 0, y: kartH * 0.08)
        deger.zPosition = 1
        kart.addChild(deger)
        scoreValueLabel = deger
    }

    // MARK: - OYNA Butonu

    /// Büyük yeşil oval buton — en belirgin eylem çağrısı.
    /// Üstünde beyaz highlight ile cam efekti.
    private func kurgulaOynaButonu() {
        let btnW = C.screenW * 0.72
        let btnH = C.screenH * 0.075

        let rect = CGRect(x: -btnW / 2, y: -btnH / 2, width: btnW, height: btnH)
        let btn  = SKShapeNode(rect: rect, cornerRadius: btnH / 2)
        btn.fillColor   = UIColor(hex: "#00C853").sk  // Parlak yeşil
        btn.strokeColor = .clear
        btn.zPosition   = C.zUI
        btn.name        = "oynaBtn"
        btn.alpha       = 0  // Giriş animasyonu
        addChild(btn)
        playButtonNode = btn

        // Üst beyaz highlight — glass morphism hissi
        // Butonun üst yarısını kaplar, yarı saydam
        let glassW = btnW * 0.92
        let glassH = btnH * 0.42
        let glassRect  = CGRect(x: -glassW / 2, y: 0, width: glassW, height: glassH)
        let glassShape = SKShapeNode(rect: glassRect, cornerRadius: btnH / 2)
        glassShape.fillColor   = UIColor.white.withAlphaComponent(0.15).sk
        glassShape.strokeColor = .clear
        glassShape.zPosition   = 0.5
        glassShape.name        = "oynaBtn"  // Dokunma tespiti için aynı isim
        btn.addChild(glassShape)

        // "OYNA" yazısı
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        lbl.text                  = "OYNA"
        lbl.fontSize              = C.screenH * 0.028
        lbl.fontColor             = .white
        lbl.verticalAlignmentMode = .center
        lbl.zPosition             = 1
        lbl.name                  = "oynaBtn"  // Dokunma tespiti için aynı isim
        btn.addChild(lbl)
        playButtonLabel = lbl
    }

    // MARK: - LİDERLİK Butonu

    /// Şeffaf arka plan, cyan border — ikincil eylem görünümü.
    /// Emoji kullanılmaz: SKLabelNode'da emoji+font karışımı render sorununa yol açar.
    private func kurgulaLiderlikButonu() {
        let btnW = C.screenW * 0.60
        let btnH = C.screenH * 0.062

        let rect = CGRect(x: -btnW / 2, y: -btnH / 2, width: btnW, height: btnH)
        let btn  = SKShapeNode(rect: rect, cornerRadius: btnH / 2)
        btn.fillColor   = UIColor(hex: "#00D4FF").withAlphaComponent(0.08).sk  // Çok hafif cyan dolgu
        btn.strokeColor = UIColor(hex: "#00D4FF").sk  // Cyan border
        btn.lineWidth   = 1.5
        btn.zPosition   = C.zUI
        btn.name        = "liderlikBtn"
        btn.alpha       = 0  // Giriş animasyonu
        addChild(btn)
        leaderButtonNode = btn

        // "LIDERLIK TABLOSU" — sade metin, taşma yok
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text                  = "LIDERLIK TABLOSU"
        lbl.fontSize              = C.screenH * 0.020
        lbl.fontColor             = UIColor(hex: "#00D4FF").sk
        lbl.verticalAlignmentMode = .center
        lbl.zPosition             = 1
        lbl.name                  = "liderlikBtn"  // Dokunma tespiti için aynı isim
        btn.addChild(lbl)
        leaderButtonLabel = lbl
    }

    // MARK: - AYARLAR Butonu

    /// Küçük, minimal ayarlar butonu — liderlik butonunun altında
    private func kurgulaAyarlarButonu() {
        let btnW = C.screenW * 0.32
        let btnH = C.screenH * 0.045

        let btn = SKSpriteNode(color: .clear, size: CGSize(width: btnW, height: btnH))
        btn.zPosition = C.zUI
        btn.name = "ayarlarBtn"
        btn.alpha = 0  // Giriş animasyonu
        addChild(btn)
        settingsButtonNode = btn

        // Daha belirgin görünüm için hafif arka plan ve border
        let rect = CGRect(x: -btnW / 2, y: -btnH / 2, width: btnW, height: btnH)
        let outline = SKShapeNode(rect: rect, cornerRadius: btnH / 2)
        outline.fillColor = UIColor.white.withAlphaComponent(0.06).sk
        outline.strokeColor = UIColor.white.withAlphaComponent(0.18).sk
        outline.lineWidth = 1
        outline.zPosition = 0.5
        outline.name = "ayarlarBtn"
        btn.addChild(outline)

        let lbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        lbl.text = "Ayarlar"
        lbl.fontSize = C.screenH * 0.019
        lbl.fontColor = UIColor(white: 1, alpha: 0.75)
        lbl.verticalAlignmentMode = .center
        lbl.zPosition = 1
        lbl.name = "ayarlarBtn"
        btn.addChild(lbl)
        settingsButtonLabel = lbl
    }

    // MARK: - Versiyon Etiketi

    /// Ekranın en altında, neredeyse görünmez — sadece çok yakın bakılınca fark edilir
    private func kurgulaVersiyon() {
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        lbl.text      = "v1.0"
        lbl.fontSize  = C.screenH * 0.014
        lbl.fontColor = UIColor.white.withAlphaComponent(0.2)
        lbl.zPosition = C.zUI
        addChild(lbl)
        versionLabel = lbl
    }

    // MARK: - Layout

    /// Tüm node'ların pozisyonunu safe area + ekran boyutuna göre günceller.
    /// Hem ilk kurulumda hem safe area değişiminde çağrılır.
    private func layoutScene() {
        C.updateSceneSize(size)

        // Safe area sınırları — notch, home indicator ve Dynamic Island'ı hesaba katar
        // safeTop/safeBottom: panellerin bu sınırları aşmaması için kullanılır
        let safeBottom = safeAreaInsets.bottom
        let safeTop    = safeAreaInsets.top
        // Güvenli kullanılabilir alan: safe area içindeki tam yükseklik
        let safeH      = C.screenH - safeTop - safeBottom
        // Güvenli alanın alt referans noktası (SpriteKit: 0 = ekranın altı)
        let safeMinY   = safeBottom

        // --- LOGO ---
        // Güvenli alanın üst %88'i — safe area'ya göre hesaplanır, notch'tan etkilenmez
        let logoY      = safeMinY + safeH * 0.88
        let spacing    = C.screenW * 0.036  // Eski görsel araligi koru: 2 * yariBosluk
        let fontBoyutu = logoFontBoyutu()

        if let block = blockLabel, let nova = novaLabel {
            // Iki label'i toplam genisligine gore ortala — kayma olmaz
            block.fontSize = fontBoyutu
            nova.fontSize  = fontBoyutu
            block.horizontalAlignmentMode = .left
            nova.horizontalAlignmentMode  = .left

            let blockW = block.frame.width
            let novaW  = nova.frame.width
            let totalW = blockW + novaW + spacing
            let startX = C.screenW / 2 - totalW / 2

            block.position = CGPoint(x: startX, y: logoY)
            nova.position  = CGPoint(x: startX + blockW + spacing, y: logoY)
        }

        // Tagline: logodan font boyutuyla orantılı mesafe aşağıda
        if let tagline = taglineLabel {
            tagline.fontSize = taglineFontBoyutu()
            tagline.position = CGPoint(x: C.screenW / 2, y: logoY - fontBoyutu * 1.15)
        }

        // --- SKOR KARTI ---
        // Güvenli alanın %62'si — logo ile butonlar arasında dengeli konum
        if let kart = scoreCardNode {
            kart.position = CGPoint(x: C.screenW / 2, y: safeMinY + safeH * 0.62)
        }

        // --- OYNA BUTONU ---
        // Güvenli alanın %45'i — skor kartının altında, rahat tıklanabilir bölge
        if let btn = playButtonNode {
            btn.position = CGPoint(x: C.screenW / 2, y: safeMinY + safeH * 0.45)
        }

        // --- LİDERLİK BUTONU ---
        // OYNA butonunun altında — iki buton arasında yeterli boşluk
        if let btn = leaderButtonNode {
            btn.position = CGPoint(x: C.screenW / 2, y: safeMinY + safeH * 0.33)
        }

        // --- AYARLAR BUTONU ---
        // Liderlik butonunun altında — daha küçük ve minimal
        if let btn = settingsButtonNode {
            btn.position = CGPoint(x: C.screenW / 2, y: safeMinY + safeH * 0.23)
        }

        // --- VERSİYON ---
        // Güvenli alanın en altında — home indicator çakışmaz
        if let lbl = versionLabel {
            lbl.position = CGPoint(x: C.screenW / 2, y: safeMinY + safeH * 0.04)
        }
    }

    // MARK: - Giriş Animasyonu

    /// Ekran açılınca elementler sırayla görünür.
    /// Önce logo yukarıdan düşer, sonra diğerleri fade ile belirir.
    private func girisAnimasyonu() {
        // Logo: 40pt yukarıdan düşer, eş zamanlı fade in
        // Önce Y'yi 40 arttır (yukarıda başlasın), sonra aşağı indir
        let logoDus = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 40, duration: 0),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -40, duration: 0.5),
                SKAction.fadeIn(withDuration: 0.5)
            ])
        ])
        blockLabel?.run(logoDus)
        novaLabel?.run(logoDus)
        taglineLabel?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.fadeIn(withDuration: 0.5)
        ]))

        // Skor kartı: 0.2 saniye gecikme, 0.4 saniye fade
        scoreCardNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.4)
        ]))

        // OYNA butonu: 0.4 saniye sonra fade + scale
        // Küçükten büyüğe büyüyerek belirir — dikkat çeker
        playButtonNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.35),
                SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0),
                    SKAction.scale(to: 1.0, duration: 0.35)
                ])
            ])
        ]))

        // LİDERLİK butonu: en son belirir
        leaderButtonNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.55),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        // AYARLAR butonu: liderlikten sonra kısa gecikmeyle
        settingsButtonNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.62),
            SKAction.fadeIn(withDuration: 0.25)
        ]))

        // Versiyon: en son, sessizce
        versionLabel?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.fadeIn(withDuration: 0.4)
        ]))
    }

    // MARK: - Dokunma Algılama

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node     = atPoint(location)

        // OYNA butonuna basıldı
        if node.name == "oynaBtn" || node.parent?.name == "oynaBtn" {
            HapticManager.impact(.medium)

            // Butonu bul: node veya parent SKShapeNode olabilir
            let hedefNode: SKNode = (node.name == "oynaBtn") ? node : (node.parent ?? node)

            // Bastı hissi: hafifçe küçül, geri dön, sonra sahneye geç
            let basAnimasyon = SKAction.sequence([
                SKAction.scale(to: 0.95, duration: 0.08),
                SKAction.scale(to: 1.0,  duration: 0.08)
            ])
            hedefNode.run(basAnimasyon) { [weak self] in
                guard let self = self else { return }
                let scene       = GameScene(size: self.size)
                scene.scaleMode = self.scaleMode
                self.view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
            }
        }

        // LİDERLİK butonuna basıldı
        if node.name == "liderlikBtn" || node.parent?.name == "liderlikBtn" {
            HapticManager.impact(.light)

            // Border: basınca beyazlaşır, geri döner — tıklandığına dair görsel feedback
            if let btn = leaderButtonNode {
                let beyazlas  = SKAction.run { btn.strokeColor = SKColor.white }
                let gereDon    = SKAction.run { btn.strokeColor = UIColor(hex: "#00D4FF").sk }
                btn.run(SKAction.sequence([beyazlas, SKAction.wait(forDuration: 0.18), gereDon]))
            }

            guard let vc = self.view?.window?.rootViewController else { return }
            GameManager.showLeaderboard(from: vc)
        }

        // AYARLAR butonuna basıldı — HomeScene yeniden olusmaz, geri donuste ayni instance kullanilir
        if node.name == "ayarlarBtn" || node.parent?.name == "ayarlarBtn" {
            HapticManager.impact(.light)
            let settings = SettingsScene(size: size)
            settings.scaleMode = scaleMode
            settings.homeScene = self
            view?.presentScene(settings, transition: SKTransition.push(with: .left, duration: 0.3))
        }
    }

}
