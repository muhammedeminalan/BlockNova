// 📁 App/AppDelegate.swift
// Uygulama yaşam döngüsü olaylarını yakalar.

import AVFoundation
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession ayarlanamadi: \(error)")
        }

        let _ = CloudManager.shared
        return true
    }
}
