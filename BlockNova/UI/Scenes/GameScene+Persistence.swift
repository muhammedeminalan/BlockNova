// 📁 Scenes/GameScene+Persistence.swift
// Oyun kaydetme/yukleme ve cikis oncesi state hazirlama islemleri.

import SpriteKit
import UIKit

extension GameScene {

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
            score: manager.score,
            highScore: manager.highScore,
            gridColors: gridRenkleri,
            currentPieceTypes: parcaTipleri,
        )
        GameSaveManager.shared.save(state)
    }

    // MARK: - Oyun Geri Yükleme

    /// Kaydedilmiş durumu sahneye uygular: skor, grid ve tepsi parçaları.
    func restoreGameState(_ savedState: SavedGameState) {
        // Manager'ı kayıtlı skorla senkronize et
        manager.restoreScore(savedState.score, highScore: savedState.highScore)

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

        // Tepsi parçalarını rawValue → BlockShapeType → BlockShape zinciriyle yükle
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
            let parca = PieceNode(shape: sekil)
            parca.slotIndex = i
            if i < previewSlots.count {
                let slot = previewSlots[i]
                parca.position = slot.position
                parca.homePosition = slot.position
                slot.piece = parca
                parca.applyPreviewScale(slotSize: slot.size)
            }
            parca.zPosition = C.zPiece
            parca.alpha = 0
            addChild(parca)
            trayPieces[i] = parca

            let gecikme = Double(i) * 0.06
            parca.run(SKAction.sequence([
                SKAction.wait(forDuration: gecikme),
                SKAction.fadeIn(withDuration: 0.18),
            ]))
        }
    }

    // MARK: - Ana Menüye Çıkış Hazırlığı

    /// SwiftUI katmanindan "Ana Menü" cikisi isterken cagirilir.
    /// Gameplay davranisini degistirmez; sadece cikis oncesi state'i guvenle kaydeder.
    func prepareForExitToHome() {
        saveGameState()
    }
}
