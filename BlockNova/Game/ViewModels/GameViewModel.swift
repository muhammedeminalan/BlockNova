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
    var scoreText: String { "\(manager.score)" }

    /// Ekranda gösterilecek rekor metni
    var highScoreText: String { "\(manager.highScore)" }

    /// "EN YÜKSEK: 1234" formatında tek satır rekor — overlay'de tek satır bilgi için
    var highScoreLineText: String { "EN YÜKSEK: \(manager.highScore)" }

    /// Oyun oynuyor mu?
    var isPlaying: Bool { manager.state == .playing }

    /// Oyun bitti mi?
    var isGameOver: Bool { manager.state == .gameOver }

    // MARK: - Skor Kartı (Overlay)

    /// Oyun sonu kartında gösterilecek skor + rekor değerleri
    var gameOverSummary: (score: String, highScore: String) {
        (score: "\(manager.score)", highScore: highScoreLineText)
    }

    /// Bu oyun oturumunda yeni rekor kırıldı mı?
    /// Overlay'de "YENİ REKOR" badge'ini göstermek için kullanılır.
    var didReachNewRecordThisRun: Bool { manager.newRecordAchieved }

    // MARK: - Geriye Donuk API

    /// Neden var: Eski adlar korunarak kademeli naming geçişini güvenli yapmak için.
    var skorMetni: String { scoreText }
    /// Neden var: Eski adlar korunarak kademeli naming geçişini güvenli yapmak için.
    var rekorMetni: String { highScoreText }
    /// Neden var: Eski adlar korunarak kademeli naming geçişini güvenli yapmak için.
    var rekorSatiri: String { highScoreLineText }
    /// Neden var: Eski adlar korunarak kademeli naming geçişini güvenli yapmak için.
    var oynuyor: Bool { isPlaying }
    /// Neden var: Eski adlar korunarak kademeli naming geçişini güvenli yapmak için.
    var oyunBitti: Bool { isGameOver }
    /// Neden var: Eski adlar korunarak kademeli naming geçişini güvenli yapmak için.
    var oyunSonuBilgisi: (skor: String, rekor: String) {
        let summary = gameOverSummary
        return (skor: summary.score, rekor: summary.highScore)
    }
    /// Neden var: Eski adlar korunarak kademeli naming geçişini güvenli yapmak için.
    var oyunSonuYeniRekorMu: Bool { didReachNewRecordThisRun }
}
