// 📁 Nodes/PieceNode.swift
// Alt tepsi bolgesindeki blok parcasinin container node'u.
// Her hucre icin SKSpriteNode barindirir — onizleme boyutunda olusturulur.
// Surukleme sirasinda dogrudan position atanir, SKAction KULLANILMAZ — akicilik icin.
// Kritik: beginDrag icinde buildCells CAGIRILMAZ — touch event sirasinda
// removeAllChildren + node yaratma gesture pipeline'ini kilitler (gesture gate timeout).

import SpriteKit
// import UIKit kaldırıldı — SpriteKit zaten UIKit'i dahil eder, duplicate import gereksiz

// MARK: - PieceNode
final class PieceNode: SKNode {

    // MARK: - Ozellikler

    /// Bu parcanin sekil modeli — hucre offsetleri, renk, boyut icin
    let shape: BlockShape

    /// Seklin minimum satir indeksi — normalize offset ve merkez hesaplari icin
    private let minRow: Int
    /// Seklin minimum sutun indeksi — normalize offset ve merkez hesaplari icin
    private let minCol: Int
    /// Seklin maksimum satir indeksi — merkez hesaplari icin
    private let maxRow: Int
    /// Seklin maksimum sutun indeksi — merkez hesaplari icin
    private let maxCol: Int

    /// Seklin normalize edilmis offset listesi — highlight ve yerlestirmede hiz icin
    /// Normalizasyon: minRow/minCol sifirlanir, offsetler 0'dan baslar
    let normalizedOffsets: [(row: Int, col: Int)]

    /// Seklin merkez kaymasini hucre biriminde tutar — grid'e hizalama icin
    private let centerOffsetInCells: CGPoint

    /// Tepsi icindeki slot indexi (0, 1, 2) — yerlestirme sonrasi ilgili slotu temizlemek icin
    var slotIndex: Int = 0

    /// Tepsi icindeki ev pozisyonu — iptal edilince buraya doner
    var homePosition: CGPoint = .zero

    /// Surukleme aktif mi? — touchesMoved sadece aktif parcayi tasir
    var isDragging: Bool = false

    // MARK: - Init

    /// shape: hangi blok sekli
    init(shape: BlockShape) {
        self.shape = shape

        // Seklin minimum/maksimum offsetlerini bir kez hesapla — performans icin
        let localMinRow = shape.offsets.map(\.row).min() ?? 0
        let localMinCol = shape.offsets.map(\.col).min() ?? 0
        let localMaxRow = shape.offsets.map(\.row).max() ?? 0
        let localMaxCol = shape.offsets.map(\.col).max() ?? 0

        self.minRow = localMinRow
        self.minCol = localMinCol
        self.maxRow = localMaxRow
        self.maxCol = localMaxCol

        // Seklin merkez kaymasini hucre biriminde hesapla — grid hizalama icin
        let centerX = CGFloat(localMaxCol - localMinCol) / 2
        let centerY = CGFloat(localMaxRow - localMinRow) / 2
        self.centerOffsetInCells = CGPoint(x: centerX, y: centerY)

        // Normalize offsetleri hazirla — her frame hesaplama yapma
        self.normalizedOffsets = shape.offsets.map {
            (row: $0.row - localMinRow, col: $0.col - localMinCol)
        }

        super.init()

        // Hucreleri sadece bir kez olustur — surukleme performansi icin kritik
        buildCells()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) desteklenmez")
    }

    // MARK: - Hucre Olusturma

    /// Sekli olusturan her hucre icin SKSpriteNode yaratir.
    /// previewCellSize kullanilir — tepside grid'den kucuk gorunur.
    /// Sadece init'te cagirilir; surukleme sirasinda cagirilmaz — kasa/gesture lock onleme.
    private func buildCells() {
        // Eski child'lari temizle — secilen sekle gore yeniden cizim yapilacak
        removeAllChildren()

        // Onizleme boyutu — grid boyutundan kucuk
        let cs = C.previewCellSize
        // Hucre aralarinda bosluk birakmak icin gorsel boyut
        // Oran kullanilir — sabit px yok, her ekranda dengeli kalir
        let vs = cs * 0.88

        // Seklin lokal merkezi: tum hucreler buna gore offsetlenir
        // Bu sayede node'un (0,0) noktasi seklin gorsel merkezine gelir
        let centerOffsetX = CGFloat(maxCol - minCol) / 2 * cs
        let centerOffsetY = CGFloat(maxRow - minRow) / 2 * cs

        // Her offset icin bir hucre olustur
        for offset in shape.offsets {
            let cell = SKSpriteNode(color: shape.color.sk,
                                    size: CGSize(width: vs, height: vs))
            // col → X (saga arti), row → Y (SpriteKit Y yukari, row asagi → eksi)
            cell.position = CGPoint(
                x:  CGFloat(offset.col - minCol) * cs - centerOffsetX,
                y: -CGFloat(offset.row - minRow) * cs + centerOffsetY
            )
            cell.zPosition = 0.1
            addChild(cell)
        }
    }

    // MARK: - Grid Hizalama

    /// Grid hesaplari icin parcanin sol-ust hucre merkezine kayma offsetini verir
    /// Bu offset, parcanin gorsel merkezini grid hucre merkezleriyle hizalar
    func gridAnchorOffset(cellSize: CGFloat) -> CGPoint {
        // Sol-ust hucre merkezine kayma: X negatif, Y pozitif
        return CGPoint(
            x: -centerOffsetInCells.x * cellSize,
            y:  centerOffsetInCells.y * cellSize
        )
    }

    // MARK: - Surukleme Baslatma

    /// Surukleme basladiginda cagirilir.
    /// setScale ile buyutulur — buildCells CAGIRILMAZ (gesture lock onleme).
    /// Mevcut child node'lar sadece scale ile buyur — yeniden cizim yok.
    func beginDrag() {
        isDragging = true
        zPosition  = C.zDrag
        // Onizleme boyutundan (previewCellSize) grid boyutuna (cellSize) olcekle
        // targetScale = cellSize / previewCellSize
        let targetScale = C.cellSize / C.previewCellSize
        setScale(targetScale * C.dragLiftScale)
        alpha = 0.98
    }

    // MARK: - Surukleme Iptali

    /// Gecersiz konuma birakildiginda veya touch iptal edildiginde.
    /// Hizli geri donus animasyonu — scale ve pozisyon ayni anda animasyonlanir.
    /// SKAction burada kullanilir cunku touch event aktif degil (birakma sonrasi).
    func cancelDrag(completion: (() -> Void)? = nil) {
        isDragging = false
        zPosition  = C.zPiece
        alpha      = 1.0

        let moveBack  = SKAction.move(to: homePosition, duration: 0.18)
        moveBack.timingMode = .easeOut
        // Scale 1.0'a don: child node'lar previewCellSize ile olusturuldu
        // setScale(1.0) = onizleme boyutu → dogru tepsi boyutu
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.18)
        run(SKAction.group([moveBack, scaleBack])) {
            completion?()
        }
    }

    // MARK: - Yerlestirme Animasyonu

    /// Parca basariyla yerlestirilince: fade out + tepsi slotundan kaldir
    func playPlaceAnimation(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        run(fadeOut) {
            completion()
        }
    }
}
