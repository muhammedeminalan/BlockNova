// 📁 Nodes/BlockNode.swift
// Tek bir grid hujcresi veya parca blogunun gorsel node'u.
// SKSpriteNode tabanli — hizli renk degisimi icin ideal (texture gerekmez).
// Hem GridNode icindeki sabit hucreler hem de PieceNode icindeki onizleme hucreleri bunu kullanabilir.

import SpriteKit
import UIKit

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

    // MARK: - Renk Guncelleme

    /// Blogun rengini degistirir — node silmeden sadece renk atanir (kasa onleme)
    func setBlockColor(_ color: UIColor) {
        self.color = color
        // Texture kullanilmadigi icin colorBlendFactor 0 olmali
        colorBlendFactor = 0
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

    // MARK: - Temizleme Animasyonu

    /// Cizgi temizlenince flash — patlama hissi icin
    /// completion: tum animasyon bitince cagrilir
    func playClearAnimation(completion: @escaping () -> Void) {
        // Beyaza flash, sonra orijinal renge don
        let flash = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.06)
        let unflash = SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.12)
        let seq = SKAction.sequence([flash, unflash])
        run(seq) {
            completion()
        }
    }
}
