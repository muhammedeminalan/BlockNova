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
    var shapeDispenser: ShapeDispenser!
    /// Alt tepsi — 3 parça slotu, nil = boş slot
    var trayPieces: [PieceNode?] = [nil, nil, nil]
    /// Preview slotları — hit-test ve yerleşim için
    var previewSlots: [PreviewSlotNode] = []

    // MARK: - Alt Panel Node'ları

    var bottomPanelNode: SKSpriteNode?

    /// SwiftUI router'a ana menüye dönüş bildirmek için köprü kapanışı
    var onReturnToHome: (() -> Void)?

    /// SwiftUI katmanina game over sunum datasini iletir
    var onGameOverChanged: ((GameOverPresentation?) -> Void)?
    /// SwiftUI katmanina combo efekt sunum datasini iletir
    var onComboEffectTriggered: ((ComboEffectPresentation) -> Void)?
    /// SwiftUI HUD katmanina skor verisini iletir
    var onScoreChanged: ((Int, Int) -> Void)?

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

    /// Arka arkaya cizgi kirma zinciri (combo sayaci)
    var comboChainCount: Int = 0
    /// Mevcut yerlestirmede cizgi kirildi mi? Finish adiminda zincir reset karari icin.
    var didClearLineInCurrentPlacement: Bool = false

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
        notifyScoreChanged(score: manager.score, highScore: manager.highScore)
    }

    /// Sahne ekrandan ayrılınca observer'ları temizle — retain cycle ve çift tetikleme önler
    override func willMove(from view: SKView) {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Safe Area Güncelleme

    /// Container katmanindan gelen safe area inset'lerini alir ve layout'u yeniler
    func updateSafeAreaInsets(_ insets: UIEdgeInsets) {
        safeAreaInsets = insets
        layoutScene()
    }

    // MARK: - Manager Kurulumu

    private func setupManager() {
        manager = GameManager.shared
        manager.delegate = self
        viewModel = GameViewModel(manager: manager)
        shapeDispenser = ShapeDispenser()
    }

    // MARK: - Grid Kurulumu

    private func setupGrid() {
        gridNode = GridNode()
        gridNode.delegate = self
        gridNode.position = CGPoint(x: C.gridCenterX, y: effectiveGridCenterY)
        gridNode.zPosition = C.zGrid
        addChild(gridNode)
    }

    // MARK: - Alt Panel Kurulumu

    private func setupBottomPanel() {
        let panel = SKSpriteNode(color: C.bgColor.sk,
                                 size: CGSize(width: C.screenW, height: C.bottomPanelHeight))
        panel.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        panel.zPosition = C.zPanel
        addChild(panel)
        bottomPanelNode = panel

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

    // MARK: - TOUCH BEGIN

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if manager.state == .gameOver {
            return
        }
        guard manager.state == .playing else { return }
        // Aktif sürükleme varken yeni piece seçme — ownership sabit kalsın
        guard draggedPiece == nil else { return }

        // Kullanıcı yeni sürükleme başlatırken sahnede kalan yetim parça varsa temizle.
        removeOrphanTrayPieces()

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

        draggedPiece = selected
        originalPosition = selected.position

        // beginDrag önce çağrılır: setScale içeride çalışır ve parçanın görsel boyutu değişir.
        // Offset hesabı scale sonrasında yapılmalı — aksi halde ölçek kayması dragOffset'i bozar.
        selected.beginDrag()

        // X offseti: parmak hangi noktaya dokunmuşsa parça o noktadan sürüklensin — kaymaz
        // Y offseti: sabit yukarı kaldırma — parmak parçayı kapatmasın
        dragOffset = CGPoint(x: selected.position.x - location.x, y: C.dragOffsetY)

        // Anlık konum ataması — gecikme hissi olmadan parça parmağa yapışır
        selected.position = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        lastHighlightAnchor = nil
        lastTouchLocation = location
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
        draggedPiece = nil
        lastTouchLocation = nil
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
        didClearLineInCurrentPlacement = false

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

    func checkGameOver() {
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
        trayPieces = [nil, nil, nil]
        draggedPiece = nil
        comboChainCount = 0
        didClearLineInCurrentPlacement = false
        previewSlots.forEach { $0.piece = nil }

        gridNode.reset()
        manager.reset()
        shapeDispenser.resetHistory()

        notifyScoreChanged(score: manager.score, highScore: manager.highScore)
        dealNewPieces()
    }

    // MARK: - Ana Menüye Dön

    func goToHome() {
        onGameOverChanged?(nil)
        onReturnToHome?()
    }

    func notifyScoreChanged(score: Int, highScore: Int) {
        onScoreChanged?(score, highScore)
    }

    // MARK: - Etiket Fabrikası

    /// SKLabelNode oluşturur — extension'lar dahil tüm sahne tarafından kullanılır
    func makeLabel(_ text: String, font: String,
                   size: CGFloat, color: SKColor) -> SKLabelNode {
        let lbl = SKLabelNode(fontNamed: font)
        lbl.text = text
        lbl.fontSize = size
        lbl.fontColor = color
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode = .baseline
        return lbl
    }
}
