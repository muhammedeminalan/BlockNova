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
        let safeW = max(0, size.width  - safeAreaInsets.left - safeAreaInsets.right)
        let safeH = max(0, size.height - safeAreaInsets.top  - safeAreaInsets.bottom)
        safeAreaFrame = CGRect(
            x: safeAreaInsets.left,
            y: safeAreaInsets.bottom,
            width: safeW,
            height: safeH
        )

        // Kullanılabilir yükseklik: paneller hariç kalan alan
        let usableH = max(0, safeAreaFrame.height - C.topPanelHeight - C.bottomPanelHeight)
        // Grid merkezi safe area içinde, paneller arasında ortalanır
        effectiveGridCenterY = safeAreaFrame.minY + C.bottomPanelHeight + usableH / 2

        // Grid konumu güncelle
        gridNode.position = CGPoint(x: safeAreaFrame.midX, y: effectiveGridCenterY)

        // Üst panel
        layoutTopPanel()
        // Alt panel
        layoutBottomPanel()
        // Tepsi parçaları
        layoutTrayPieces()
    }

    // MARK: - Üst Panel

    /// Skor/rekor etiketleri dahil üst paneli safe area top'a göre konumlandırır
    func layoutTopPanel() {
        let panelTopY = safeAreaFrame.maxY

        guard let panel = topPanelNode else { return }
        panel.size        = CGSize(width: C.screenW, height: C.topPanelHeight)
        panel.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        panel.position    = CGPoint(x: C.screenW / 2, y: panelTopY)

        if let sep = topPanelSeparator {
            updateSeparator(sep, y: panelTopY - C.topPanelHeight)
        }

        let scoreTitleY = panelTopY - C.topPanelHeight * 0.32
        let scoreValueY = panelTopY - C.topPanelHeight * 0.72

        if let lbl = scoreTitleLabel {
            lbl.fontSize = C.screenH * 0.016
            lbl.position = CGPoint(x: C.screenW * 0.28, y: scoreTitleY)
        }
        scoreValueLabel.fontSize = C.screenH * 0.038
        scoreValueLabel.position = CGPoint(x: C.screenW * 0.28, y: scoreValueY)

        if let lbl = highScoreTitleLabel {
            lbl.fontSize = C.screenH * 0.016
            lbl.position = CGPoint(x: C.screenW * 0.72, y: scoreTitleY)
        }
        highScoreValueLabel.fontSize = C.screenH * 0.038
        highScoreValueLabel.position = CGPoint(x: C.screenW * 0.72, y: scoreValueY)
    }

    // MARK: - Alt Panel

    /// Alt paneli safe area bottom'a göre konumlandırır
    func layoutBottomPanel() {
        let panelBottomY = safeAreaFrame.minY

        guard let panel = bottomPanelNode else { return }
        panel.size        = CGSize(width: C.screenW, height: C.bottomPanelHeight)
        panel.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        panel.position    = CGPoint(x: C.screenW / 2, y: panelBottomY)

        if let sep = bottomPanelSeparator {
            updateSeparator(sep, y: panelBottomY + C.bottomPanelHeight)
        }
    }

    // MARK: - Tepsi

    /// Alt tepsi parçalarını safe area bottom'a göre konumlandırır
    func layoutTrayPieces() {
        let slotWidth = C.screenW / 3
        let midY      = safeAreaFrame.minY + C.bottomPanelHeight * 0.50

        for (i, piece) in trayPieces.enumerated() {
            guard let piece else { continue }
            // Sürüklenen parçayı elle hizalama — dokunuş akıcılığı bozulmasın
            if piece === draggedPiece { continue }

            let targetX = slotWidth * CGFloat(i) + slotWidth / 2
            let target  = CGPoint(x: targetX, y: midY)
            piece.position     = target
            piece.homePosition = target
        }
    }

    // MARK: - Separator Yardımcıları

    /// Yatay çizgi oluşturur — panel ayırıcısı için
    func makeSeparator(y: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to:    CGPoint(x: 0,          y: y))
        path.addLine(to: CGPoint(x: C.screenW,  y: y))
        let line = SKShapeNode(path: path)
        line.strokeColor = UIColor(red: 0.25, green: 0.25, blue: 0.45, alpha: 1).sk
        line.lineWidth   = C.screenW * 0.0016
        line.zPosition   = C.zPanel + 0.1
        return line
    }

    /// Mevcut ayırıcı çizgiyi yeni Y konumuna göre günceller
    func updateSeparator(_ line: SKShapeNode, y: CGFloat) {
        let path = CGMutablePath()
        path.move(to:    CGPoint(x: 0,         y: y))
        path.addLine(to: CGPoint(x: C.screenW, y: y))
        line.path      = path
        line.lineWidth = C.screenW * 0.0016
    }
}
