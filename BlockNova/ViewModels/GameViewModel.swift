// 📁 ViewModels/GameViewModel.swift
// SpriteKit'e uygun sunum katmanı.
//
// SORUMLULUKLAR:
// - Skor ve rekor formatlama (UI'ye hazır String)
// - Oyun durumu sorguları (isPlaying, isGameOver)
// - Puan güncellemelerini sahneye köprüleyen tipik yer
//
// NOT: SpriteKit'te ViewModel doğrudan SKNode bağlamaz.
// Sahne (GameScene) bu sınıfı sorgular, delegate callback'leri
// geldikçe sahnenin kendi node'larını günceller.

import Foundation

// MARK: - GameViewModel

final class GameViewModel {

    // MARK: - Bağımlılık

    /// Ham veri kaynağı — skor, state, highScore buradan okunur
    private let manager: GameManager

    // MARK: - Başlangıç

    init(manager: GameManager) {
        self.manager = manager
    }

    // MARK: - Sunum Değerleri

    /// Ekranda gösterilecek skor metni
    var skorMetni: String { "\(manager.score)" }

    /// Ekranda gösterilecek rekor metni
    var rekorMetni: String { "\(manager.highScore)" }

    /// "EN YÜKSEK: 1234" formatında tek satır rekor — overlay'de tek satır bilgi için
    var rekorSatiri: String { "EN YÜKSEK: \(manager.highScore)" }

    /// Oyun oynuyor mu?
    var oynuyor: Bool { manager.state == .playing }

    /// Oyun bitti mi?
    var oyunBitti: Bool { manager.state == .gameOver }

    // MARK: - Skor Kartı (Overlay)

    /// Oyun sonu kartında gösterilecek skor + rekor değerleri
    var oyunSonuBilgisi: (skor: String, rekor: String) {
        (skor: "\(manager.score)", rekor: rekorSatiri)
    }

    /// Bu oyun oturumunda yeni rekor kırıldı mı?
    /// Overlay'de "YENİ REKOR" badge'ini göstermek için kullanılır.
    var oyunSonuYeniRekorMu: Bool { manager.newRecordAchieved }
}
