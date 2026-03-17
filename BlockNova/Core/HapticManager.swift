// 📁 Utils/HapticManager.swift
// Dokunsal geri bildirim (haptic feedback) yoneticisi.
// SpriteKit main thread disindan cagirabilir, bu yuzden DispatchQueue.main.async kullanilir.
// UIKit feedback generator'lari main thread'de calismak zorunda — hata onleme.
//
// Generator'lar singleton içinde önceden oluşturulur ve hazırlanır.
// Her çağrıda yeni instance oluşturmak micro-allocation yaratır —
// Apple da generator'ları cache'leyip prepare() ile hazırlamayı önerir.

import UIKit

// MARK: - HapticManager
final class HapticManager {

    /// Singleton — generator'lar bir kez oluşturulur, uygulama boyunca yeniden kullanılır
    static let shared = HapticManager()

    // Önceden oluşturulmuş generator'lar — her çağrıda yeniden oluşturulmaz
    // Bu sayede micro-allocation önlenir ve ilk çalmada gecikme olmaz
    private let lightGen  = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGen  = UIImpactFeedbackGenerator(style: .heavy)
    private let notifGen  = UINotificationFeedbackGenerator()

    private init() {
        // Uygulama başlangıcında hazırla — ilk tetiklemede gecikme olmasın
        lightGen.prepare()
        mediumGen.prepare()
        heavyGen.prepare()
        notifGen.prepare()
    }

    /// Fiziksel dokunma hissi — yerlestirme, etkilesim icin
    /// style: .light (hafif), .medium (orta), .heavy (guclu)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // SettingsManager'dan kontrol et — kullanıcı titreşimi kapattıysa çalıştırma
        guard SettingsManager.shared.isHapticEnabled else { return }
        // Main thread garantisi: UIKit generator'lari sadece main thread'de calisir
        DispatchQueue.main.async {
            // Cache'lenmiş generator'dan çal — yeni instance oluşturulmaz
            switch style {
            case .light:
                shared.lightGen.impactOccurred()
            case .medium:
                shared.mediumGen.impactOccurred()
            case .heavy:
                shared.heavyGen.impactOccurred()
            case .soft:
                // Map to the closest available generator; soft ~ light
                shared.lightGen.impactOccurred()
            case .rigid:
                // Map to the closest available generator; rigid ~ heavy
                shared.heavyGen.impactOccurred()
            @unknown default:
                // Safe fallback to a neutral medium impact for any future cases
                shared.mediumGen.impactOccurred()
            }
        }
    }

    /// Bildirim tipi haptic — basari, uyari, hata durumlari icin
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        // SettingsManager'dan kontrol et — kullanıcı titreşimi kapattıysa çalıştırma
        guard SettingsManager.shared.isHapticEnabled else { return }
        // Main thread disinda kullanmak dokunus motorunu bozabilir
        DispatchQueue.main.async {
            // Cache'lenmiş generator'dan çal — yeni instance oluşturulmaz
            shared.notifGen.notificationOccurred(type)
        }
    }
}
