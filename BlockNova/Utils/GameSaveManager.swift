// 📁 Utils/GameSaveManager.swift
// Oyun durumunu UserDefaults'a kaydeden ve geri yükleyen yönetici.
// Firebase veya dosya sistemi kullanılmaz — UserDefaults basit ve güvenilir.
//
// KAYIT İÇERİĞİ:
// - Mevcut skor ve rekor skor
// - 8x8 grid renk verisi (UIColor hex string olarak)
// - Tepsideki 3 parçanın tipleri (BlockShapeType rawValue)
//
// YAŞAM DÖNGÜSÜ:
// - Uygulama arka plana geçince veya kapanınca kaydet
// - Sahne açılınca kayıtlı durum varsa yükle
// - Game Over olunca kaydı sil

import UIKit

// MARK: - Kaydedilecek Veri Yapısı

/// Codable: JSONEncoder/JSONDecoder ile UserDefaults'a yazılır/okunur
struct SavedGameState: Codable {
    /// Mevcut tur skoru
    var score: Int
    /// Tüm zamanların rekoru
    var highScore: Int
    /// 8x8 grid renk verisi: nil = boş hücre, hex string = dolu hücre rengi
    var gridColors: [[String?]]
    /// Tepsideki parçaların tipleri — BlockShapeType.rawValue olarak saklanır
    var currentPieceTypes: [String]
}

// MARK: - GameSaveManager

final class GameSaveManager {

    /// Singleton — tüm yerden aynı instance üzerinden erişilir
    static let shared = GameSaveManager()
    private init() {}

    /// UserDefaults anahtarı — diğer anahtarlarla çakışmasın
    private let kayitAnahtari = "BlockNova_SavedGameState"

    // MARK: - Kaydetme

    /// Oyun durumunu JSON'a dönüştürüp UserDefaults'a yazar.
    /// Hata olursa sessizce geçer — kayıt başarısızlığı oyunu çökertmemeli.
    func kaydet(_ durum: SavedGameState) {
        do {
            let veri = try JSONEncoder().encode(durum)
            UserDefaults.standard.set(veri, forKey: kayitAnahtari)
        } catch {
            // Encode hatası nadiren olur ama crash önlemek için yakalanır
            print("Oyun kaydedilemedi: \(error.localizedDescription)")
        }
    }

    // MARK: - Kayıt Var Mı?

    /// Kaydedilmiş aktif oyun durumu var mı?
    /// HomeScene veya GameScene'de devam seçeneği sunmak için kullanılır.
    func kayitVarMi() -> Bool {
        return UserDefaults.standard.data(forKey: kayitAnahtari) != nil
    }

    // MARK: - Yükleme

    /// UserDefaults'tan JSON'u okur ve decode eder.
    /// Veri yoksa veya hatalıysa nil döner — çağıran taraf kontrol eder.
    func yukle() -> SavedGameState? {
        guard let veri = UserDefaults.standard.data(forKey: kayitAnahtari) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(SavedGameState.self, from: veri)
        } catch {
            // Bozuk veri: sil ve nil dön — eski format uyumsuzluğu için güvenli temizlik
            print("Kayıt yüklenemedi (bozuk veri temizlendi): \(error.localizedDescription)")
            sil()
            return nil
        }
    }

    // MARK: - Silme

    /// Kaydı UserDefaults'tan tamamen kaldırır.
    /// Game Over, yeni oyun başlatma veya bozuk veri durumlarında çağrılır.
    func sil() {
        UserDefaults.standard.removeObject(forKey: kayitAnahtari)
    }
}

// MARK: - UIColor Hex Dönüşüm Uzantısı

extension UIColor {

    /// UIColor → "#RRGGBB" formatında hex string.
    /// Grid renk verisini JSON'a kaydetmek için kullanılır.
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        // getRed başarısız olursa siyah döndür — crash önleme
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return "#000000"
        }
        return String(format: "#%02X%02X%02X",
                      Int((r * 255).rounded()),
                      Int((g * 255).rounded()),
                      Int((b * 255).rounded()))
    }
}
