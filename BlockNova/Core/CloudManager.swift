// 📁 Core/CloudManager.swift
// iCloud key-value storage ile high score yonetimi
// Uygulama silinip yeniden yuklenince skor korunur
// iCloud erisilemezse UserDefaults'a fallback yapar

import Foundation

final class CloudManager {
    static let shared = CloudManager()
    private init() {
        // iCloud degisikliklerini dinle
        // Baska cihazdan skor gelince otomatik guncelle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        // iCloud'u senkronize et
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    // Rekor anahtari — mevcut anahtar ile uyumlu kalsin
    private let highScoreKey = C.highScoreKey

    // High score'u kaydet
    // Hem iCloud hem UserDefaults'a yazar — ikili guvenlik
    func saveHighScore(_ score: Int) {
        // Sadece yeni rekor ise kaydet
        let current = loadHighScore()
        guard score > current else { return }

        // iCloud'a kaydet
        NSUbiquitousKeyValueStore.default.set(score, forKey: highScoreKey)
        NSUbiquitousKeyValueStore.default.synchronize()

        // UserDefaults'a da kaydet (fallback)
        UserDefaults.standard.set(score, forKey: highScoreKey)
    }

    // High score'u yukle
    // iCloud'ta varsa oradan al, yoksa UserDefaults'tan al
    func loadHighScore() -> Int {
        let iCloudScore = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: highScoreKey))
        let localScore = UserDefaults.standard.integer(forKey: highScoreKey)

        // Ikisinden buyuk olani al — veri kaybini onler
        let best = max(iCloudScore, localScore)

        // Eger iCloud'taki local'den buyukse local'i guncelle
        if iCloudScore > localScore {
            UserDefaults.standard.set(iCloudScore, forKey: highScoreKey)
        }

        return best
    }

    // iCloud'tan disaridan degisiklik gelince cagrilir
    // Baska bir cihazda yuksek skor yapilinca bu tetiklenir
    @objc private func iCloudDidChange(_ notification: Notification) {
        let store = NSUbiquitousKeyValueStore.default
        let newScore = Int(store.longLong(forKey: highScoreKey))
        let localScore = UserDefaults.standard.integer(forKey: highScoreKey)

        if newScore > localScore {
            UserDefaults.standard.set(newScore, forKey: highScoreKey)
            // UI'i guncelle — NotificationCenter ile bildir
            NotificationCenter.default.post(
                name: Notification.Name("highScoreUpdated"),
                object: nil,
                userInfo: ["score": newScore]
            )
        }
    }
}
