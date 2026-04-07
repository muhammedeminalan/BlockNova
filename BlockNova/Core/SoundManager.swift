// 📁 Utils/SoundManager.swift
// Tüm ses işlemlerini tek yerden yönetir
// SKAction ile çalar — ayrı bir framework gerekmez

import SpriteKit
import QuartzCore

// final: subclass'lanma engellenir, derleyici static dispatch kullanır — minor performans iyileştirmesi
final class SoundManager {
    static let shared = SoundManager()

    // Ses spam'ini engellemek için son çalma zamanları
    private var lastPlayTime: [String: TimeInterval] = [:]

    // Sesleri önceden yükle — ilk çalmada gecikme olmasın
    private let placeSound    = SKAction.playSoundFileNamed("pop.wav",          waitForCompletion: false)
    private let clearSound    = SKAction.playSoundFileNamed("long-pop.wav",     waitForCompletion: false)
    private let recordSound   = SKAction.playSoundFileNamed("achievement.wav",  waitForCompletion: false)
    private let gameOverSound = SKAction.playSoundFileNamed("game-over.wav",    waitForCompletion: false)
    private let invalidSound  = SKAction.playSoundFileNamed("pop.wav",          waitForCompletion: false)
    private let comboSound    = SKAction.playSoundFileNamed("achievement.wav",  waitForCompletion: false)

    // Minimum aralıklar (sn): aynı sesin kısa aralıkla spamlanmasını önler
    private let minIntervals: [String: TimeInterval] = [
        "place":  0.06,
        "clear":  0.12,
        "combo":  0.45,
        "record": 0.80,
        "invalid": 0.25,
        "gameover": 0.80
    ]

    // Blok yerleştirince çal
    func playPlace(on node: SKNode) {
        // SettingsManager'dan kontrol et — kullanıcı sesi kapattıysa çalma
        guard SettingsManager.shared.isSoundEnabled else { return }
        guard shouldPlay(key: "place") else { return }
        node.run(placeSound)
    }

    // Çizgi patlaması
    func playClear(on node: SKNode) {
        // SettingsManager'dan kontrol et — kullanıcı sesi kapattıysa çalma
        guard SettingsManager.shared.isSoundEnabled else { return }
        guard shouldPlay(key: "clear") else { return }
        node.run(clearSound)
    }

    // Combo (2+ çizgi) — belirgin ama spam yapmayan
    func playCombo(on node: SKNode) {
        // SettingsManager'dan kontrol et — kullanıcı sesi kapattıysa çalma
        guard SettingsManager.shared.isSoundEnabled else { return }
        guard shouldPlay(key: "combo") else { return }
        node.run(comboSound)
    }

    // Geçersiz hamle — kısa uyarı
    func playInvalid(on node: SKNode) {
        // SettingsManager'dan kontrol et — kullanıcı sesi kapattıysa çalma
        guard SettingsManager.shared.isSoundEnabled else { return }
        guard shouldPlay(key: "invalid") else { return }
        node.run(invalidSound)
    }

    // Yeni rekor
    func playRecord(on node: SKNode) {
        // SettingsManager'dan kontrol et — kullanıcı sesi kapattıysa çalma
        guard SettingsManager.shared.isSoundEnabled else { return }
        guard shouldPlay(key: "record") else { return }
        node.run(recordSound)
    }

    // Oyun bitti
    func playGameOver(on node: SKNode) {
        // SettingsManager'dan kontrol et — kullanıcı sesi kapattıysa çalma
        guard SettingsManager.shared.isSoundEnabled else { return }
        guard shouldPlay(key: "gameover") else { return }
        node.run(gameOverSound)
    }

    // MARK: - Cooldown Kontrolü

    private func shouldPlay(key: String) -> Bool {
        let now = CACurrentMediaTime()
        let minInterval = minIntervals[key] ?? 0
        if let last = lastPlayTime[key], now - last < minInterval {
            return false
        }
        lastPlayTime[key] = now
        return true
    }
}
