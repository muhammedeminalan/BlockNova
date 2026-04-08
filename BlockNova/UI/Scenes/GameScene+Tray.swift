// 📁 Scenes/GameScene+Tray.swift
// Alt tepsi parcasi uretimi ve sahnede kalmis yetim parca temizligi.

import SpriteKit

extension GameScene {

    // MARK: - Parça Dağıtma

    /// Tepsi state'iyle eşleşmeyen eski PieceNode'ları temizler.
    /// Neden: Bazı cihazlarda animation completion kaçarsa eski node sahnede kalıp
    /// yeni gelen parçalarla üst üste binebiliyor.
    func removeOrphanTrayPieces() {
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
        let shapes = shapeDispenser.nextSet(for: gridNode.cellColors)

        for (i, shape) in shapes.enumerated() {
            let piece = PieceNode(shape: shape)
            piece.slotIndex = i
            if i < previewSlots.count {
                let slot = previewSlots[i]
                piece.position = slot.position
                piece.homePosition = slot.position
                slot.piece = piece
                piece.applyPreviewScale(slotSize: slot.size)
            }
            piece.zPosition = C.zPiece
            piece.alpha = 0
            addChild(piece)
            trayPieces[i] = piece

            // Fade-in — slide animasyonu kasaya neden olabilir
            let delay = Double(i) * 0.07
            piece.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.20),
            ]))
        }
    }
}
