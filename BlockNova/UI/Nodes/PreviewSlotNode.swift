// 📁 Nodes/PreviewSlotNode.swift
// Alt tepsi için slot/container node'u.
// Hit-test bu node üzerinden yapılır, parça seçimleri daha affedici olur.

import SpriteKit

final class PreviewSlotNode: SKSpriteNode {

    let index: Int
    weak var piece: PieceNode?

    init(index: Int, size: CGSize) {
        self.index = index
        super.init(texture: nil, color: .clear, size: size)
        isUserInteractionEnabled = false
        zPosition = C.zPanel + 0.05
        alpha = 0.001
        name = "previewSlot_\(index)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) desteklenmez")
    }

    func updateSize(_ size: CGSize) {
        self.size = size
    }
}
