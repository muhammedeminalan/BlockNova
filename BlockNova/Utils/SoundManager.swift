// 📁 Utils/SoundManager.swift
// Tüm ses işlemlerini tek yerden yönetir
// SKAction ile çalar — ayrı bir framework gerekmez

import SpriteKit

// final: subclass'lanma engellenir, derleyici static dispatch kullanır — minor performans iyileştirmesi
final class SoundManager {
    static let shared = SoundManager()

    // Ses açık/kapalı — ileride ayarlar eklenirse diye
    var isSoundEnabled = true

    // Sesleri önceden yükle — ilk çalmada gecikme olmasın
    private let placeSound    = SKAction.playSoundFileNamed("pop.wav",          waitForCompletion: false)
    private let clearSound    = SKAction.playSoundFileNamed("long-pop.wav",     waitForCompletion: false)
    private let recordSound   = SKAction.playSoundFileNamed("achievement.wav",  waitForCompletion: false)
    private let gameOverSound = SKAction.playSoundFileNamed("game-over.wav",    waitForCompletion: false)

    // Blok yerleştirince çal
    func playPlace(on node: SKNode) {
        guard isSoundEnabled else { return }
        node.run(placeSound)
    }

    // Çizgi patlaması
    func playClear(on node: SKNode) {
        guard isSoundEnabled else { return }
        node.run(clearSound)
    }

    // Yeni rekor
    func playRecord(on node: SKNode) {
        guard isSoundEnabled else { return }
        node.run(recordSound)
    }

    // Oyun bitti
    func playGameOver(on node: SKNode) {
        guard isSoundEnabled else { return }
        node.run(gameOverSound)
    }
}
