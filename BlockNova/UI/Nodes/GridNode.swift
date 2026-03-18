// 📁 Nodes/GridNode.swift
// 8x8 oyun izgarasinin hem gorsel hem de veri katmani.
// TEMEL PRENSIP: cellNodes hicbir zaman silinmez veya yeniden olusturulmaz.
// Sadece renkleri degistirilir — bu, yerlestirme ve temizleme kasasini onler.
// Grid merkez-origin koordinat sistemi kullanir: (0,0) grid'in tam ortasi.

import SpriteKit
// import UIKit kaldırıldı — SpriteKit zaten UIKit'i dahil eder, duplicate import gereksiz

// MARK: - GridDelegate
/// Grid olaylarini GameScene'e iletmek icin.
protocol GridDelegate: AnyObject {
    /// Cizgiler temizlendiginde: kac cizgi (satir+sutun toplam)
    func gridDidClearLines(_ count: Int)
    /// Hucreler yerlestirildiginde: kac hucre
    func gridDidPlaceCells(_ count: Int)
    /// Yerlestirme islemi tamamen bitti (cizgi temizleme dahil) — game over kontrolu icin
    func gridDidFinishPlacement()
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

    /// Patlama partikül sayacı — scene.children taraması yerine kullanılır
    private var activeExplodeParticles: Int = 0

    /// FX partikül sayacı — scene.children taraması yerine kullanılır
    private var activeSpawnParticles: Int = 0

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

    // MARK: - Satir/Sutun Dolacak Preview

    /// Yerleştirince dolacak satırları hesaplar — preview icin
    func rowsThatWillClear(if shape: BlockShape, at startRow: Int, col startCol: Int) -> [Int] {
        var tempCells = cellColors
        // Seklin sol-ust referansini hizalamak icin min offsetleri kullan
        let minRow = shape.offsets.map(\.row).min() ?? 0
        let minCol = shape.offsets.map(\.col).min() ?? 0

        for offset in shape.offsets {
            let r = startRow + offset.row - minRow
            let c = startCol + offset.col - minCol
            guard r >= 0, r < C.rows, c >= 0, c < C.cols else { continue }
            tempCells[r][c] = UIColor.white
        }

        return (0..<C.rows).filter { row in
            (0..<C.cols).allSatisfy { tempCells[row][$0] != nil }
        }
    }

    /// Yerleştirince dolacak sütunları hesaplar — preview icin
    func colsThatWillClear(if shape: BlockShape, at startRow: Int, col startCol: Int) -> [Int] {
        var tempCells = cellColors
        let minRow = shape.offsets.map(\.row).min() ?? 0
        let minCol = shape.offsets.map(\.col).min() ?? 0

        for offset in shape.offsets {
            let r = startRow + offset.row - minRow
            let c = startCol + offset.col - minCol
            guard r >= 0, r < C.rows, c >= 0, c < C.cols else { continue }
            tempCells[r][c] = UIColor.white
        }

        return (0..<C.cols).filter { col in
            (0..<C.rows).allSatisfy { tempCells[$0][col] != nil }
        }
    }

    /// Dolacak satır/sütun hücrelerini yanıp söndürür
    func flashWillClear(rows: [Int], cols: [Int]) {
        var affectedCells: [SKSpriteNode] = []

        for row in rows {
            for col in 0..<C.cols { affectedCells.append(cellNodes[row][col]) }
        }
        for col in cols {
            for row in 0..<C.rows {
                if !rows.contains(row) { affectedCells.append(cellNodes[row][col]) }
            }
        }

        let flashColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1).sk

        for cell in affectedCells {
            cell.removeAction(forKey: "willClearFlash")
            // Patlama olacaksa tek renk goster — daha net sinyal
            cell.color = flashColor
        }
    }

    /// Sürükleme bitince preview flash temizlenir
    func clearWillClearFlash() {
        for row in 0..<C.rows {
            for col in 0..<C.cols {
                let cell = cellNodes[row][col]
                cell.removeAction(forKey: "willClearFlash")
                let originalColor = cellColors[row][col] ?? C.cellEmptyColor
                cell.color = originalColor.sk
            }
        }
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

    /// Normalize offset ile hizli kontrol — drag sırasında performans için.
    /// normalizedOffsets: minRow/minCol sıfırlanmış olmalı.
    func canPlace(normalizedOffsets: [(row: Int, col: Int)], at row: Int, col: Int) -> Bool {
        for offset in normalizedOffsets {
            let r = row + offset.row
            let c = col + offset.col
            guard isValid(row: r, col: c) else { return false }
            if cellColors[r][c] != nil { return false }
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
    /// Dolu satir ve sutunlari bulur, efekt oynatir, sonra temizler.
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
        guard !rowsToClear.isEmpty || !colsToClear.isEmpty else {
            delegate?.gridDidFinishPlacement()
            return
        }

        // Temizlenecek benzersiz hucre node'lari ve duny koordinatlari
        // Koordinat seti: ayni hucreyi iki kez islememek icin (satir-sutun kesisimi)
        var affectedNodes:  [SKSpriteNode] = []
        var affectedColors: [UIColor]      = []   // Her hucrenin o anki rengi — partikul rengine eslesir
        var affectedWorldPositions: [CGPoint] = [] // Partikul icin dunya koordinati
        var affectedCoords: Set<String>    = []

        func addCoord(_ r: Int, _ c: Int) {
            let key = "\(r),\(c)"
            guard affectedCoords.insert(key).inserted else { return }
            let node = cellNodes[r][c]
            affectedNodes.append(node)
            // Hucrenin rengi: dolu ise blok rengi, yoksa varsayilan
            affectedColors.append(cellColors[r][c] ?? C.cellEmptyColor)
            // Grid-lokal koordinati sahne koordinatina cevir — partikul pozisyonu icin
            if let scene = self.scene {
                affectedWorldPositions.append(convert(positionFor(row: r, col: c), to: scene))
            } else {
                affectedWorldPositions.append(positionFor(row: r, col: c))
            }
        }

        for row in rowsToClear { for col in 0..<C.cols { addCoord(row, col) } }
        for col in colsToClear { for row in 0..<C.rows { addCoord(row, col) } }

        let lineCount = rowsToClear.count + colsToClear.count

        // Combo seviyesine gore patlama animasyonu uygula
        explodeLine(cells: affectedNodes, lineCount: lineCount) { [weak self] in
            guard let self = self else { return }
            // Patlama bittikten sonra hucreleri temizle
            for row in rowsToClear { for col in 0..<C.cols { self.clearCell(row: row, col: col) } }
            for col in colsToClear { for row in 0..<C.rows { self.clearCell(row: row, col: col) } }
            self.delegate?.gridDidClearLines(lineCount)
            self.delegate?.gridDidFinishPlacement()
        }
    }

    // MARK: - Patlama Animasyonu

    /// Tek bir hucreyi parcalara bolup patlatir
    private func explodeCell(_ cell: SKSpriteNode, distanceRange: ClosedRange<CGFloat>, duration: TimeInterval, completion: @escaping () -> Void) {
        guard let scene = scene else {
            completion()
            return
        }

        // Parca siniri: ayni anda max 150
        guard activeExplodeParticles < 150 else {
            cell.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                cell.isHidden = false
                completion()
            }
            return
        }

        let cellColor = cell.color
        let worldPos = cell.parent?.convert(cell.position, to: scene) ?? cell.position

        // Hücreyi gizle
        cell.isHidden = true

        let particleCount = 7
        for i in 0..<particleCount {
            let size = CGFloat.random(in: cell.size.width * 0.2 ... cell.size.width * 0.45)
            let particle = SKSpriteNode(color: cellColor, size: CGSize(width: size, height: size))
            particle.position = worldPos
            particle.zPosition = 150
            particle.alpha = 1.0
            scene.addChild(particle)
            activeExplodeParticles += 1

            let angle = (CGFloat(i) / CGFloat(particleCount)) * 2 * .pi + CGFloat.random(in: -0.3...0.3)
            let distance = CGFloat.random(in: distanceRange)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let flyOut = SKAction.group([
                SKAction.moveBy(x: dx, y: dy, duration: duration),
                SKAction.rotate(byAngle: CGFloat.random(in: -.pi ... .pi), duration: duration),
                SKAction.scale(to: 0.1, duration: duration),
                SKAction.fadeOut(withDuration: duration * 0.85)
            ])

            let decrement = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.activeExplodeParticles = max(0, self.activeExplodeParticles - 1)
            }
            particle.run(SKAction.sequence([
                flyOut,
                decrement,
                SKAction.removeFromParent()
            ]))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            cell.isHidden = false
            completion()
        }
    }

    /// Satır/sütun patlaması — dalga efekti
    private func explodeLine(cells: [SKSpriteNode], lineCount: Int, completion: @escaping () -> Void) {
        var completed = 0
        let total = cells.count

        let distanceRange: ClosedRange<CGFloat>
        let duration: TimeInterval

        switch lineCount {
        case 1:
            distanceRange = 25...55
            duration = 0.35
        case 2:
            distanceRange = 40...80
            duration = 0.30
        default:
            distanceRange = 60...120
            duration = 0.32
        }

        for (index, cell) in cells.enumerated() {
            let delay = Double(index) * 0.03
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }

                if lineCount == 2 {
                    // Double combo icin kisa sari-turuncu flash
                    let originalColor = cell.color
                    let flash = SKAction.sequence([
                        SKAction.run { cell.color = UIColor(red: 1, green: 0.8, blue: 0, alpha: 1).sk },
                        SKAction.wait(forDuration: 0.06),
                        SKAction.run { cell.color = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1).sk },
                        SKAction.wait(forDuration: 0.10),
                        SKAction.run { cell.color = originalColor }
                    ])
                    cell.run(flash) { [weak self] in
                        self?.explodeCell(cell, distanceRange: distanceRange, duration: duration) {
                            completed += 1
                            if completed >= total {
                                completion()
                            }
                        }
                    }
                } else {
                    self.explodeCell(cell, distanceRange: distanceRange, duration: duration) {
                        completed += 1
                        if completed >= total {
                            completion()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Cizgi Kirma Efekti

    /// Kirik cizgi sayisina gore dogru efekti secer ve tetikler.
    /// Tek cizgi: sade flash + scatter
    /// Double (2): altin flash + daha fazla partikul
    /// Mega (3+): ekran sarsintisi + cyan flash + yogun partikul
    private func playLineClearEffect(lineCount: Int,
                                     nodes: [SKSpriteNode],
                                     colors: [UIColor],
                                     worldPositions: [CGPoint]) {
        switch lineCount {
        case 1:
            singleClearEffect(nodes: nodes, colors: colors, worldPositions: worldPositions)
        case 2:
            doubleClearEffect(nodes: nodes, worldPositions: worldPositions)
        default:
            megaClearEffect(nodes: nodes, worldPositions: worldPositions)
        }
    }

    /// Tek cizgi efekti: beyaz flash + hucrelerin dagilan parcaciklari
    /// colorize kullanilmaz — texture'siz node'da gorunsuz kalir.
    /// Bunun yerine SKAction.run ile .color property'si dogrudan degistirilir.
    private func singleClearEffect(nodes: [SKSpriteNode],
                                   colors: [UIColor],
                                   worldPositions: [CGPoint]) {
        for node in nodes {
            // .color dogrudan beyaza set edilip gecikme sonrasi bos renge dondurulur
            node.run(SKAction.sequence([
                SKAction.run { node.color = .white },
                SKAction.wait(forDuration: 0.07),
                SKAction.run { node.color = C.cellEmptyColor.sk }
            ]))
        }
        // Her hucrenin kendi rengiyle 6 partikul — renk eslesmesi dogal gorunum saglar
        for (pos, color) in zip(worldPositions, colors) {
            spawnParticles(at: pos, color: color, count: 6)
        }
    }

    /// Double efekti: altin flash + 10 partikul
    /// colorize yerine dogrudan .color atamasi — texture'siz node'da tek calisaн yol
    private func doubleClearEffect(nodes: [SKSpriteNode],
                                   worldPositions: [CGPoint]) {
        let altın = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        for node in nodes {
            node.run(SKAction.sequence([
                SKAction.run { node.color = altın.sk },
                SKAction.wait(forDuration: 0.10),
                SKAction.run { node.color = C.cellEmptyColor.sk }
            ]))
        }
        // Normalin ~1.5 kati partikul — combo gucunu hissettirir
        for pos in worldPositions {
            spawnParticles(at: pos, color: altın, count: 10)
        }
    }

    /// Mega efekti (3+): ekran sarsintisi + cyan flash + yogun partikul
    /// colorize yerine dogrudan .color atamasi — texture'siz node'da tek calisан yol
    private func megaClearEffect(nodes: [SKSpriteNode],
                                  worldPositions: [CGPoint]) {
        // Ekran sarsintisi: camera veya scene'i bul ve shake uygula — yogunluk hissi verir
        scene?.run(SKAction.sequence([
            SKAction.moveBy(x: -7, y: 0, duration: 0.03),
            SKAction.moveBy(x: 14, y: 0, duration: 0.04),
            SKAction.moveBy(x: -14, y: 0, duration: 0.04),
            SKAction.moveBy(x: 7,  y: 0, duration: 0.03)
        ]))

        let cyan = UIColor(red: 0, green: 0.9, blue: 1, alpha: 1)
        for node in nodes {
            node.run(SKAction.sequence([
                SKAction.run { node.color = cyan.sk },
                SKAction.wait(forDuration: 0.13),
                SKAction.run { node.color = C.cellEmptyColor.sk }
            ]))
        }
        // En yogun partikul patlamas — hucre basina 15 ile sinirli (kasa onleme)
        for pos in worldPositions {
            spawnParticles(at: pos, color: cyan, count: 15)
        }
    }

    // MARK: - Partikul Sistemi

    /// Belirtilen dunya konumuna renk ve sayida partikul firlatiir.
    /// SKEmitterNode yerine elle SKSpriteNode — .sks dosyasi gerekmez, her zaman calisiir.
    /// Partikul animasyon bittikten sonra removeFromParent ile kendini siler — bellek temiz kalir.
    ///
    /// Partikül sınırı: sahnede aynı anda max 120 partikül olabilir.
    /// Mega combo'da 24 hücre × 15 = 360 partikül düşük RAM cihazlarda kasa yaratır.
    /// Bu sınır ile düşük RAM'li cihazlarda (iPhone SE, iPod Touch) frame drop önlenir.
    private func spawnParticles(at worldPosition: CGPoint, color: UIColor, count: Int) {
        // Partikulleri sahneye ekle — GridNode'a degil, boylece grid transformundan etkilenmez
        guard let targetScene = self.scene else { return }

        // Sahnedeki mevcut partikül sayısını kontrol et — 120'yi geçiyorsa spawn etme
        // Düşük RAM cihazlarda kasa önlenir
        guard activeSpawnParticles < 120 else { return }

        // Sınırı aşmamak için gerçek spawn sayısını hesapla
        let gercekCount = min(count, 120 - activeSpawnParticles)

        for _ in 0..<gercekCount {
            let size = CGFloat.random(in: 4...8)
            let particle = SKSpriteNode(color: color.sk,
                                        size: CGSize(width: size, height: size))
            particle.name      = "partikul"  // Sayım için isim — sınır kontrolünde kullanılır
            particle.position  = worldPosition
            particle.zPosition = 150    // Her seyin onunde gorunsun
            particle.alpha     = 0.9
            targetScene.addChild(particle)
            activeSpawnParticles += 1

            // Rastgele yon ve mesafe — her partikul farkli yonde ucar
            let angle    = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 25...60)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            // Hareket + kuculme + solma ayni anda — 0.35sn: yeterince uzun ama kasa yapmaz
            let decrement = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.activeSpawnParticles = max(0, self.activeSpawnParticles - 1)
            }
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.35),
                    SKAction.fadeOut(withDuration: 0.35),
                    SKAction.scale(to: 0.1, duration: 0.35)
                ]),
                decrement,
                SKAction.removeFromParent()
            ]))
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
