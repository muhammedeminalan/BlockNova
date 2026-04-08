# BlockNova Architecture

Bu doküman, projenin mevcut hibrit mimarisini (SwiftUI + SpriteKit) ve güvenli değişiklik sınırlarını tanımlar.

## 1) Mimari Hedefler

- Oyun mekaniğini stabil tutmak
- UI tarafını hızlı geliştirilebilir kılmak
- State/persistence akışını deterministik tutmak
- Katman sorumluluklarını net ayırmak

## 2) Teknoloji Stack

- UI: SwiftUI
- Gameplay Rendering: SpriteKit
- App Lifecycle: UIKit (`AppDelegate`)
- Navigation: Router tabanlı (`AppRouter`)
- Persistence: UserDefaults + iCloud Key-Value Store
- Social: Game Center

## 3) Katmanlar ve Sorumluluklar

| Katman | Dosyalar | Sorumluluk |
|---|---|---|
| App Composition | `App/BlockNovaApp.swift`, `App/RootView.swift` | Uygulama giriş noktası, ekran ağacı, modal sunum |
| Routing | `App/AppRouter.swift` | `loading/home/game` ekran geçişleri, settings sunumu |
| SwiftUI Screens | `UI/Loading`, `UI/Home`, `UI/Settings`, `UI/Game` | Ekran UI katmanı ve component kompozisyonu |
| Bridge | `UI/Game/GameContainerView.swift` | SpriteKit scene’i SwiftUI içine host etme ve event köprüsü |
| Gameplay Core | `UI/Scenes/GameScene*.swift`, `UI/Nodes/*.swift` | Drag-drop, yerleştirme, line clear, combo zinciri, game over |
| Domain Logic | `Game/Models`, `Game/Logic` | Skor/state yönetimi, shape üretimi, model tanımları |
| Core Services | `Core/*`, `Utils/SettingsManager.swift` | Kalıcılık, cloud sync, ses, titreşim, sabitler |

## 4) Runtime Akış

1. `BlockNovaApp` -> `RootView`
2. `AppRouter` başlangıç ekranı: `loading`
3. `LoadingViewModel`:
   - Game Center auth
   - High score sync
   - Ses preload
4. Router -> `home`
5. Kullanıcı `Play` -> Router -> `game`
6. `GameContainerViewController` bir `GameScene` üretir
7. `GameScene` event’leri closure ile SwiftUI katmanına iletir:
   - score/highscore değişimi
   - combo overlay tetikleme
   - game over sunumu
8. Settings her iki context’te de aynı `SettingsView` ile açılır; game context’inde ek “ana menüye dön” aksiyonu gösterilebilir.

## 5) State ve Persistence Stratejisi

- `GameManager.shared`:
  - oyun state (`playing`, `gameOver`)
  - score/highScore
  - delegate üzerinden scene/UI bildirimi
- `GameSaveManager`:
  - grid renkleri
  - anlık skor/rekor
  - tray shape tipleri
- `CloudManager`:
  - iCloud KVS ile rekor senkronu
  - local fallback (`UserDefaults`)

Kural: Cloud/Game Center başarısız olsa bile gameplay bloklanmaz.

## 6) Neyi Nerede Değiştirmeliyim?

| İhtiyaç | Değiştirilecek Yer | Not |
|---|---|---|
| Oyun içi üst HUD tasarımı | `UI/Game/InGameHUDView.swift` | Güvenli, gameplay’e dokunmaz |
| Combo overlay stilleri | `UI/Game/Components/ComboEffectOverlayView.swift` | Güvenli, event köprüsü üzerinden gelir |
| Game over görünümü | `UI/Game/GameOverOverlayView.swift` + `UI/Game/Components/*` | Güvenli |
| Home/Loading/Settings UI | `UI/Home/*`, `UI/Loading/*`, `UI/Settings/*` | Güvenli |
| Skor formülü | `Game/Models/GameManager.swift` | Oynanış dengesini etkiler, dikkatli |
| Parça üretim dengesi | `Game/Logic/ShapeDispenser.swift` | Zorluk eğrisini etkiler |
| Drag davranışı | `UI/Scenes/GameScene.swift`, `UI/Nodes/PieceNode.swift` | Kritik gameplay alanı |
| Grid temizleme/patlama | `UI/Nodes/GridNode+LineClearEffects.swift` | Performans ve state riski yüksek |
| Save/restore akışı | `UI/Scenes/GameScene+Persistence.swift`, `Core/GameSaveManager.swift` | State bütünlüğü kritik |
| Cloud/Game Center | `Core/CloudManager.swift`, `Game/Models/GameManager.swift` | Offline fallback korunmalı |

## 7) Kritik Sınırlar (Bozmadan Refactor)

- `GameScene` drag akışındaki sıraları değiştirme:
  - `beginDrag` -> offset hesap -> anlık pozisyon
- `GridNode` line clear callback sırasını bozma:
  - effect -> clear -> delegate
- `trayPieces` ve sahnedeki `PieceNode` senkronunu koru
- `removeObserver` temizliğini kaldırma
- `safeArea` güncelleme zincirini bozma:
  - `viewDidLayoutSubviews` / `viewSafeAreaInsetsDidChange` -> `updateSafeAreaInsets`

## 8) Güvenli Refactor Roadmap

1. **Dokümantasyon + Şablonlar** (davranış değişimi yok)
2. **Dosya isim/klasör düzeni** (Xcode içinden taşı)
3. **UI component extraction** (yalnızca SwiftUI katmanı)
4. **Gameplay içindeki mikro iyileştirme** (her adımda build + smoke test)

## 9) Kalite Kapısı

Minimum merge kriteri:
- Debug build başarılı
- Release build başarılı
- Static analyze başarılı
- Manuel smoke test notu PR’da kayıtlı

