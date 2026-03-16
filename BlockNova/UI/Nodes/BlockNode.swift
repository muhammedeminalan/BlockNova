// 📁 Nodes/BlockNode.swift
// Tek bir grid hujcresi veya parca blogunun gorsel node'u.
// SKSpriteNode tabanli — hizli renk degisimi icin ideal (texture gerekmez).
// Hem GridNode icindeki sabit hucreler hem de PieceNode icindeki onizleme hucreleri bunu kullanabilir.

import SpriteKit
// import UIKit kaldırıldı — SpriteKit zaten UIKit'i dahil eder, duplicate import gereksiz

// MARK: - BlockNode
final class BlockNode: SKSpriteNode {

    // MARK: - Init

    /// size: pikseldeki boyut (cellVisualSize), color: baslangic rengi
    /// Hafif parlama katmani eklenir — bloklarin hacimli gorunmesini saglar
    init(size: CGFloat, color: UIColor) {
        let sz = CGSize(width: size, height: size)
        super.init(texture: nil, color: color, size: sz)

        // Hafif ust highlight — isik yansimasi hissi verir
        let highlight = SKSpriteNode(
            color: UIColor.white.withAlphaComponent(0.18),
            size: CGSize(width: size, height: size * 0.25)
        )
        highlight.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        highlight.position    = CGPoint(x: 0, y: size / 2)
        highlight.zPosition   = 0.1
        addChild(highlight)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) desteklenmez")
    }

    // MARK: - Yerlestirme Animasyonu

    /// Parca yerlestirilince hafif bounce — geri bildirim ve canlilik icin
    func playPlaceAnimation() {
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.05),
            SKAction.scale(to: 1.00, duration: 0.05)
        ])
        run(bounce)
    }

}
