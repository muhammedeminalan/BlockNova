// 📁 Nodes/GridNode.swift
// 8x8 oyun izgarasinin hem gorsel hem de veri katmani.
// TEMEL PRENSIP: cellNodes hicbir zaman silinmez veya yeniden olusturulmaz.
// Sadece renkleri degistirilir — bu, yerlestirme ve temizleme kasasini onler.
// Grid merkez-origin koordinat sistemi kullanir: (0,0) grid'in tam ortasi.

import SpriteKit
import UIKit

// MARK: - GridDelegate
/// Grid olaylarini GameScene'e iletmek icin.
protocol GridDelegate: AnyObject {
    /// Cizgiler temizlendiginde: kac cizgi (satir+sutun toplam)
    func gridDidClearLines(_ count: Int)
    /// Hucreler yerlestirildiginde: kac hucre
    func gridDidPlaceCells(_ count: Int)
}

// MARK: - GridNode
final class GridNode: SKNode {

    // MARK: - Veri Modeli
    /// Renk verisi: nil = bos, UIColor = o hucrenin rengi
    /// row 0 = ust, row 7 = alt; col 0 = sol, col 7 = sag
    private(set) var cellColors: [[UIColor?]]

    // MARK: - Gorsel Katman
    /// 8x8 SKSpriteNode dizisi — bir kez olusturulur, hic silinmez
    /// Renk degisimi icin dogrudan index ile erisilir
    private(set) var cellNodes: [[SKSpriteNode]]

    /// Son highlight edilen hucreler — clearHighlight sadece bunlari gunceller (performans)
    private var highlightedPositions: [(row: Int, col: Int)] = []

    /// Olaylar icin delegate — weak: retain cycle onleme
    weak var delegate: GridDelegate?

    // MARK: - Init
    override init() {
        let rows = C.rows
        let cols = C.cols
        // Tum hucreleri bos baslat — oyun baslangicinda veri temiz olsun
        cellColors = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        // Gecici bos node array — buildGrid'de gercek node'lar atanir
        cellNodes  = Array(repeating: Array(repeating: SKSpriteNode(), count: cols), count: rows)
        super.init()
        // Gorsel grid tek seferde kurulur — tekrar tekrar olusturulmaz
        buildGrid()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) desteklenmez")
    }

    // MARK: - Grid Gorsel Kurulumu

    /// 64 hucreyi olusturur ve konumlandirir. Sadece bir kez cagirilir.
    /// Her hucre sonradan sadece .color ozelligi degistirilerek guncellenir.
    private func buildGrid() {
        let vs = C.cellVisualSize

        // Grid arka plani — hafif rounded panel, grid alanini ayristirir
        // Rounded gorsel yumusaklik verir, modern his yaratir
        let bgW = C.gridTotalWidth  + 16
        let bgH = C.gridTotalHeight + 16
        let bgRect = CGRect(x: -bgW / 2, y: -bgH / 2, width: bgW, height: bgH)
        let bg = SKShapeNode(rect: bgRect, cornerRadius: C.cellSize * 0.35)
        bg.fillColor   = C.gridBgColor.sk
        bg.strokeColor = UIColor.white.withAlphaComponent(0.08).sk
        bg.lineWidth   = 1
        bg.zPosition   = C.zBackground
        addChild(bg)

        // Tum hucreleri olustur — tek seferlik is, daha sonra node yaratilmaz
        for row in 0..<C.rows {
            for col in 0..<C.cols {
                // Hucre merkezinin grid-local koordinati (grid merkezi = 0,0)
                let pos = positionFor(row: row, col: col)

                // Ana hucre node'u — renk degisimi buradan yapilir
                let cell = SKSpriteNode(color: C.cellEmptyColor.sk,
                                        size: CGSize(width: vs, height: vs))
                cell.position  = pos
                cell.zPosition = C.zCell
                addChild(cell)

                // Ince kenarlik — hucre sinirlarini belirginlestirir
                // SKShapeNode child olarak ekleniyor: cell silinmedigi icin hep var
                let borderRect = CGRect(x: -vs / 2, y: -vs / 2, width: vs, height: vs)
                let border = SKShapeNode(rect: borderRect)
                border.fillColor   = .clear
                border.strokeColor = C.cellBorderColor.sk
                border.lineWidth   = C.screenW * 0.0012
                border.zPosition   = 0.1
                cell.addChild(border)

                // Iceri golge hissi — hucreye derinlik katar, dikkat dagitmaz
                let innerShadow = SKSpriteNode(
                    color: UIColor.black.withAlphaComponent(0.12).sk,
                    size: CGSize(width: vs * 0.92, height: vs * 0.92)
                )
                innerShadow.zPosition = 0.05
                cell.addChild(innerShadow)

                // Node referansini sakla — daha sonra renk degisimi icin
                cellNodes[row][col] = cell
            }
        }
    }

    // MARK: - Koordinat Hesabi

    /// (row, col) → GridNode lokal koordinati.
    /// Grid merkezi (0,0); row 0 = en ust, col 0 = en sol.
    /// Bu formül nearestCell ile tutarli olmali — her ikisi de ayni referansi kullanir.
    func positionFor(row: Int, col: Int) -> CGPoint {
        let cs = C.cellSize
        // col → X: sol tarafa negatif, sag tarafa pozitif
        let x = CGFloat(col) * cs - (CGFloat(C.cols) * cs / 2) + cs / 2
        // row → Y: SpriteKit Y yukari, oyun row'u asagi → ters cevir
        let y = (CGFloat(C.rows) * cs / 2) - CGFloat(row) * cs - cs / 2
        return CGPoint(x: x, y: y)
    }

    // MARK: - Sinir Kontrolu

    /// Koordinatin grid sinirlari icinde olup olmadigini kontrol eder
    func isValid(row: Int, col: Int) -> Bool {
        row >= 0 && row < C.rows && col >= 0 && col < C.cols
    }

    // MARK: - En Yakin Hucre

    /// Dunya koordinatini (sahne koordinati) en yakin grid hucrelerine cevirir.
    /// Parcanin TUM offsetleri grid icinde kaliyor ise (row, col) doner, aksi halde nil.
    /// "Blok offset sorunu" burada cozulur: scene koordinati once grid-local'e cevrilir.
    func nearestCell(for worldPosition: CGPoint, piece: PieceNode) -> (row: Int, col: Int)? {
        guard let scene = scene else { return nil }

        // Dunya (sahne) koordinatini grid'in lokal koordinatina cevir
        // Bu cevrim olmadan col/row hesabi hatali olur — kritik adim
        let localPos = convert(worldPosition, from: scene)

        let cs   = C.cellSize
        let half = CGFloat(C.cols) * cs / 2

        // Parcanin gorsel merkezi ile grid hucre merkezi uyusmasi icin anchor offset uygula
        let anchorOffset = piece.gridAnchorOffset(cellSize: cs)
        let anchorPos = CGPoint(x: localPos.x + anchorOffset.x, y: localPos.y + anchorOffset.y)

        // Lokal koordinattan hucre indexi: positionFor'un tersi
        // Round kullan: gorsel merkez hangi hucreye en yakin ise onu secer
        let colFloat = (anchorPos.x + half - cs / 2) / cs
        let rowFloat = (half - cs / 2 - anchorPos.y) / cs
        let col = Int(round(colFloat))
        let row = Int(round(rowFloat))

        // Parcanin tum hucreleri grid icinde mi? Biri bile disariysa yerlestirilemez
        for offset in piece.normalizedOffsets {
            let r = row + offset.row
            let c = col + offset.col
            if !isValid(row: r, col: c) { return nil }
        }

        return (row: row, col: col)
    }

    // MARK: - Highlight

    /// Surukleme sirasinda potansiyel yerlestirme alanini renklendirir.
    /// valid=true → yesil, false → kirmizi
    func highlight(positions: [(row: Int, col: Int)], valid: Bool) {
        // Eski highlight'i temizle — sadece farkli hucreleri guncellemek icin
        clearHighlight()
        let color = valid ? C.highlightValid : C.highlightInvalid
        // Sadece gecerli indeksleri boyar — array bounds hatasi onleme
        for pos in positions where isValid(row: pos.row, col: pos.col) {
            cellNodes[pos.row][pos.col].color = color.sk
        }
        // Bir sonraki clearHighlight icin hangileri highlight edildi sakla
        highlightedPositions = positions.filter { isValid(row: $0.row, col: $0.col) }
    }

    /// Sadece highlight edilmis hucreleri gercek renklerine dondurur.
    /// Tum 64 hucreyi degil, yalnizca birkac hucreyi gunceller — performans kritik.
    func clearHighlight() {
        // Sadece highlight edilmis hucreleri yenile — gereksiz is yapma
        for pos in highlightedPositions {
            refreshCellColor(row: pos.row, col: pos.col)
        }
        highlightedPositions = []
    }

    // MARK: - Yerlestirme Kontrolu

    /// Verilen sekli belirtilen row/col'a yerlestirmek mumkun mu?
    /// Tum hucrelerin bos ve grid icinde olmasi gerekir.
    func canPlace(_ shape: BlockShape, at row: Int, col: Int) -> Bool {
        // Seklin sol-ust referansini almak icin minimum offsetleri bul
        let minRow = shape.offsets.map(\.row).min() ?? 0
        let minCol = shape.offsets.map(\.col).min() ?? 0

        // Tum offset'leri kontrol et — biri bile dolu/disarida ise false
        for offset in shape.offsets {
            let r = row + offset.row - minRow
            let c = col + offset.col - minCol
            guard isValid(row: r, col: c) else { return false }
            if cellColors[r][c] != nil { return false }  // Dolu hucre
        }
        return true
    }

    // MARK: - Yerlestirme

    /// Sekli izgara uzerine yerlestirir: veri gunceller, gorsel gunceller, animasyon oynatir.
    /// Delegate'e yerlestirilen hucre sayisini bildirir, sonra cizgi kontrolu yapar.
    @discardableResult
    func place(_ shape: BlockShape, at row: Int, col: Int) -> Bool {
        // Yerlesebilirlik kontrolu olmadan yazma yok — veri butunlugunu korur
        guard canPlace(shape, at: row, col: col) else { return false }

        // Seklin sol-ust referansini almak icin minimum offsetleri bul
        let minRow = shape.offsets.map(\.row).min() ?? 0
        let minCol = shape.offsets.map(\.col).min() ?? 0

        // Tum offset'leri grid'e yaz — her hucre renklenir
        for offset in shape.offsets {
            let r = row + offset.row - minRow
            let c = col + offset.col - minCol
            fillCell(row: r, col: c, color: shape.color)
            // Bounce animasyonu — her hucre yerlestiginde canlanir
            cellNodes[r][c].playPlaceAnimation()
        }

        // Skor hesaplamasi icin delegate'e bildir
        delegate?.gridDidPlaceCells(shape.cellCount)
        // Yerlesimden sonra cizgi temizleme kontrolu
        checkAndClearLines()
        return true
    }

    // MARK: - Hucre Doldurma / Bosaltma

    /// Hucreyi doldurur: veri + gorsel gunceller. Node SILINMEZ.
    func fillCell(row: Int, col: Int, color: UIColor) {
        guard isValid(row: row, col: col) else { return }
        cellColors[row][col] = color
        cellNodes[row][col].color = color.sk
    }

    /// Hucreyi bosaltir: veri nil, gorsel bos renk. Node SILINMEZ.
    func clearCell(row: Int, col: Int) {
        guard isValid(row: row, col: col) else { return }
        cellColors[row][col] = nil
        cellNodes[row][col].color = C.cellEmptyColor.sk
        cellNodes[row][col].alpha = 1
        cellNodes[row][col].setScale(1)
    }

    // MARK: - Cizgi Kontrolu ve Temizleme

    /// Her yerlestirmeden sonra cagirilir.
    /// Dolu satir ve sutunlari bulur, flash animasyonu oynatir, sonra temizler.
    /// Node olusturulmuyor — mevcut node'lara animasyon uygulanir (kasa onleme).
    private func checkAndClearLines() {
        var rowsToClear: [Int] = []
        var colsToClear: [Int] = []

        // Dolu satirlari bul — her satirda 8 hucre dolu mu bak
        for row in 0..<C.rows {
            if (0..<C.cols).allSatisfy({ cellColors[row][$0] != nil }) {
                rowsToClear.append(row)
            }
        }
        // Dolu sutunlari bul — her sutunda 8 hucre dolu mu bak
        for col in 0..<C.cols {
            if (0..<C.rows).allSatisfy({ cellColors[$0][col] != nil }) {
                colsToClear.append(col)
            }
        }

        // Hic cizgi yoksa erken cik — gereksiz animasyon yok
        guard !rowsToClear.isEmpty || !colsToClear.isEmpty else { return }

        // Temizlenecek benzersiz hucre node'lari — hem satir hem sutun kesisebilir
        var affectedNodes: [SKSpriteNode] = []
        var affectedCoords: Set<String>   = []

        // Ayni hucreyi iki kez eklememek icin koordinat seti kullan
        func addCoord(_ r: Int, _ c: Int) {
            let key = "\(r),\(c)"
            if affectedCoords.insert(key).inserted {
                affectedNodes.append(cellNodes[r][c])
            }
        }

        // Satir hucrelerini ekle
        for row in rowsToClear { for col in 0..<C.cols { addCoord(row, col) } }
        // Sutun hucrelerini ekle
        for col in colsToClear { for row in 0..<C.rows { addCoord(row, col) } }

        // Flash animasyonu: beyaza gecip geri don — patlama hissi
        let flashOn  = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.05)
        let flashOff = SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.12)
        let flash    = SKAction.sequence([flashOn, flashOff])

        // Tum etkilenmis hucrelere animasyon uygula
        for node in affectedNodes { node.run(flash) }

        // Animasyon bittikten sonra veri ve gorsel temizle
        let lineCount = rowsToClear.count + colsToClear.count
        run(SKAction.wait(forDuration: 0.18)) { [weak self] in
            guard let self = self else { return }
            // Satirlari temizle
            for row in rowsToClear { for col in 0..<C.cols { self.clearCell(row: row, col: col) } }
            // Sutunlari temizle
            for col in colsToClear { for row in 0..<C.rows { self.clearCell(row: row, col: col) } }
            // Skor icin delegate'i bilgilendir
            self.delegate?.gridDidClearLines(lineCount)
        }
    }

    // MARK: - Hucre Renk Yenileme

    /// Hucreyi veri modeline gore renklendirir — dolu: blok rengi, bos: empty rengi
    private func refreshCellColor(row: Int, col: Int) {
        guard isValid(row: row, col: col) else { return }
        if let color = cellColors[row][col] {
            cellNodes[row][col].color = color.sk
        } else {
            cellNodes[row][col].color = C.cellEmptyColor.sk
        }
    }

    // MARK: - Oyun Bitti Kontrolu

    /// Verilen sekil listesinden herhangi biri grid'e sigiyor mu?
    /// Sigan varsa false (oyun devam), hicbiri sigmiyorsa true (oyun bitti)
    func noPieceFits(shapes: [BlockShape]) -> Bool {
        // Tum sekilleri tek tek dene — herhangi biri sigarsa oyun devam eder
        for shape in shapes {
            if canPlaceAnywhere(shape: shape) { return false }
        }
        return true
    }

    /// Bir sekli grid'in tum olasi pozisyonlarinda dener
    private func canPlaceAnywhere(shape: BlockShape) -> Bool {
        // 8x8 tum kombinasyonlari dene — kaba kuvvet ama kucuk alan, hizli
        for row in 0..<C.rows {
            for col in 0..<C.cols {
                if canPlace(shape, at: row, col: col) { return true }
            }
        }
        return false
    }

    // MARK: - Sifirlama

    /// Tum hucreleri bosaltir — yeni oyun basladiginda cagirilir
    func reset() {
        // Tum grid'i tek tek temizle — data ve gorsel sifirlanir
        for row in 0..<C.rows {
            for col in 0..<C.cols {
                clearCell(row: row, col: col)
            }
        }
    }
}

// MARK: - SKSpriteNode Uzantisi (GridNode ici kullanim)
private extension SKSpriteNode {
    /// Yerlestirme bounce animasyonu — kisa ve hafif, kasa yaratmaz
    func playPlaceAnimation() {
        removeAction(forKey: "bounce")
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.10, duration: 0.05),
            SKAction.scale(to: 1.00, duration: 0.05)
        ])
        run(bounce, withKey: "bounce")
    }
}
