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

    /// Paylasilan instance — senkronizasyon icin kullanilir
    static let shared = GameManager()

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
    private init() {
        // Kayıtlı rekor varsa yükle — uygulama yeniden açılınca kaybolmasın
        highScore = CloudManager.shared.loadHighScore()
    }

    // MARK: - Skor Ekleme

    /// Dışarıdan direkt puan eklemek için genel metod.
    /// Skor mantığını tek noktada toplar — tutarlılık sağlar.
    func addScore(_ points: Int) {
        addPoints(points)
    }

    /// Hücre yerleştirme skoru: parça büyüklüğüne göre artan puan
    /// Küçük parça az, büyük parça çok puan verir — tatmin hissi artar
    func addScore(forCells count: Int) {
        addPoints(pointsForPlacement(cellCount: count))
    }

    /// Çizgi temizleme skoru — combo arttıkça katlanır
    func addScore(forLines count: Int) {
        addPoints(pointsForLines(count))
    }

    /// Çizgi puanını UI'da göstermek için dışarıdan okunabilir
    func previewPointsForLines(_ count: Int) -> Int {
        return pointsForLines(count)
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

    /// Kaydedilmiş oyundan geri yüklenince çağrılır.
    /// private score/highScore değerlerini dışarıdan set etmenin tek yolu.
    func restoreScore(_ savedScore: Int, highScore savedHighScore: Int) {
        score = savedScore
        // highScore küçülmez — iCloud + local degerlerden buyuk olan korunur
        if savedHighScore > highScore {
            highScore = savedHighScore
            CloudManager.shared.saveHighScore(highScore)
        }
        // Delegate'e bildir: skor etiketleri hemen güncellenir
        delegate?.didUpdateScore(score, highScore: highScore, isNewRecord: false)
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
                DispatchQueue.main.async {
                    viewController.present(vc, animated: true)
                }
            } else if player.isAuthenticated {
                // Giriş başarılı — kullanıcı adını logla
                print("Game Center giriş başarılı: \(player.displayName)")
            }
            // Giriş reddedilirse ya da hata oluşursa sessizce devam et — crash olmaz
            if let error = error {
                print("Game Center auth hatası: \(error.localizedDescription)")
            }
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
            leaderboardIDs: [C.leaderboardID]
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
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticateGameCenter(from: viewController)
            return
        }

        let vc = GKGameCenterViewController(
            leaderboardID: C.leaderboardID,
            playerScope: .global,   // Tüm oyuncular — sadece arkadaşlar değil
            timeScope: .allTime     // Tüm zamanlar — haftalık değil
        )
        // Delegate olarak geçirilen controller, ekran kapatmayı yönetir
        vc.gameCenterDelegate = viewController as? GKGameCenterControllerDelegate
        DispatchQueue.main.async {
            viewController.present(vc, animated: true)
        }
    }

    // MARK: - Özel Yardımcı

    /// Yerleştirme puanını parça boyutuna göre hesaplar
    private func pointsForPlacement(cellCount: Int) -> Int {
        switch cellCount {
        case 1...2:  return cellCount * 5
        case 3...4:  return cellCount * 8
        case 5...9:  return cellCount * 12
        default:     return cellCount * 15
        }
    }

    /// Çizgi temizleme puanını combo seviyesine göre hesaplar
    private func pointsForLines(_ count: Int) -> Int {
        switch count {
        case 1: return 100
        case 2: return 300
        case 3: return 600
        default: return 1000 + (count - 4) * 200
        }
    }

    /// Skoru artırır, rekor kontrolü yapar, delegate'i bilgilendirir.
    /// Merkezi tutuluyor çünkü rekor kontrolü her iki çağrıda da aynı.
    private func addPoints(_ points: Int) {
        score += points
        var isNewRecord = false
        if score > highScore {
            highScore = score
            // Kalıcı kayıt: uygulama kapansa da korunur
            CloudManager.shared.saveHighScore(highScore)
            // isNewRecord sadece bu oturumda rekor ilk kez kırılınca true — sonraki artışlarda false
            if !newRecordAchieved {
                isNewRecord = true
                newRecordAchieved = true
            }
        }
        delegate?.didUpdateScore(score, highScore: highScore, isNewRecord: isNewRecord)
    }

    // MARK: - Disaridan Rekor Guncelleme

    /// Disaridan gelen skor mevcut highScore'dan buyukse guncelle
    /// iCloud / Game Center senkronizasyonunda kullanilir
    func updateHighScoreIfNeeded(_ score: Int) {
        guard score > highScore else { return }
        highScore = score
        CloudManager.shared.saveHighScore(score)
        // UI'i guncelle — NotificationCenter ile bildir
        NotificationCenter.default.post(
            name: .highScoreUpdated,
            object: nil,
            userInfo: ["score": score]
        )
    }
}
