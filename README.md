<div align="center">
  <img src="BlockNova/Resources/Assets.xcassets/AppIcon.appiconset/app_icon_fixed.png" width="120" alt="BlockNova Icon"/>
  <h1>BlockNova</h1>
  <p><b>SwiftUI + SpriteKit hibrit mimari ile geliştirilen native iOS blok bulmaca oyunu</b></p>
  <p>Sürükle. Yerleştir. Satır ve sütunları temizle. Zinciri büyüt.</p>

[![iOS](https://img.shields.io/badge/iOS-15.6%2B-0A84FF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-UI-0EA5E9?style=for-the-badge)](https://developer.apple.com/xcode/swiftui/)
[![SpriteKit](https://img.shields.io/badge/SpriteKit-Gameplay-7C3AED?style=for-the-badge)](https://developer.apple.com/spritekit/)
[![CI](https://img.shields.io/github/actions/workflow/status/muhammedeminalan/BlockNova/ios-ci.yml?branch=main&style=for-the-badge&label=iOS%20CI)](https://github.com/muhammedeminalan/BlockNova/actions/workflows/ios-ci.yml)
[![Lisans](https://img.shields.io/badge/Lisans-MIT-22C55E?style=for-the-badge)](LICENSE)
[![App Store](https://img.shields.io/badge/App%20Store-İndir-000000?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/us/app/nova-block/id6760556862)
</div>

---

## İçindekiler

- [Proje Özeti](#proje-özeti)
- [Mimari Snapshot](#mimari-snapshot)
- [Ekran Görüntüleri](#ekran-görüntüleri)
- [Öne Çıkan Özellikler](#öne-çıkan-özellikler)
- [Proje Yapısı](#proje-yapısı)
- [Kurulum (Hızlı)](#kurulum-hızlı)
- [Kurulum (Detaylı)](#kurulum-detaylı)
- [Kalite Kapıları](#kalite-kapıları)
- [Dokümantasyon](#dokümantasyon)
- [Katkı](#katkı)
- [Lisans](#lisans)

---

## Proje Özeti

BlockNova, 8x8 grid üzerinde oynanan, sürükle-bırak odaklı bir blok bulmaca oyunudur.

Proje, son migrasyonlarla birlikte hibrit bir yapıya geçti:
- Oyun çekirdeği ve drag mekaniği **SpriteKit** tarafında.
- Home / Loading / Settings / HUD / Overlay katmanları **SwiftUI** tarafında.
- Yönlendirme ve ekran geçişleri `AppRouter` üzerinden yönetiliyor.
- Oyun sahnesi `GameContainerView` ile SwiftUI içine host ediliyor.

---

## Mimari Snapshot

```mermaid
flowchart TD
    A["BlockNovaApp"] --> B["RootView"]
    B --> C["AppRouter"]
    C --> D["LoadingView"]
    C --> E["HomeView"]
    C --> F["GameContainerView"]
    F --> G["GameContainerViewController (UIKit Bridge)"]
    G --> H["GameScene (SpriteKit Core)"]
    H --> I["GridNode / PieceNode / PreviewSlotNode"]
    H --> J["GameManager + ShapeDispenser"]
    H --> K["GameSaveManager + CloudManager"]
    H --> L["SwiftUI Overlay: HUD / Combo / GameOver"]
```

Detaylı mimari dokümanı: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Ekran Görüntüleri

<div align="center">

| Ana Ekran | Oyun Başlangıcı | Oynanış | Oyun Sonu |
|:---------:|:---------------:|:-------:|:---------:|
| <img src="screenshot/02_home.png" width="170"/> | <img src="screenshot/03_game_start.png" width="170"/> | <img src="screenshot/04_game_play.png" width="170"/> | <img src="screenshot/05_game_over.png" width="170"/> |

</div>

---

## Öne Çıkan Özellikler

- 8x8 oyun tahtası ve akıcı sürükle-bırak deneyimi
- 29 farklı blok şekli (micro/line/rectangle/corner/zigzag)
- Milestone bazlı combo efekt akışı (`5`, `10`, `15` zinciri)
- Kırılan hücre üstünde puan popup animasyonları
- Canlı skor animasyonlu oyun içi HUD
- iCloud + local fallback high score senkronu
- Game Center liderlik tablosu entegrasyonu
- Oyun state kalıcılığı (arka plan/kapanış sonrası devam)
- Ses + titreşim ayarları

---

## Proje Yapısı

```text
BlockNova/
├── App/
│   ├── BlockNovaApp.swift
│   ├── RootView.swift
│   ├── AppRouter.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Constants.swift
│   ├── CloudManager.swift
│   ├── GameSaveManager.swift
│   ├── HapticManager.swift
│   ├── SoundManager.swift
│   └── NotificationNames.swift
├── Game/
│   ├── Models/
│   ├── Logic/
│   └── ViewModels/
├── UI/
│   ├── Loading/
│   ├── Home/
│   ├── Settings/
│   ├── Game/
│   │   └── Components/
│   ├── Scenes/
│   ├── Nodes/
│   └── Common/
├── Utils/
│   └── SettingsManager.swift
├── Resources/
│   ├── Assets.xcassets/
│   ├── Base.lproj/LaunchScreen.storyboard
│   └── Sounds/
└── SupportingFiles/
    └── BlockNova.entitlements
```

---

## Kurulum (Hızlı)

```bash
git clone https://github.com/muhammedeminalan/BlockNova.git
cd BlockNova
open BlockNova.xcodeproj
```

---

## Kurulum (Detaylı)

1. Gereksinimler
- Güncel stabil Xcode sürümü
- iOS 15.6+ hedefleyen bir cihaz/simulator
- App Store/Game Center testleri için Apple ID (fiziksel cihaz önerilir)

2. Projeyi aç
- `BlockNova.xcodeproj` dosyasını Xcode ile aç.
- Target: `BlockNova`
- Scheme: `BlockNova`

3. Signing & Capabilities
- `Signing & Capabilities` altında kendi Team’ini seç.
- Bundle Identifier çakışmıyorsa mevcut kimlikle devam et.
- Gerekli capability’ler:
  - Game Center
  - iCloud (Key-Value Storage)

4. Çalıştırma profilleri
- Gameplay doğrulaması: fiziksel cihaz
- Görsel/screenshot: simulator
- Not: simulator’da Game Center/iCloud log gürültüsü görülebilir; bu tek başına crash anlamına gelmez.

5. Archive öncesi checklist
- `Version` ve `Build` numaralarını artır
- Release archive al
- Kısa smoke test yap:
  - Home -> Game -> Settings -> Home
  - Hızlı sürükle-bırak + combo
  - Game over -> replay/home

---

## Kalite Kapıları

CI pipeline şu adımları otomatik koşar:
- Debug build
- Release build
- Static analyze

Workflow: [ios-ci.yml](.github/workflows/ios-ci.yml)

Not: Projede henüz test target tanımlı değil; bu yüzden ana kalite kapısı build + analyze + manuel smoke test.

---

## Dokümantasyon

- Mimari ve sorumluluk haritası: [ARCHITECTURE.md](ARCHITECTURE.md)
- Katkı kuralları: [CONTRIBUTING.md](CONTRIBUTING.md)
- Davranış kuralları: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Test checklist: [TEST_CHECKLIST.md](TEST_CHECKLIST.md)

---

## Katkı

Katkı sürecini başlatmadan önce:
1. [CONTRIBUTING.md](CONTRIBUTING.md) dosyasını oku.
2. Uygunsa issue aç veya mevcut issue’yu üstlen.
3. Küçük, odaklı PR gönder.

---

## Lisans

Bu proje [MIT Lisansı](LICENSE) ile yayınlanmaktadır.
