// 📁 Scenes/GameScene+Layout.swift
// Tüm safe-area tabanlı yerleşim mantığı.
// GameScene ana dosyasını ince tutar — layout hesapları ve panel güncellemeleri burada.

import SpriteKit
import UIKit

// MARK: - Layout

extension GameScene {

    /// Tüm node'ları safe area'ya göre yeniden konumlandırır.
    /// Safe area değişince veya sahne boyutu değişince çağrılır.
    func layoutScene() {
        // Sabit boyut değişimi olursa merkezi hesaplar güncellensin
        C.updateSceneSize(size)

        // Safe area frame hesapla — üst/alt/yan güvenli alanları dikkate al
        let safeW = max(
            0,
            size.width - safeAreaInsets.left - safeAreaInsets.right
        )
        let safeH = max(
            0,
            size.height - safeAreaInsets.top - safeAreaInsets.bottom
        )
        safeAreaFrame = CGRect(
            x: safeAreaInsets.left,
            y: safeAreaInsets.bottom,
            width: safeW,
            height: safeH
        )

        // Kullanılabilir yükseklik: paneller hariç kalan alan
        let usableH = max(
            0,
            safeAreaFrame.height - C.topPanelHeight - C.bottomPanelHeight
        )
        // Grid merkezi safe area içinde, paneller arasında ortalanır
        effectiveGridCenterY =
            safeAreaFrame.minY + C.bottomPanelHeight + usableH / 2

        // Grid konumu güncelle
        gridNode.position = CGPoint(
            x: safeAreaFrame.midX,
            y: effectiveGridCenterY
        )

        // Alt panel
        layoutBottomPanel()
        // Preview slotları
        layoutPreviewSlots()
        // Tepsi parçaları
        layoutTrayPieces()
    }

    // MARK: - Alt Panel

    /// Alt paneli safe area bottom'a göre konumlandırır
    func layoutBottomPanel() {
        let panelBottomY = safeAreaFrame.minY

        guard let panel = bottomPanelNode else { return }
        panel.size = CGSize(width: C.screenW, height: C.bottomPanelHeight)
        panel.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        panel.position = CGPoint(x: C.screenW / 2, y: panelBottomY)
    }

    // MARK: - Tepsi

    /// Alt tepsi parçalarını safe area bottom'a göre konumlandırır
    func layoutTrayPieces() {
        for (i, slot) in previewSlots.enumerated() {
            guard let piece = slot.piece else { continue }
            if piece === draggedPiece { continue }
            piece.position = slot.position
            piece.homePosition = slot.position
            piece.applyPreviewScale(slotSize: slot.size)
            trayPieces[i] = piece
        }
    }

    // MARK: - Preview Slot Layout

    /// Preview slotlarını safe area bottom'a göre konumlandırır
    func layoutPreviewSlots() {
        let slotWidth = C.screenW / 3
        let midY = safeAreaFrame.minY + C.bottomPanelHeight * 0.50

        for i in 0..<previewSlots.count {
            let slot = previewSlots[i]
            let targetX = slotWidth * CGFloat(i) + slotWidth / 2
            slot.position = CGPoint(x: targetX, y: midY)
            slot.updateSize(C.previewSlotSize)
        }
    }

}
