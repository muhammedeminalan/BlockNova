// 📁 Scenes/GameScene.swift
// Oyunun ana sahnesi. Tum bilesenleri koordine eder:
// GridNode, alt tepsi parcalari, surukle-birak mekanizmasi, skor UI, oyun sonu overlay.
//
// SURUKLEME TASARIMI:
// - touchesMoved'da SKAction KULLANILMAZ: position dogrudan atanir — akicilik icin
// - beginDrag'de buildCells CAGIRILMAZ: gesture lock onleme
// - clearHighlight sadece highlight edilen hucreleri sifirlar: performans icin
//
// LAYOUT (tumu responsive):
// - Ust panel:  safe area icinde en ustte, topPanelHeight yuksekliginde
// - Grid:       ust ve alt panel arasinda, safe area icinde dikey ortalanmis
// - Alt panel:  safe area icinde en altta, bottomPanelHeight yuksekliginde

import SpriteKit
import UIKit

// MARK: - GameScene
final class GameScene: SKScene, SafeAreaUpdatable {

    // MARK: - Safe Area Durumu

    /// Scene icin guncel safe area inset'leri — panel ve grid hesaplari icin zorunlu
    private var safeAreaInsets: UIEdgeInsets = .zero
    /// Scene icinde kullanilabilir guvenli alan — tum yerlesimler buna gore yapilir
    private var safeAreaFrame: CGRect = .zero
    /// Grid'in efektif merkez Y degeri — safe area duzeltmesi ile guncellenir
    private var effectiveGridCenterY: CGFloat = C.gridCenterY

    // MARK: - Bilesenler

    /// 8x8 oyun izgarasi
    private var gridNode: GridNode!
    /// Oyun mantigi ve skor yoneticisi
    private var manager: GameManager!
    /// Alt tepsi — 3 parca slotu, nil = bos slot
    private var trayPieces: [PieceNode?] = [nil, nil, nil]
    /// Sekil torbasi — ayni 3-4 seklin surekli gelmesini onler
    private var shapeBag: [BlockShape] = []

    // MARK: - Ust Panel Node'lari

    /// Ust panel arka plan node'u — safe area degisince konumu guncellenir
    private var topPanelNode: SKSpriteNode?
    /// Ust panel alt ayirici cizgisi — panel sinirini belirtir
    private var topPanelSeparator: SKShapeNode?
    /// Skor baslik etiketi — panel icinde konumlanir
    private var scoreTitleLabel: SKLabelNode?
    /// Skor deger etiketi — panel icinde konumlanir
    private var scoreValueLabel: SKLabelNode!
    /// Rekor baslik etiketi — panel icinde konumlanir
    private var highScoreTitleLabel: SKLabelNode?
    /// Rekor deger etiketi — panel icinde konumlanir
    private var highScoreValueLabel: SKLabelNode!

    // MARK: - Alt Panel Node'lari

    /// Alt panel arka plan node'u — safe area bottom'a sabitlenir
    private var bottomPanelNode: SKSpriteNode?
    /// Alt panel ust ayirici cizgisi — panel sinirini belirtir
    private var bottomPanelSeparator: SKShapeNode?

    // MARK: - Oyun Sonu Overlay

    /// Oyun sonu overlay — gosterilince eklenir, yeniden baslatinca kaldirilir
    private var overlayNode: SKNode?

    // MARK: - Surukleme Durumu

    /// Aktif suruklenen parca — nil: surukleme yok
    private var draggedPiece: PieceNode?
    /// Parmak ile parca merkezi arasindaki fark + yukari offset
    /// Bir kez hesaplanir, surukleme boyunca sabit kalir
    private var dragOffset: CGPoint = .zero
    /// Surukleme baslamadan once parcanin pozisyonu — iptal edilince buraya doner
    private var originalPosition: CGPoint = .zero
    /// Son highlight edilen anchor hucre — gereksiz is yapmamak icin
    private var lastHighlightAnchor: (row: Int, col: Int)? = nil

    // MARK: - Sahne Kurulumu

    override func didMove(to view: SKView) {
        // Arka plan sabit renk — kontrast icin koyu ton
        backgroundColor = C.bgColor.sk

        // Safe area bilgisini view'dan al — GameViewController guncellemeden once fallback olur
        safeAreaInsets = view.safeAreaInsets

        // Model ve UI kurulum sirasini sabit tut — bagimliliklari net tutar
        setupManager()
        setupGrid()
        setupTopPanel()
        setupBottomPanel()
        dealNewPieces()

        // Ilk layout'u safe area'ya gore yap — paneller dogru konuma gelsin
        layoutScene()
    }

    // MARK: - Safe Area Guncelleme

    /// GameViewController'dan gelen safe area inset'lerini alir ve layout'u yeniler
    func updateSafeAreaInsets(_ insets: UIEdgeInsets) {
        // Insets saklanir — layout hesaplarinin temel girdisi
        safeAreaInsets = insets
        // Safe area degisince tum node'lar yeniden konumlanir
        layoutScene()
    }

    // MARK: - Layout

    /// Tum node'lari safe area'ya gore yeniden konumlandirir
    private func layoutScene() {
        // Scene size degisimi olursa merkezi hesaplar guncellensin
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

        // Kullanilabilir yukseklik: paneller haric kalan alan
        let usableHeight = max(0, safeAreaFrame.height - C.topPanelHeight - C.bottomPanelHeight)
        // Grid merkezi safe area icinde, paneller arasinda ortalanir
        effectiveGridCenterY = safeAreaFrame.minY + C.bottomPanelHeight + usableHeight / 2

        // Grid konumu safe area merkezine gore guncellenir
        gridNode.position = CGPoint(x: safeAreaFrame.midX, y: effectiveGridCenterY)

        // Ust panel konumu ve icindeki etiketler safe area top'a gore ayarlanir
        layoutTopPanel()

        // Alt panel konumu safe area bottom'a gore ayarlanir
        layoutBottomPanel()

        // Alt tepsideki parcalar safe area bottom'a gore guncellenir
        layoutTrayPieces()
    }

    /// Ust panelin konumunu ve icindeki etiketleri safe area top'a gore ayarlar
    private func layoutTopPanel() {
        // Panel yukarida, safe area ust sinirina sabitlenir
        let panelTopY = safeAreaFrame.maxY

        // Panel node'u yoksa is yapma — kurulumda olusmustu
        guard let panel = topPanelNode else { return }
        panel.size = CGSize(width: C.screenW, height: C.topPanelHeight)
        panel.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        panel.position = CGPoint(x: C.screenW / 2, y: panelTopY)

        // Ayirici cizgiyi panel altina sabitle
        if let sep = topPanelSeparator {
            updateSeparator(sep, y: panelTopY - C.topPanelHeight)
        }

        // Panel icindeki Y hesaplari panelTopY referansli olmali — safe area etkisi icin
        let scoreTitleY = panelTopY - C.topPanelHeight * 0.32
        let scoreValueY = panelTopY - C.topPanelHeight * 0.72

        // Baslik ve skor etiketlerini guncelle
        if let scoreTitleLabel {
            scoreTitleLabel.fontSize = C.screenH * 0.016
            scoreTitleLabel.position = CGPoint(x: C.screenW * 0.28, y: scoreTitleY)
        }
        scoreValueLabel.fontSize = C.screenH * 0.038
        scoreValueLabel.position = CGPoint(x: C.screenW * 0.28, y: scoreValueY)

        if let highScoreTitleLabel {
            highScoreTitleLabel.fontSize = C.screenH * 0.016
            highScoreTitleLabel.position = CGPoint(x: C.screenW * 0.72, y: scoreTitleY)
        }
        highScoreValueLabel.fontSize = C.screenH * 0.038
        highScoreValueLabel.position = CGPoint(x: C.screenW * 0.72, y: scoreValueY)
    }

    /// Alt panelin konumunu safe area bottom'a gore ayarlar
    private func layoutBottomPanel() {
        // Panel altta, safe area alt sinirina sabitlenir
        let panelBottomY = safeAreaFrame.minY

        // Panel node'u yoksa is yapma — kurulumda olusmustu
        guard let panel = bottomPanelNode else { return }
        panel.size = CGSize(width: C.screenW, height: C.bottomPanelHeight)
        panel.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        panel.position = CGPoint(x: C.screenW / 2, y: panelBottomY)

        // Ayirici cizgiyi panel ustune sabitle
        if let sep = bottomPanelSeparator {
            updateSeparator(sep, y: panelBottomY + C.bottomPanelHeight)
        }
    }

    /// Alt tepsideki parcalarin pozisyonlarini safe area bottom'a gore gunceller
    private func layoutTrayPieces() {
        // Slotlarin genisligini scene genisligine gore ayarla
        let slotWidth = C.screenW / 3
        // Tepsi ortasi safe area bottom + panel yuksekligi ile hesaplanir
        let midY = safeAreaFrame.minY + C.bottomPanelHeight * 0.50

        // Var olan parcalari yeni slot merkezlerine tasi
        for (i, piece) in trayPieces.enumerated() {
            guard let piece else { continue }

            // Suruklenen parcayi elle hizalama — dokunus akiciligi bozulmasin
            if piece === draggedPiece { continue }

            let targetX = slotWidth * CGFloat(i) + slotWidth / 2
            let targetPosition = CGPoint(x: targetX, y: midY)
            piece.position = targetPosition
            piece.homePosition = targetPosition
        }
    }

    // MARK: - Manager

    private func setupManager() {
        // Manager oyun mantigi icin tek kaynak — yeni instance baslangicta kurulur
        manager = GameManager()
        // Delegate ile UI guncellemeleri scene tarafinda yapilir
        manager.delegate = self
    }

    // MARK: - Grid

    /// GridNode'u olusturur ve responsive hesaba gore ekrana yerlestirir.
    /// Grid tam olarak ust ve alt panel arasinda dikey ortalanir.
    private func setupGrid() {
        // Grid tek node olarak kurulur — hizli ve temiz
        gridNode = GridNode()
        gridNode.delegate = self
        // Ilk konum layoutScene icinde guncellenecek
        gridNode.position = CGPoint(x: C.gridCenterX, y: effectiveGridCenterY)
        gridNode.zPosition = C.zGrid
        addChild(gridNode)
    }

    // MARK: - Ust Panel

    /// Skor ve rekor gosterimi — safe area top icinde sabit panel
    private func setupTopPanel() {
        // Panel arka plani
        let panel = SKSpriteNode(
            color: C.panelColor.sk,
            size: CGSize(width: C.screenW, height: C.topPanelHeight)
        )
        panel.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        panel.zPosition = C.zPanel
        addChild(panel)
        topPanelNode = panel

        // Alt ayirici cizgisi — panel ve grid ayrimi belirgin olsun
        let sep = makeSeparator(y: C.screenH - C.topPanelHeight)
        addChild(sep)
        topPanelSeparator = sep

        // --- SOL: Mevcut skor ---
        let scoreTitle = makeLabel("SKOR", font: C.fontMedium,
                                   size: C.screenH * 0.016, color: C.accentColor.sk)
        scoreTitle.horizontalAlignmentMode = .center
        scoreTitle.zPosition = C.zUI
        addChild(scoreTitle)
        scoreTitleLabel = scoreTitle

        scoreValueLabel = makeLabel("0", font: C.fontBold,
                                    size: C.screenH * 0.038, color: .white)
        scoreValueLabel.horizontalAlignmentMode = .center
        scoreValueLabel.zPosition = C.zUI
        addChild(scoreValueLabel)

        // --- SAG: En yuksek skor ---
        let hsTitle = makeLabel("EN YUKSEK", font: C.fontMedium,
                                size: C.screenH * 0.016, color: C.accentColor.sk)
        hsTitle.horizontalAlignmentMode = .center
        hsTitle.zPosition = C.zUI
        addChild(hsTitle)
        highScoreTitleLabel = hsTitle

        highScoreValueLabel = makeLabel("\(manager.highScore)", font: C.fontBold,
                                        size: C.screenH * 0.038, color: C.goldColor.sk)
        highScoreValueLabel.horizontalAlignmentMode = .center
        highScoreValueLabel.zPosition = C.zUI
        addChild(highScoreValueLabel)
    }

    // MARK: - Alt Panel

    /// Tepsi arka plani — parca slotlari icin koyu panel
    private func setupBottomPanel() {
        let panel = SKSpriteNode(
            color: C.panelColor.sk,
            size: CGSize(width: C.screenW, height: C.bottomPanelHeight)
        )
        panel.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        panel.zPosition = C.zPanel
        addChild(panel)
        bottomPanelNode = panel

        // Ust ayirici cizgisi — panelin ust siniri net olsun
        let sep = makeSeparator(y: C.bottomPanelHeight)
        addChild(sep)
        bottomPanelSeparator = sep
    }

    // MARK: - Parca Dagitma

    /// Alt tepsiye 3 yeni rastgele parca yerlestirir.
    /// Mevcut parcalar zaten kaldirilmis olmali.
    private func dealNewPieces() {
        // Sekil torbasindan 3 yeni sekil cek — dagilim daha adil olur
        let shapes = [drawShapeFromBag(), drawShapeFromBag(), drawShapeFromBag()]
        let slotWidth = C.screenW / 3
        let midY = safeAreaFrame.minY + C.bottomPanelHeight * 0.50  // Panel dikey ortasi

        for (i, shape) in shapes.enumerated() {
            // Yeni parca olustur — her tur farkli sekil gelsin
            let piece = PieceNode(shape: shape)
            piece.slotIndex = i
            let targetX = slotWidth * CGFloat(i) + slotWidth / 2
            piece.position = CGPoint(x: targetX, y: midY)
            piece.homePosition = piece.position
            piece.zPosition = C.zPiece
            piece.alpha = 0
            addChild(piece)
            trayPieces[i] = piece

            // FadeIn animasyonu — slide yerine: slide animasyonu kasa yapabilir
            let delay = Double(i) * 0.07
            piece.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.20)
            ]))
        }
    }

    // MARK: - Sekil Torbasi

    /// Torbadan bir sekil ceker — bitince yeniden karistirir
    private func drawShapeFromBag() -> BlockShape {
        // Torba azaldiysa tum sekilleri yeniden karistir
        if shapeBag.count < 3 {
            shapeBag = BlockShape.all.shuffled()
        }
        // Ilk elemani cek — sonraki cekislerde tekrar gelme azalir
        return shapeBag.removeFirst()
    }

    // MARK: - TOUCH BEGIN

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Oyun sonu overlay aciksa sadece buton kontrolu
        if manager.state == .gameOver {
            guard let touch = touches.first else { return }
            handleOverlayTap(atPoint(touch.location(in: self)))
            return
        }
        guard manager.state == .playing,
              let touch = touches.first else { return }

        let location = touch.location(in: self)
        let hitNode = atPoint(location)

        // PieceNode'u bul — child'a (SKSpriteNode) dokunulmus olabilir
        // Hiyerarsiyi yukari tarayarak en fazla 3 seviye yukariya bakiyoruz
        var piece: PieceNode? = nil
        if let p = hitNode as? PieceNode { piece = p }
        else if let p = hitNode.parent as? PieceNode { piece = p }
        else if let p = hitNode.parent?.parent as? PieceNode { piece = p }

        // Tepside olan bir parca mi? Sahnenin baska node'lari secilmesin
        guard let selectedPiece = piece,
              trayPieces.contains(where: { $0 === selectedPiece }) else { return }

        draggedPiece = selectedPiece
        originalPosition = selectedPiece.position

        // dragOffset: X ekseninde parmak konumunu koru, Y ekseninde sabit yukari kaldir
        // Bu sayede parca parmagin altinda kalmaz, her cihazda net gorunur
        dragOffset = CGPoint(
            x: selectedPiece.position.x - location.x,
            y: C.dragOffsetY
        )

        // Surukleme baslar baslamaz parcayi yeni hedefe tasi — gecikme hissini kaldir
        let immediatePosition = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        selectedPiece.position = immediatePosition

        // Highlight dogru konumdan baslasin diye onceki anchor'i sifirla
        lastHighlightAnchor = nil

        // beginDrag: scale up, zPosition → on plan
        // buildCells CAGIRILMAZ — touch event ortasinda node yaratma gesture lock yapar
        selectedPiece.beginDrag()

        // Ilk frame'de highlight guncelle — gorsel ve mantik senkron olsun
        updateHighlight(for: selectedPiece)
    }

    // MARK: - TOUCH MOVE

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let piece = draggedPiece else { return }

        let location = touch.location(in: self)

        // DOGRUDAN position atamasi — SKAction kullanilmaz
        // SKAction gecikme yaratir ve gesture pipeline'i mesgul eder
        piece.position = CGPoint(
            x: location.x + dragOffset.x,
            y: location.y + dragOffset.y
        )

        // Grid highlight guncelleme — sadece renk degisir, hafif ve hizli
        updateHighlight(for: piece)
    }

    // MARK: - TOUCH END

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Overlay aciksa touchesBegan'da islenir, buraya dusmesin
        if manager.state == .gameOver { return }
        guard let touch = touches.first,
              let piece = draggedPiece else { return }

        // Birakma noktasi: parcanin gercek pozisyonu
        // Parmak ofseti zaten bu pozisyona yansitildi — gorunen yere birakir
        let dropLocation = piece.position

        // Surukleme birakma noktasindaki grid hucresini bul
        if let (row, col) = gridNode.nearestCell(for: dropLocation, piece: piece),
           gridNode.canPlace(piece.shape, at: row, col: col) {
            placePiece(piece, at: row, col: col)
        } else {
            // Gecersiz konum — orijinal pozisyona geri dondur
            cancelDrag(for: piece)
        }

        // Surukleme bitti — highlight temizle ve state sifirla
        gridNode.clearHighlight()
        lastHighlightAnchor = nil
        draggedPiece = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Sistem iptali (cagri geldi vb.) — parcayi geri dondur
        if let piece = draggedPiece {
            gridNode.clearHighlight()
            lastHighlightAnchor = nil
            cancelDrag(for: piece)
            draggedPiece = nil
        }
    }

    // MARK: - Surukleme Yardimcilari

    /// Parcayi orijinal pozisyonuna geri dondurur
    private func cancelDrag(for piece: PieceNode) {
        piece.cancelDrag()
    }

    /// Surukleme sirasinda grid highlight gunceller — hafif, sadece renk degisir
    private func updateHighlight(for piece: PieceNode) {
        // Parca grid disindaysa highlight yok
        guard let (row, col) = gridNode.nearestCell(for: piece.position, piece: piece) else {
            // Daha once highlight vardiysa temizle — aksi halde gereksiz is yapma
            if lastHighlightAnchor != nil { gridNode.clearHighlight() }
            lastHighlightAnchor = nil
            return
        }

        // Ayni hucre uzerindeyse tekrar hesaplama — gereksiz performans maliyeti yok
        if let last = lastHighlightAnchor, last.row == row, last.col == col {
            return
        }
        lastHighlightAnchor = (row: row, col: col)

        // Seklin tum hucrelerinin grid pozisyonlarini hesapla
        // Normalized offsets kullanilir — her frame'de min hesaplama yapilmaz
        let positions: [(row: Int, col: Int)] = piece.normalizedOffsets.map {
            (row: row + $0.row, col: col + $0.col)
        }

        let valid = gridNode.canPlace(piece.shape, at: row, col: col)
        gridNode.highlight(positions: positions, valid: valid)
    }

    // MARK: - Yerlestirme

    /// Parcayi grid'e yerlestirir, animasyon oynatir, slot temizler.
    private func placePiece(_ piece: PieceNode, at row: Int, col: Int) {
        // Haptic geri bildirim — yerlestirme hissi verir
        HapticManager.impact(.medium)

        // Veri + gorsel grid guncellemesi
        gridNode.place(piece.shape, at: row, col: col)

        // Parcayi tepsiden kaldir
        trayPieces[piece.slotIndex] = nil
        piece.playPlaceAnimation {
            piece.removeFromParent()
        }

        // Tum slotlar bosaldiysa yeni tur baslat
        if trayPieces.allSatisfy({ $0 == nil }) {
            // Kisa gecikme: son parcanin animasyonu tamamlansin
            run(SKAction.wait(forDuration: 0.25)) { [weak self] in
                self?.dealNewPieces()
                // Yeni parcalar geldikten sonra oyun bitti kontrolu
                self?.run(SKAction.wait(forDuration: 0.3)) {
                    self?.checkGameOver()
                }
            }
        } else {
            // Hemen oyun bitti kontrolu — kalan parcalarla devam
            checkGameOver()
        }
    }

    // MARK: - Oyun Bitti Kontrolu

    /// Kalan parcalarin hicbiri grid'e sigmiyorsa oyunu bitirir
    private func checkGameOver() {
        let remaining = trayPieces.compactMap { $0?.shape }
        // Tepsi bos ise kontrol yapma — yeni parca gelecek
        guard !remaining.isEmpty else { return }
        if gridNode.noPieceFits(shapes: remaining) {
            manager.triggerGameOver()
        }
    }

    // MARK: - Oyun Sonu Overlay

    /// Yari saydam overlay + skor karti.
    /// Yeni scene gecisi YOK — gecis kasasi yapar. Overlay sahneye eklenir.
    private func showGameOverOverlay() {
        let overlay = SKNode()
        overlay.zPosition = C.zOverlay
        overlay.alpha = 0

        // Karartma katmani — dikkat kartta toplansin
        let dim = SKSpriteNode(
            color: UIColor.black.withAlphaComponent(0.85).sk,
            size: CGSize(width: C.screenW, height: C.screenH)
        )
        dim.anchorPoint = .zero
        dim.position = .zero
        overlay.addChild(dim)

        // Kart boyutlari responsive
        let cardW = C.screenW * 0.80
        let cardH = C.screenH * 0.44
        let cardX = C.screenW / 2
        // Kart Y safe area merkezine alin — alt paneli ve notch'i ihlal etmesin
        let safeCenterY = safeAreaFrame == .zero ? C.screenH / 2 : safeAreaFrame.midY
        let cardY = safeCenterY
        let corner = cardH * 0.12

        let cardRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
        let card = SKShapeNode(rect: cardRect, cornerRadius: corner)
        card.fillColor = UIColor(hex: "#1a1a36").sk
        card.strokeColor = UIColor.white.withAlphaComponent(0.12).sk
        card.lineWidth = C.screenW * 0.0022
        card.position = CGPoint(x: cardX, y: cardY)
        overlay.addChild(card)

        // Kart icin hafif golge — derinlik hissi
        let shadow = SKShapeNode(rect: cardRect, cornerRadius: corner)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.25).sk
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: cardX, y: cardY - C.screenH * 0.01)
        shadow.zPosition = -0.5
        overlay.addChild(shadow)

        // Icerik yerlesimi icin dikey araliklar
        let contentTop = cardH / 2 - cardH * 0.16
        let spacing = cardH * 0.12

        // Yazi boyutlarini kart yuksekligine gore sinirla — tasma onleme
        let titleSize = min(C.screenH * 0.034, cardH * 0.12)
        let scoreSize = min(C.screenH * 0.070, cardH * 0.22)
        let ptsSize = min(C.screenH * 0.018, cardH * 0.06)
        let hsSize = min(C.screenH * 0.022, cardH * 0.07)

        // "OYUN BITTI"
        let title = makeLabel("OYUN BITTI", font: C.fontBold,
                              size: titleSize, color: .white)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: contentTop)
        card.addChild(title)

        // Skor degeri
        let scoreLbl = makeLabel("\(manager.score)", font: C.fontBold,
                                 size: scoreSize, color: C.goldColor.sk)
        scoreLbl.verticalAlignmentMode = .center
        scoreLbl.position = CGPoint(x: 0, y: contentTop - spacing)
        card.addChild(scoreLbl)

        let ptsLbl = makeLabel("PUAN", font: C.fontMedium,
                               size: ptsSize, color: UIColor.white.withAlphaComponent(0.5).sk)
        ptsLbl.verticalAlignmentMode = .center
        ptsLbl.position = CGPoint(x: 0, y: contentTop - spacing * 1.75)
        card.addChild(ptsLbl)

        // Rekor
        let hsLbl = makeLabel("EN YUKSEK: \(manager.highScore)", font: C.fontMedium,
                              size: hsSize, color: C.goldColor.sk)
        hsLbl.verticalAlignmentMode = .center
        hsLbl.position = CGPoint(x: 0, y: contentTop - spacing * 2.55)
        card.addChild(hsLbl)

        // Uzun metinlerde tasma olmasin diye gerekli olursa scale uygula
        let maxTitleWidth = cardW * 0.78
        let maxScoreWidth = cardW * 0.78
        let maxHsWidth = cardW * 0.82
        if title.frame.width > maxTitleWidth {
            title.setScale(maxTitleWidth / title.frame.width)
        }
        if scoreLbl.frame.width > maxScoreWidth {
            scoreLbl.setScale(maxScoreWidth / scoreLbl.frame.width)
        }
        if hsLbl.frame.width > maxHsWidth {
            hsLbl.setScale(maxHsWidth / hsLbl.frame.width)
        }

        // Ayirici
        let sepPath = CGMutablePath()
        let sepLeft = -cardW / 2 + cardW * 0.10
        let sepRight = cardW / 2 - cardW * 0.10
        let sepY = -cardH / 2 + cardH * 0.28
        sepPath.move(to: CGPoint(x: sepLeft, y: sepY))
        sepPath.addLine(to: CGPoint(x: sepRight, y: sepY))
        let sep = SKShapeNode(path: sepPath)
        sep.strokeColor = UIColor.white.withAlphaComponent(0.12).sk
        sep.lineWidth = C.screenW * 0.0016
        card.addChild(sep)

        // "YENIDEN OYNA" butonu
        let btnW = cardW * 0.76
        let btnH = C.screenH * 0.060
        addOverlayButton(to: card, text: "YENIDEN OYNA", name: "restartBtn",
                         color: UIColor(hex: "#00c853"),
                         y: -cardH / 2 + cardH * 0.22,
                         w: btnW, h: btnH)

        // "ANA MENU" butonu
        addOverlayButton(to: card, text: "ANA MENU", name: "homeBtn",
                         color: UIColor(hex: "#1565c0"),
                         y: -cardH / 2 + cardH * 0.08,
                         w: btnW, h: btnH)

        addChild(overlay)
        overlayNode = overlay
        // Overlay fade + scale pop — daha modern dialog hissi
        overlay.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.35),
            SKAction.sequence([
                SKAction.scale(to: 0.96, duration: 0.0),
                SKAction.scale(to: 1.0, duration: 0.18)
            ])
        ]))
    }

    /// Overlay buton helper
    private func addOverlayButton(to parent: SKNode,
                                  text: String,
                                  name: String,
                                  color: UIColor,
                                  y: CGFloat,
                                  w: CGFloat, h: CGFloat) {
        // Buton sekli — yuvarlak kenar, parmakla dokunma rahatligi
        let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
        let btn = SKShapeNode(rect: rect, cornerRadius: h / 2)
        btn.fillColor = color.sk
        btn.strokeColor = .clear
        btn.name = name
        btn.position = CGPoint(x: 0, y: y)
        parent.addChild(btn)

        // Buton yazisi — dokunma alanina bagli olsun
        let lbl = makeLabel(text, font: C.fontBold,
                            size: C.screenH * 0.022, color: .white)
        lbl.verticalAlignmentMode = .center
        lbl.name = name
        btn.addChild(lbl)
    }

    // MARK: - Overlay Dokunus

    private func handleOverlayTap(_ node: SKNode) {
        // Node ismine gore aksiyon sec — SKShapeNode ve label ayni isme sahip
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

    // MARK: - Yeniden Baslat

    private func restartGame() {
        // Overlay temizle — yeni oyuna temiz sahne ile basla
        overlayNode?.removeFromParent()
        overlayNode = nil
        // Tepsi parcalarini temizle — yeni set gelecek
        trayPieces.forEach { $0?.removeFromParent() }
        trayPieces = [nil, nil, nil]
        draggedPiece = nil
        // Grid ve skor sifirlama
        gridNode.reset()
        manager.reset()
        // Sekil torbasini temizle — yeni oyunda temiz dagilim
        shapeBag.removeAll()
        scoreValueLabel.text = "0"
        highScoreValueLabel.text = "\(manager.highScore)"
        dealNewPieces()
    }

    // MARK: - Ana Menuye Don

    private func goToHome() {
        // HomeScene'e fade ile don — temiz ve yavas gecis
        let home = HomeScene(size: size)
        home.scaleMode = scaleMode
        view?.presentScene(home, transition: SKTransition.fade(withDuration: 0.4))
    }

    // MARK: - Yardimcilar

    /// SKLabelNode olusturur — tekrar eden kod yerine merkezi uretici
    private func makeLabel(_ text: String, font: String,
                           size: CGFloat, color: SKColor) -> SKLabelNode {
        let lbl = SKLabelNode(fontNamed: font)
        lbl.text = text
        lbl.fontSize = size
        lbl.fontColor = color
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode = .baseline
        return lbl
    }

    /// Yatay cizgi — panel ayiricisi icin
    private func makeSeparator(y: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: C.screenW, y: y))
        let line = SKShapeNode(path: path)
        line.strokeColor = UIColor(red: 0.25, green: 0.25, blue: 0.45, alpha: 1).sk
        // Cizgi kalinligi ekran genisligine gore ayarlanir — sabit px yok
        line.lineWidth = C.screenW * 0.0016
        line.zPosition = C.zPanel + 0.1
        return line
    }

    /// Mevcut ayirici cizgiyi yeni Y konumuna ve genislige gore gunceller
    private func updateSeparator(_ line: SKShapeNode, y: CGFloat) {
        // Yeni path olustur — genislik ve konum guncellensin
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: C.screenW, y: y))
        line.path = path
        // Cizgi kalinligi responsive kalmali
        line.lineWidth = C.screenW * 0.0016
    }
}

// MARK: - GridDelegate
extension GameScene: GridDelegate {

    /// Cizgiler temizlendiginde: skor ekle, haptic, combo yazisi
    func gridDidClearLines(_ count: Int) {
        manager.addScore(forLines: count)
        HapticManager.impact(.heavy)
        showLineClearEffect(count: count)
    }

    /// Hucreler yerlestirildiginde: skor ekle
    func gridDidPlaceCells(_ count: Int) {
        manager.addScore(forCells: count)
    }

    /// Cizgi temizleme efekti — ucan yazi
    private func showLineClearEffect(count: Int) {
        let text: String
        let color: SKColor
        let fsize: CGFloat

        // Cizgi sayisina gore mesaj ve boyut degistir — geri bildirim net olsun
        switch count {
        case 1:
            text = "LINE!"; color = .white; fsize = C.screenH * 0.026
        case 2:
            text = "DOUBLE!"; color = C.goldColor.sk; fsize = C.screenH * 0.032
        default:
            text = "COMBO x\(count)!"; color = C.goldColor.sk; fsize = C.screenH * 0.036
        }

        let lbl = makeLabel(text, font: C.fontBold, size: fsize, color: color)
        lbl.position = CGPoint(
            x: C.screenW / 2,
            y: effectiveGridCenterY + C.gridTotalHeight / 2 + C.screenH * 0.02
        )
        lbl.zPosition = C.zUI + 2
        lbl.alpha = 0
        addChild(lbl)

        // Fade + yukari kayma — hafif animasyon, kasa yapmaz
        lbl.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.15),
                SKAction.moveBy(x: 0, y: C.screenH * 0.07, duration: 0.65)
            ]),
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent()
        ]))
    }
}

// MARK: - GameManagerDelegate
extension GameScene: GameManagerDelegate {

    func didUpdateScore(_ score: Int, highScore: Int, isNewRecord: Bool) {
        scoreValueLabel.text = "\(score)"
        highScoreValueLabel.text = "\(highScore)"

        // Skor micro-bounce — guncelleme fark edilsin
        scoreValueLabel.removeAction(forKey: "scoreBounce")
        scoreValueLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.28, duration: 0.08),
            SKAction.scale(to: 1.00, duration: 0.08)
        ]), withKey: "scoreBounce")

        if isNewRecord { showNewRecordEffect() }
    }

    func didChangeState(_ state: GameState) {
        if state == .gameOver {
            HapticManager.notification(.error)
            // Kisa gecikme: son animasyonlar tamamlansin
            run(SKAction.wait(forDuration: 0.45)) { [weak self] in
                self?.showGameOverOverlay()
            }
        }
    }

    /// "YENI REKOR!" ucan yazisi
    private func showNewRecordEffect() {
        let lbl = makeLabel("YENI REKOR!", font: C.fontBold,
                            size: C.screenH * 0.024, color: C.goldColor.sk)
        lbl.position = CGPoint(
            x: C.screenW / 2,
            y: effectiveGridCenterY + C.gridTotalHeight / 2 + C.screenH * 0.05
        )
        lbl.zPosition = C.zUI + 3
        lbl.alpha = 0
        addChild(lbl)

        // Fade + scale — dikkat cekmek icin kisa vurgu
        lbl.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.18),
                    SKAction.scale(to: 1.0, duration: 0.18)
                ])
            ]),
            SKAction.wait(forDuration: 1.4),
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.removeFromParent()
        ]))
    }
}
