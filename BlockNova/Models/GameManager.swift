// 📁 Models/GameManager.swift
// Oyun durumunu ve skorunu yöneten model katmanı.
// UI mantığı içermez — sadece veri ve durum.
// Delegate pattern ile GameScene'e bildirim gönderir.

import Foundation

// MARK: - Oyun Durumu
enum GameState {
    /// Oyun aktif — kullanıcı parça sürükleyebilir
    case playing
    /// Oyun bitti — hiçbir parça sığmıyor
    case gameOver
}

// MARK: - Delegate
/// GameManager olaylarını GameScene'e iletmek için.
/// Weak referans ile tutulur — retain cycle önleme.
protocol GameManagerDelegate: AnyObject {
    /// Skor güncellendiğinde — UI güncelleme için
    func didUpdateScore(_ score: Int, highScore: Int, isNewRecord: Bool)
    /// Oyun durumu değiştiğinde — overlay, haptic tetikleme için
    func didChangeState(_ state: GameState)
}

// MARK: - GameManager
final class GameManager {

    // MARK: - Özellikler

    /// Oyunun şu anki durumu — başlangıçta .playing
    private(set) var state: GameState = .playing

    /// Mevcut tur skoru — yerleştirme + çizgi temizleme ile artar
    private(set) var score: Int = 0

    /// Tüm zamanların en yüksek skoru — UserDefaults'ta kalıcı
    private(set) var highScore: Int

    /// Olayları GameScene'e iletmek için — weak: retain cycle önler
    weak var delegate: GameManagerDelegate?

    // MARK: - Init
    init() {
        // Kayıtlı rekor varsa yükle — uygulama yeniden açılınca kaybolmasın
        highScore = UserDefaults.standard.integer(forKey: C.highScoreKey)
    }

    // MARK: - Skor Ekleme

    /// Dışarıdan direkt puan eklemek için genel metod.
    /// Skor mantığını tek noktada toplar — tutarlılık sağlar.
    func addScore(_ points: Int) {
        addPoints(points)
    }

    /// Hücre yerleştirme skoru: her hücre 1 puan
    /// Yeterince basit, spam yerleştirmeyi ödüllendirmez
    func addScore(forCells count: Int) {
        addPoints(count)
    }

    /// Çizgi temizleme skoru — combo bonusu ile artar:
    /// 1 çizgi: 10, 2 çizgi: 10+25=35, 3+ çizgi: n*10+50
    func addScore(forLines count: Int) {
        let base  = count * 10
        let bonus: Int
        switch count {
        case 1:  bonus = 0
        case 2:  bonus = 25
        default: bonus = 50   // 3 veya daha fazla — combo ödülü
        }
        addPoints(base + bonus)
    }

    /// Oyunu bitirir — delegate'i bilgilendirir
    func triggerGameOver() {
        guard state == .playing else { return }
        state = .gameOver
        delegate?.didChangeState(.gameOver)
    }

    /// Yeni oyun için durumu sıfırlar — skor sıfırlanır, rekor korunur
    func reset() {
        score = 0
        state = .playing
        // highScore korunur — oyun bitmeden silmek yanlış olur
    }

    // MARK: - Özel Yardımcı

    /// Skoru artırır, rekor kontrolü yapar, delegate'i bilgilendirir.
    /// Merkezi tutuluyor çünkü rekor kontrolü her iki çağrıda da aynı.
    private func addPoints(_ points: Int) {
        score += points
        var isNewRecord = false
        if score > highScore {
            highScore = score
            // Kalıcı kayıt: uygulama kapansa da korunur
            UserDefaults.standard.set(highScore, forKey: C.highScoreKey)
            isNewRecord = true
        }
        delegate?.didUpdateScore(score, highScore: highScore, isNewRecord: isNewRecord)
    }
}
