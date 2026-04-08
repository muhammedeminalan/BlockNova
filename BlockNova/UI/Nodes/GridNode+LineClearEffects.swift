// 📁 Nodes/GridNode+LineClearEffects.swift
// Cizgi temizleme, patlama ve partikül efektleri.

import SpriteKit

extension GridNode {

    // MARK: - Cizgi Kontrolu ve Temizleme

    /// Her yerlestirmeden sonra cagirilir.
    /// Dolu satir ve sutunlari bulur, efekt oynatir, sonra temizler.
    /// Node olusturulmuyor — mevcut node'lara animasyon uygulanir (kasa onleme).
    func checkAndClearLines() {
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
        var affectedNodes: [SKSpriteNode] = []
        var affectedColors: [UIColor] = [] // Her hucrenin o anki rengi — partikul rengine eslesir
        var affectedWorldPositions: [CGPoint] = [] // Partikul icin dunya koordinati
        var affectedCoords: Set<String> = []

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

        for row in rowsToClear {
            for col in 0..<C.cols { addCoord(row, col) }
        }
        for col in colsToClear {
            for row in 0..<C.rows { addCoord(row, col) }
        }

        let lineCount = rowsToClear.count + colsToClear.count

        // Combo seviyesine gore patlama animasyonu uygula
        explodeLine(cells: affectedNodes, lineCount: lineCount) { [weak self] in
            guard let self = self else { return }
            // Patlama bittikten sonra hucreleri temizle
            for row in rowsToClear {
                for col in 0..<C.cols { self.clearCell(row: row, col: col) }
            }
            for col in colsToClear {
                for row in 0..<C.rows { self.clearCell(row: row, col: col) }
            }
            self.delegate?.gridDidClearLines(lineCount, clearedCellWorldPositions: affectedWorldPositions)
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
                SKAction.fadeOut(withDuration: duration * 0.85),
            ])

            let decrement = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.activeExplodeParticles = max(0, self.activeExplodeParticles - 1)
            }
            particle.run(SKAction.sequence([
                flyOut,
                decrement,
                SKAction.removeFromParent(),
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
        case 4:
            distanceRange = 70...130
            duration = 0.28
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
                        SKAction.run { cell.color = originalColor },
                    ])
                    cell.run(flash) { [weak self] in
                        self?.explodeCell(cell, distanceRange: distanceRange, duration: duration) {
                            completed += 1
                            if completed >= total {
                                completion()
                            }
                        }
                    }
                } else if lineCount == 4 {
                    // 4 cizgi combo icin daha parlak mavi-mor flash.
                    let originalColor = cell.color
                    let flash = SKAction.sequence([
                        SKAction.run { cell.color = UIColor(red: 0.62, green: 0.36, blue: 1.0, alpha: 1).sk },
                        SKAction.wait(forDuration: 0.05),
                        SKAction.run { cell.color = UIColor(red: 0.20, green: 0.90, blue: 1.0, alpha: 1).sk },
                        SKAction.wait(forDuration: 0.08),
                        SKAction.run { cell.color = originalColor },
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
                SKAction.run { node.color = C.cellEmptyColor.sk },
            ]))
        }
        // Her hucrenin kendi rengiyle 6 partikul — renk eslesmesi dogal gorunum saglar
        for (pos, color) in zip(worldPositions, colors) {
            spawnParticles(at: pos, color: color, count: 6)
        }
    }

    /// Double efekti: altin flash + 10 partikul
    /// colorize yerine dogrudan .color atamasi — texture'siz node'da tek calisan yol
    private func doubleClearEffect(nodes: [SKSpriteNode],
                                   worldPositions: [CGPoint]) {
        let altin = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        for node in nodes {
            node.run(SKAction.sequence([
                SKAction.run { node.color = altin.sk },
                SKAction.wait(forDuration: 0.10),
                SKAction.run { node.color = C.cellEmptyColor.sk },
            ]))
        }
        // Normalin ~1.5 kati partikul — combo gucunu hissettirir
        for pos in worldPositions {
            spawnParticles(at: pos, color: altin, count: 10)
        }
    }

    /// Mega efekti (3+): ekran sarsintisi + cyan flash + yogun partikul
    /// colorize yerine dogrudan .color atamasi — texture'siz node'da tek calisan yol
    private func megaClearEffect(nodes: [SKSpriteNode],
                                 worldPositions: [CGPoint]) {
        // Ekran sarsintisi: camera veya scene'i bul ve shake uygula — yogunluk hissi verir
        scene?.run(SKAction.sequence([
            SKAction.moveBy(x: -7, y: 0, duration: 0.03),
            SKAction.moveBy(x: 14, y: 0, duration: 0.04),
            SKAction.moveBy(x: -14, y: 0, duration: 0.04),
            SKAction.moveBy(x: 7, y: 0, duration: 0.03),
        ]))

        let cyan = UIColor(red: 0, green: 0.9, blue: 1, alpha: 1)
        for node in nodes {
            node.run(SKAction.sequence([
                SKAction.run { node.color = cyan.sk },
                SKAction.wait(forDuration: 0.13),
                SKAction.run { node.color = C.cellEmptyColor.sk },
            ]))
        }
        // En yogun partikul patlamasi — hucre basina 15 ile sinirli (kasa onleme)
        for pos in worldPositions {
            spawnParticles(at: pos, color: cyan, count: 15)
        }
    }

    // MARK: - Partikul Sistemi

    /// Belirtilen dunya konumuna renk ve sayida partikul firlatir.
    /// SKEmitterNode yerine elle SKSpriteNode — .sks dosyasi gerekmez, her zaman calisir.
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
            particle.name = "partikul" // Sayım için isim — sınır kontrolünde kullanılır
            particle.position = worldPosition
            particle.zPosition = 150 // Her seyin onunde gorunsun
            particle.alpha = 0.9
            targetScene.addChild(particle)
            activeSpawnParticles += 1

            // Rastgele yon ve mesafe — her partikul farkli yonde ucar
            let angle = CGFloat.random(in: 0...(2 * .pi))
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
                    SKAction.scale(to: 0.1, duration: 0.35),
                ]),
                decrement,
                SKAction.removeFromParent(),
            ]))
        }
    }
}
