// 📁 Scenes/GameScene.swift
// Oyunun ana sahnesi. Bileşenleri koordine eder; yerleşim mantığı extension'da tutulur:
//   GameScene+Layout.swift — safe area tabanlı yerleşim
// Oyun sonu overlay sunumu SwiftUI katmanında (GameContainerView) yönetilir.
//
// SÜRÜKLEME TASARIMI:
// - touchesMoved'da SKAction KULLANILMAZ: position doğrudan atanır — akıcılık için
// - beginDrag'de buildCells ÇAĞIRILMAZ: gesture lock önleme
// - clearHighlight sadece highlight edilen hücreleri sıfırlar: performans için

import SpriteKit
// import UIKit kaldırıldı — SpriteKit zaten UIKit'i dahil eder, duplicate import gereksiz

// MARK: - GameScene

final class GameScene: SKScene, SafeAreaUpdatable {

    // MARK: - Safe Area Durumu

    /// Güncel safe area inset'leri — panel ve grid hesapları için
    var safeAreaInsets: UIEdgeInsets = .zero
    /// Scene içinde kullanılabilir güvenli alan
    var safeAreaFrame: CGRect = .zero
    /// Grid'in efektif merkez Y değeri — safe area düzeltmesiyle güncellenir
    var effectiveGridCenterY: CGFloat = C.gridCenterY

    // MARK: - Bileşenler

    /// 8×8 oyun ızgarası
    var gridNode: GridNode!
    /// Oyun mantığı ve skor yöneticisi
    private(set) var manager: GameManager!
    /// Sunum katmanı — skor/durum sorgulama için
    private(set) var viewModel: GameViewModel!
    /// Şekil dağıtıcısı — üç katmanlı çeşitlilik sistemi
    private var shapeDispenser: ShapeDispenser!
    /// Alt tepsi — 3 parça slotu, nil = boş slot
    var trayPieces: [PieceNode?] = [nil, nil, nil]
    /// Preview slotları — hit-test ve yerleşim için
    var previewSlots: [PreviewSlotNode] = []

    // MARK: - Üst Panel Node'ları

    var topPanelNode: SKSpriteNode?
    var topPanelSeparator: SKShapeNode?
    var scoreTitleLabel: SKLabelNode?
    var scoreValueLabel: SKLabelNode!
    var highScoreTitleLabel: SKLabelNode?
    var highScoreValueLabel: SKLabelNode!

    // MARK: - Alt Panel Node'ları

    var bottomPanelNode: SKSpriteNode?
    var bottomPanelSeparator: SKShapeNode?

    /// SwiftUI router'a ana menüye dönüş bildirmek için köprü kapanışı
    var onReturnToHome: (() -> Void)?

    /// SwiftUI katmanina game over sunum datasini iletir
    var onGameOverChanged: ((GameOverPresentation?) -> Void)?
    /// SwiftUI katmanina combo efekt sunum datasini iletir
    var onComboEffectTriggered: ((ComboEffectPresentation) -> Void)?

    // MARK: - Sürükleme Durumu

    /// Aktif sürüklenen parça — nil: sürükleme yok
    var draggedPiece: PieceNode?
    /// Parmak ile parça merkezi arasındaki fark + yukarı offset
    private var dragOffset: CGPoint = .zero
    /// Sürükleme başlamadan önce parçanın pozisyonu — iptal edilince buraya döner
    private var originalPosition: CGPoint = .zero
    /// Son highlight edilen anchor hücre — gereksiz iş yapmamak için
    private var lastHighlightAnchor: (row: Int, col: Int)? = nil
    /// Son touch konumu — küçük hareketleri elemek için
    private var lastTouchLocation: CGPoint? = nil

    // MARK: - Sahne Kurulumu

    override func didMove(to view: SKView) {
        backgroundColor = C.bgColor.sk
        safeAreaInsets  = view.safeAreaInsets

        // Model ve UI kurulum sırası — bağımlılıkları net tutar
        setupManager()
        // Shared GameManager kullanimi nedeniyle yeni sahnede stale state kalmasin
        // Kayit varsa restoreScore zaten degerleri geri yazar
        manager.reset()
        setupGrid()
        setupTopPanel()
        setupBottomPanel()

        // Uygulama arka plana geçince oyun durumunu kaydet
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveGameState),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        // Uygulama kapanınca da kaydet
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveGameState),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        // Kayıtlı oyun varsa yükle, yoksa yeni parçalar dağıt
        if let savedState = GameSaveManager.shared.load() {
            restoreGameState(savedState)
        } else {
            dealNewPieces()
        }

        // İlk layout safe area'ya göre yapılır
        layoutScene()
    }

    /// Sahne ekrandan ayrılınca observer'ları temizle — retain cycle ve çift tetikleme önler
    override func willMove(from view: SKView) {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Oyun Kaydetme

    /// Mevcut oyun durumunu UserDefaults'a yazar.
    /// Game over durumunda kayıt yapılmaz — devam edilecek oyun yoktur.
    @objc func saveGameState() {
        guard manager.state == .playing else { return }

        // Grid renk datasını [[String?]] formatına dönüştür: dolu hücre hex, boş nil
        let gridRenkleri: [[String?]] = (0..<C.rows).map { satir in
            (0..<C.cols).map { sutun in
                gridNode.cellColors[satir][sutun]?.hexString
            }
        }

        // Tepsideki parçaların tip adlarını kaydet
        let parcaTipleri: [String] = trayPieces.compactMap { $0?.shape.type.rawValue }

        let state = SavedGameState(
            score:             manager.score,
            highScore:         manager.highScore,
            gridColors:        gridRenkleri,
            currentPieceTypes: parcaTipleri
        )
        GameSaveManager.shared.save(state)
    }

    // MARK: - Oyun Geri Yükleme

    /// Kaydedilmiş durumu sahneye uygular: skor, grid ve tepsi parçaları.
    private func restoreGameState(_ savedState: SavedGameState) {
        // Manager'ı kayıtlı skorla senkronize et
        manager.restoreScore(savedState.score, highScore: savedState.highScore)

        // Etiketler manager'daki normalize state'den gelsin; kayittaki stale degeri ezme.
        scoreValueLabel?.text     = "\(manager.score)"
        highScoreValueLabel?.text = "\(manager.highScore)"

        // Grid hücrelerini renkleriyle doldur — sınır kontrolü: bozuk kayıt için güvenli
        // UIColor(hex:) optional döndürmez, nil kontrolü hex string üzerinden yapılır
        for satir in 0..<min(savedState.gridColors.count, C.rows) {
            let satirVerisi = savedState.gridColors[satir]
            for sutun in 0..<min(satirVerisi.count, C.cols) {
                if let hex = satirVerisi[sutun] {
                    let renk = UIColor(hex: hex)
                    gridNode.fillCell(row: satir, col: sutun, color: renk)
                }
            }
        }

        // Tepsi parçalarını rawValue → BlockShapeType → BlockShape zinciiriyle yükle
        let sekiller: [BlockShape] = savedState.currentPieceTypes.compactMap { rawDeger in
            guard let tip = BlockShapeType(rawValue: rawDeger) else { return nil }
            return BlockShape.shape(for: tip)
        }

        if !sekiller.isEmpty {
            placePiecesInTray(sekiller)
        } else {
            // Parça verisi bozuksa yeni dağıt
            dealNewPieces()
        }
    }

    /// Verilen şekilleri tepsi slotlarına yerleştirir.
    /// dealNewPieces ile aynı mantık — şekiller dışarıdan gelir.
    private func placePiecesInTray(_ sekiller: [BlockShape]) {
        for (i, sekil) in sekiller.prefix(3).enumerated() {
            let parca          = PieceNode(shape: sekil)
            parca.slotIndex    = i
            if i < previewSlots.count {
                let slot = previewSlots[i]
                parca.position     = slot.position
                parca.homePosition = slot.position
                slot.piece         = parca
                parca.applyPreviewScale(slotSize: slot.size)
            }
            parca.zPosition    = C.zPiece
            parca.alpha        = 0
            addChild(parca)
            trayPieces[i] = parca

            let gecikme = Double(i) * 0.06
            parca.run(SKAction.sequence([
                SKAction.wait(forDuration: gecikme),
                SKAction.fadeIn(withDuration: 0.18)
            ]))
        }
    }

    // MARK: - Safe Area Güncelleme

    /// Container katmanindan gelen safe area inset'lerini alir ve layout'u yeniler
    func updateSafeAreaInsets(_ insets: UIEdgeInsets) {
        safeAreaInsets = insets
        layoutScene()
    }

    // MARK: - Manager Kurulumu

    private func setupManager() {
        manager   = GameManager.shared
        manager.delegate = self
        viewModel = GameViewModel(manager: manager)
        shapeDispenser = ShapeDispenser()
    }

    // MARK: - Grid Kurulumu

    private func setupGrid() {
        gridNode          = GridNode()
        gridNode.delegate = self
        gridNode.position = CGPoint(x: C.gridCenterX, y: effectiveGridCenterY)
        gridNode.zPosition = C.zGrid
        addChild(gridNode)
    }

    // MARK: - Üst Panel Kurulumu

    private func setupTopPanel() {
        let panel = SKSpriteNode(color: C.panelColor.sk,
                                 size: CGSize(width: C.screenW, height: C.topPanelHeight))
        panel.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        panel.zPosition   = C.zPanel
        addChild(panel)
        topPanelNode = panel

        let sep = makeSeparator(y: C.screenH - C.topPanelHeight)
        addChild(sep)
        topPanelSeparator = sep

        // Sol: mevcut skor
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

        // Sağ: en yüksek skor
        let hsTitle = makeLabel("EN YUKSEK", font: C.fontMedium,
                                size: C.screenH * 0.016, color: C.accentColor.sk)
        hsTitle.horizontalAlignmentMode = .center
        hsTitle.zPosition = C.zUI
        addChild(hsTitle)
        highScoreTitleLabel = hsTitle

        highScoreValueLabel = makeLabel(viewModel.highScoreText, font: C.fontBold,
                                        size: C.screenH * 0.038, color: C.goldColor.sk)
        highScoreValueLabel.horizontalAlignmentMode = .center
        highScoreValueLabel.zPosition = C.zUI
        addChild(highScoreValueLabel)
    }

    // MARK: - Alt Panel Kurulumu

    private func setupBottomPanel() {
        let panel = SKSpriteNode(color: C.panelColor.sk,
                                 size: CGSize(width: C.screenW, height: C.bottomPanelHeight))
        panel.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        panel.zPosition   = C.zPanel
        addChild(panel)
        bottomPanelNode = panel

        let sep = makeSeparator(y: C.bottomPanelHeight)
        addChild(sep)
        bottomPanelSeparator = sep

        setupPreviewSlots()
    }

    private func setupPreviewSlots() {
        if !previewSlots.isEmpty { return }
        for i in 0..<3 {
            let slot = PreviewSlotNode(index: i, size: C.previewSlotSize)
            addChild(slot)
            previewSlots.append(slot)
        }
    }

    // MARK: - Parça Dağıtma

    /// Tepsi state'iyle eşleşmeyen eski PieceNode'ları temizler.
    /// Neden: Bazı cihazlarda animation completion kaçarsa eski node sahnede kalıp
    /// yeni gelen parçalarla üst üste binebiliyor.
    private func removeOrphanTrayPieces() {
        let aktifKimlikler = Set(trayPieces.compactMap { $0 }.map { ObjectIdentifier($0) })

        let sahnedekiParcalar = children.compactMap { $0 as? PieceNode }
        for parca in sahnedekiParcalar {
            let kimlik = ObjectIdentifier(parca)
            guard !aktifKimlikler.contains(kimlik) else { continue }
            parca.removeAllActions()
            parca.removeFromParent()
        }
    }

    /// Alt tepsiye ShapeDispenser'dan 3 yeni parça yerleştirir.
    /// Grid'in güncel durumu iletilir — akıllı üretim için grid analizi burada başlar.
    func dealNewPieces() {
        // Yeni tur dağıtımından önce sahnede kalan yetim parça varsa temizle.
        removeOrphanTrayPieces()

        // Grid durumunu ilet: ShapeDispenser neredeyse dolu satır/sütun olduğunu bilsin
        let shapes   = shapeDispenser.nextSet(for: gridNode.cellColors)

        for (i, shape) in shapes.enumerated() {
            let piece = PieceNode(shape: shape)
            piece.slotIndex    = i
            if i < previewSlots.count {
                let slot = previewSlots[i]
                piece.position     = slot.position
                piece.homePosition = slot.position
                slot.piece         = piece
                piece.applyPreviewScale(slotSize: slot.size)
            }
            piece.zPosition    = C.zPiece
            piece.alpha        = 0
            addChild(piece)
            trayPieces[i] = piece

            // Fade-in — slide animasyonu kasaya neden olabilir
            let delay = Double(i) * 0.07
            piece.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.20)
            ]))
        }
    }

    // MARK: - TOUCH BEGIN

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if manager.state == .gameOver {
            return
        }
        guard manager.state == .playing,
              let touch = touches.first else { return }
        // Aktif sürükleme varken yeni piece seçme — ownership sabit kalsın
        guard draggedPiece == nil else { return }

        // Kullanıcı yeni sürükleme başlatırken sahnede kalan yetim parça varsa temizle.
        removeOrphanTrayPieces()

        let location = touch.location(in: self)
        let selectedSlot = previewSlots.first { slot in
            slot.calculateAccumulatedFrame().contains(location)
        }
        guard let slot = selectedSlot, let selected = slot.piece else {
            lastTouchLocation = nil
            return
        }
        guard trayPieces.contains(where: { $0 === selected }) else {
            lastTouchLocation = nil
            return
        }

        draggedPiece     = selected
        originalPosition = selected.position

        // beginDrag önce çağrılır: setScale içeride çalışır ve parçanın görsel boyutu değişir.
        // Offset hesabı scale sonrasında yapılmalı — aksi halde ölçek kayması dragOffset'i bozar.
        selected.beginDrag()

        // X offseti: parmak hangi noktaya dokunmuşsa parça o noktadan sürüklensin — kaymaz
        // Y offseti: sabit yukarı kaldırma — parmak parçayı kapatmasın
        dragOffset = CGPoint(x: selected.position.x - location.x, y: C.dragOffsetY)

        // Anlık konum ataması — gecikme hissi olmadan parça parmağa yapışır
        selected.position   = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        lastHighlightAnchor = nil
        lastTouchLocation   = location
        updateHighlight(for: selected)
    }

    // MARK: - TOUCH MOVE

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let piece = draggedPiece else { return }

        let location = touch.location(in: self)
        if let last = lastTouchLocation {
            let dx = location.x - last.x
            let dy = location.y - last.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < C.dragMinDistance { return }
        }
        lastTouchLocation = location
        // DOĞRUDAN position ataması — SKAction gecikme yaratır
        piece.position = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        updateHighlight(for: piece)
    }

    // MARK: - TOUCH END

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if manager.state == .gameOver { return }
        // guard let kullanımı: force unwrap yerine güvenli açma — crash önlenir
        guard let piece = draggedPiece else { return }

        let dropLocation = piece.position

        if let (row, col) = gridNode.nearestCell(for: dropLocation, piece: piece),
           gridNode.canPlace(piece.shape, at: row, col: col) {
            placePiece(piece, at: row, col: col)
        } else {
            cancelDrag(for: piece, playInvalidSound: true)
        }

        gridNode.clearHighlight()
        gridNode.clearWillClearFlash()
        lastHighlightAnchor = nil
        draggedPiece        = nil
        lastTouchLocation   = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let piece = draggedPiece {
            gridNode.clearHighlight()
            gridNode.clearWillClearFlash()
            lastHighlightAnchor = nil
            cancelDrag(for: piece, playInvalidSound: false)
            draggedPiece = nil
            lastTouchLocation = nil
        }
    }

    // MARK: - Sürükleme Yardımcıları

    private func cancelDrag(for piece: PieceNode, playInvalidSound: Bool) {
        if playInvalidSound {
            HapticManager.impact(.light)
            SoundManager.shared.playInvalid(on: self)
        }
        piece.cancelDrag()
    }

    /// Sürükleme sırasında grid highlight günceller — sadece renk değişir
    private func updateHighlight(for piece: PieceNode) {
        guard let (row, col) = gridNode.nearestCell(for: piece.position, piece: piece) else {
            if lastHighlightAnchor != nil { gridNode.clearHighlight() }
            gridNode.clearWillClearFlash()
            lastHighlightAnchor = nil
            return
        }

        // Aynı hücre üzerindeyse tekrar hesaplama
        if let last = lastHighlightAnchor, last.row == row, last.col == col { return }
        lastHighlightAnchor = (row: row, col: col)

        // Önce flash preview'i temizle
        gridNode.clearWillClearFlash()

        let positions: [(row: Int, col: Int)] = piece.normalizedOffsets.map {
            (row: row + $0.row, col: col + $0.col)
        }
        let valid = gridNode.canPlace(normalizedOffsets: piece.normalizedOffsets, at: row, col: col)
        gridNode.highlight(positions: positions, valid: valid)

        guard valid else { return }

        // Yerleştirince dolacak satır/sütunları hesapla ve yanıp söndür
        let willClearRows = gridNode.rowsThatWillClear(if: piece.shape, at: row, col: col)
        let willClearCols = gridNode.colsThatWillClear(if: piece.shape, at: row, col: col)
        if !willClearRows.isEmpty || !willClearCols.isEmpty {
            gridNode.flashWillClear(rows: willClearRows, cols: willClearCols)
        }
    }

    // MARK: - Yerleştirme

    private func placePiece(_ piece: PieceNode, at row: Int, col: Int) {
        HapticManager.impact(.medium)
        // Blok grid'e yerleştirilince pop sesi çal
        SoundManager.shared.playPlace(on: self)

        // Tepsi slotunu ÖNCE nil yap — gridNode.place() satır temizleme olmadığında
        // gridDidFinishPlacement'ı senkron çağırır. Slot nil yapılmamışsa tepsi
        // "hâlâ dolu" görünür ve dealNewPieces hiç tetiklenmez.
        trayPieces[piece.slotIndex] = nil
        if piece.slotIndex < previewSlots.count {
            previewSlots[piece.slotIndex].piece = nil
        }
        gridNode.place(piece.shape, at: row, col: col)

        piece.playPlaceAnimation { piece.removeFromParent() }

        // Game over kontrolu gridDidFinishPlacement delegate'inde yapilir.
        // Satir/sutun temizleme 0.18sn gecikmeyle gerceklesir — o bitene kadar
        // grid verisi guncel degildir, bu yuzden burada checkGameOver CAGIRILMAZ.
    }

    // MARK: - Oyun Bitti Kontrolü

    private func checkGameOver() {
        let remaining = trayPieces.compactMap { $0?.shape }
        guard !remaining.isEmpty else { return }
        if gridNode.noPieceFits(shapes: remaining) {
            manager.triggerGameOver()
        }
    }

    // MARK: - Yeniden Başlat

    func restartGame() {
        onGameOverChanged?(nil)

        // Yeni oyun başlayınca kaydı sil — eski durum geçersiz
        GameSaveManager.shared.deleteSavedGame()

        trayPieces.forEach { $0?.removeFromParent() }
        trayPieces   = [nil, nil, nil]
        draggedPiece = nil
        previewSlots.forEach { $0.piece = nil }

        gridNode.reset()
        manager.reset()
        shapeDispenser.resetHistory()

        scoreValueLabel.text     = "0"
        highScoreValueLabel.text = viewModel.highScoreText
        dealNewPieces()
    }

    // MARK: - Ana Menüye Dön

    func goToHome() {
        onGameOverChanged?(nil)
        onReturnToHome?()
    }

    /// SwiftUI katmanindan "Ana Menü" cikisi isterken cagirilir.
    /// Gameplay davranisini degistirmez; sadece cikis oncesi state'i guvenle kaydeder.
    func prepareForExitToHome() {
        saveGameState()
    }

    // MARK: - Skor Animasyonu

    /// Skor artinca label ziplat — net geri bildirim
    private func animateScoreLabel() {
        scoreValueLabel.removeAction(forKey: "scoreBounce")
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        scoreValueLabel.run(bounce, withKey: "scoreBounce")
    }

    // MARK: - Etiket Fabrikası

    /// SKLabelNode oluşturur — extension'lar dahil tüm sahne tarafından kullanılır
    func makeLabel(_ text: String, font: String,
                   size: CGFloat, color: SKColor) -> SKLabelNode {
        let lbl = SKLabelNode(fontNamed: font)
        lbl.text     = text
        lbl.fontSize = size
        lbl.fontColor = color
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode   = .baseline
        return lbl
    }
}

// MARK: - GridDelegate

extension GameScene: GridDelegate {

    func gridDidClearLines(_ count: Int) {
        manager.addScore(forLines: count)
        HapticManager.impact(.heavy)
        // Çizgi temizlenince long-pop sesi çal
        SoundManager.shared.playClear(on: self)
        if count >= 2 {
            SoundManager.shared.playCombo(on: self)
        }
        if count >= 3 {
            // Neden: Mega combo anında daha güçlü ödül hissi için.
            HapticManager.notification(.success)
        }

        let linePoints = manager.previewPointsForLines(count)
        let effect = ComboEffectPresentation(
            level: ComboEffectPresentation.level(for: count),
            points: linePoints
        )
        onComboEffectTriggered?(effect)
    }

    func gridDidPlaceCells(_ count: Int) {
        manager.addScore(forCells: count)
    }

    func gridDidFinishPlacement() {
        // Satir/sutun temizleme bittikten sonra: tepsi bosaldiysa yeni parcalar dagit,
        // sonra game over kontrolu yap. Grid verisi artik gunceldir.
        if trayPieces.allSatisfy({ $0 == nil }) {
            run(SKAction.wait(forDuration: 0.25)) { [weak self] in
                self?.dealNewPieces()
                self?.run(SKAction.wait(forDuration: 0.3)) {
                    self?.checkGameOver()
                }
            }
        } else {
            checkGameOver()
        }
    }

}

// MARK: - GameManagerDelegate

extension GameScene: GameManagerDelegate {

    func didUpdateScore(_ score: Int, highScore: Int, isNewRecord: Bool) {
        scoreValueLabel.text     = "\(score)"
        highScoreValueLabel.text = "\(highScore)"

        // Skor artinca label ziplasin — daha net geri bildirim
        animateScoreLabel()

        if isNewRecord {
            // Yeni rekor kırılınca achievement sesi çal — her skor artışında değil, sadece rekorда
            SoundManager.shared.playRecord(on: self)
            showNewRecordEffect()
        }
    }

    func didChangeState(_ state: GameState) {
        if state == .gameOver {
            HapticManager.notification(.error)
            // Oyun bitince game-over sesi çal
            SoundManager.shared.playGameOver(on: self)

            // Game over olunca kaydı sil — devam edilecek oyun kalmadı
            GameSaveManager.shared.deleteSavedGame()

            // Skoru Game Center'a gönder — her bitişte çağrılır, sadece rekorda değil
            GameManager.submitScore(manager.score)

            run(SKAction.wait(forDuration: 0.45)) { [weak self] in
                guard let self else { return }
                let score = self.manager.score
                let highScore = self.manager.highScore
                let presentation = GameOverPresentation(
                    score: score,
                    highScore: highScore,
                    isNewRecord: self.manager.newRecordAchieved
                )
                self.onGameOverChanged?(presentation)
            }
        }
    }

    /// "YENİ REKOR!" uçan yazısı
    private func showNewRecordEffect() {
        let lbl = makeLabel("YENI REKOR!", font: C.fontBold,
                            size: C.screenH * 0.024, color: C.goldColor.sk)
        lbl.position  = CGPoint(x: C.screenW / 2,
                                y: effectiveGridCenterY + C.gridTotalHeight / 2 + C.screenH * 0.05)
        lbl.zPosition = C.zUI + 3
        lbl.alpha     = 0
        addChild(lbl)

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
