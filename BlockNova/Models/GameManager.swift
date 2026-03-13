// 📁 Models/GameManager.swift
// Oyun durumunu ve skorunu yöneten model katmanı.
// UI mantığı içermez — sadece veri ve durum.
// Delegate pattern ile GameScene'e bildirim gönderir.

import Foundation
import UIKit    // UIViewController parametresi için gerekli
import GameKit  // Game Center servisleri için gerekli

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

    /// Bu oyun oturumunda en az bir kez rekor kırıldı mı?
    /// Overlay'de "YENİ REKOR" badge'ini göstermek için kullanılır.
    private(set) var newRecordAchieved: Bool = false

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
        newRecordAchieved = false
        // highScore korunur — oyun bitmeden silmek yanlış olur
    }

    // MARK: - Game Center Entegrasyonu

    /// Game Center'a kullanıcı girişini başlatır.
    /// viewController: Apple'ın kendi giriş ekranını üzerinde gösterecek controller
    /// viewDidLoad'da çağrılır — uygulama açıldığında kimlik doğrulama tamamlanır
    static func authenticateGameCenter(from viewController: UIViewController) {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { vc, error in
            if let vc = vc {
                // Apple'ın standart Game Center giriş ekranını göster
                viewController.present(vc, animated: true)
            } else if player.isAuthenticated {
                // Giriş başarılı — kullanıcı adını logla
                print("Game Center giriş başarılı: \(player.displayName)")
            }
            // Giriş reddedilirse ya da hata oluşursa sessizce devam et — crash olmaz
        }
    }

    /// Mevcut skoru Game Center liderlik tablosuna gönderir.
    /// Her oyun bitişinde çağrılır — sadece rekorda değil
    static func submitScore(_ score: Int) {
        // Kullanıcı giriş yapmamışsa gönderme — hata ve crash önler
        guard GKLocalPlayer.local.isAuthenticated else { return }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: ["com.novablock.highscore"]
        ) { error in
            if let error = error {
                // Hata sessizce loglanır — kullanıcı deneyimini bozmaz
                print("Skor gönderilemedi: \(error.localizedDescription)")
            }
        }
    }

    /// Game Center liderlik tablosu ekranını açar.
    /// viewController: GKGameCenterViewController üzerinde gösterilecek controller
    static func showLeaderboard(from viewController: UIViewController) {
        // Kullanıcı giriş yapmamışsa gösterme — boş ekran açılmaz
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let vc = GKGameCenterViewController(
            leaderboardID: "com.novablock.highscore",
            playerScope: .global,   // Tüm oyuncular — sadece arkadaşlar değil
            timeScope: .allTime     // Tüm zamanlar — haftalık değil
        )
        // Delegate olarak geçirilen controller, ekran kapatmayı yönetir
        vc.gameCenterDelegate = viewController as? GKGameCenterControllerDelegate
        viewController.present(vc, animated: true)
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
            // Bu oturumda rekor kırıldığını işaretle — oyun bitince overlay'de gösterilir
            newRecordAchieved = true
        }
        delegate?.didUpdateScore(score, highScore: highScore, isNewRecord: isNewRecord)
    }
}
