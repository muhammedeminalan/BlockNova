// 📁 Utils/SettingsManager.swift
// Kullanici tercihlerini UserDefaults'ta saklar
// Singleton pattern — her yerden erisilebilir

import Foundation

final class SettingsManager {
    static let shared = SettingsManager()
    private init() {}

    // Ses acik/kapali — varsayilan: acik
    var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isSoundEnabled") }
    }

    // Titresim acik/kapali — varsayilan: acik
    var isHapticEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isHapticEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isHapticEnabled") }
    }
}
