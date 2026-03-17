// 📁 App/AppDelegate.swift
// Uygulamanin yasam dongusu olaylarini yakalar.
// Bu proje SpriteKit kullandigi icin burada minimum kod tutulur.

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// iOS 12 ve onceki surumler icin pencere referansi
    /// Storyboard tabanli uygulamada mevcut pencereyi takip etmek icin gerekli
    var window: UIWindow?

    // MARK: - Uygulama Baslangici

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Ses kategorisini ambient olarak ayarla
        // .ambient → diğer uygulamaların sesini kesmez
        // Spotify çalarken oyun sesleri üstüne eklenir, çakışma olmaz
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]  // Diğer seslerle karışmasına izin ver
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Hata olursa sessizce devam et — crash verme
            print("AVAudioSession ayarlanamadı: \(error)")
        }

        // Baslangicta ekstra is yapmiyoruz — performans icin temiz baslangic
        return true
    }

    // MARK: - Uygulama Durum Gecisleri

    func applicationWillResignActive(_ application: UIApplication) {
        // Uygulama aktiften pasife geciyor — oyun burada gerekirse duraklatilabilir
        // SpriteKit sahneleri kendi kontrolunu yaptigi icin simdilik bos birakildi
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Arka plana geciste kaynaklari serbest birakmak icin kullanilir
        // Bu projede kritik durum saklama yok, bu yuzden bos
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Arka plandan cikarken gerekli ayarlari geri almak icin kullanilir
        // Oyun sahnesi kendi yenilemesini yaptigi icin bos
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Uygulama tekrar aktif oldu — gerekiyorsa oyun devam ettirilebilir
        // Kontrol GameScene tarafinda oldugu icin burada is yok
    }
}
