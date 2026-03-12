// 📁 Utils/HapticManager.swift
// Dokunsal geri bildirim (haptic feedback) yoneticisi.
// SpriteKit main thread disindan cagirabilir, bu yuzden DispatchQueue.main.async kullanilir.
// UIKit feedback generator'lari main thread'de calismak zorunda — hata onleme.

import UIKit

// MARK: - HapticManager
final class HapticManager {

    /// Fiziksel dokunma hissi — yerlestirme, etkilesim icin
    /// style: .light (hafif), .medium (orta), .heavy (guclu)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Main thread garantisi: UIKit generator'lari sadece main thread'de calisir
        DispatchQueue.main.async {
            let gen = UIImpactFeedbackGenerator(style: style)
            gen.impactOccurred()
        }
    }

    /// Bildirim tipi haptic — basari, uyari, hata durumlari icin
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        // Main thread disinda kullanmak dokunus motorunu bozabilir
        DispatchQueue.main.async {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(type)
        }
    }

    /// Secim degisikligi haptic — buton secimi, menu gecisi icin
    static func selectionChanged() {
        // Secim geri bildirimi kisa ve hafif oldugu icin ana thread yeterli
        DispatchQueue.main.async {
            let gen = UISelectionFeedbackGenerator()
            gen.selectionChanged()
        }
    }
}
