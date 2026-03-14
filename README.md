<div align="center">

# 🟦 Nova Block

**SpriteKit ile geliştirilmiş modern blok yerleştirme oyunu**

*Sürükle. Yerleştir. Patlat.*

<br/>

[![iOS](https://img.shields.io/badge/iOS-15.5%2B-0A84FF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SpriteKit](https://img.shields.io/badge/SpriteKit-Framework-9B59B6?style=for-the-badge&logo=apple&logoColor=white)]()
[![App Store](https://img.shields.io/badge/App%20Store-İndir-000000?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com)

</div>

---

## 📸 Ekran Görüntüleri

<div align="center">
  <img src="screenshot/01_launch.png" width="170" alt="Yükleniyor"/>
  &nbsp;&nbsp;
  <img src="screenshot/02_home.png" width="170" alt="Ana Ekran"/>
  &nbsp;&nbsp;
  <img src="screenshot/03_game_start.png" width="170" alt="Oyun Başlangıcı"/>
  &nbsp;&nbsp;
  <img src="screenshot/04_game_play.png" width="170" alt="Oynanış"/>
  &nbsp;&nbsp;
  <img src="screenshot/05_game_over.png" width="170" alt="Oyun Sonu"/>
</div>

---

## ✨ Özellikler

### Temel Oynanış
- **8×8 ızgara** — Klasik blok bulmaca alanı
- **12 benzersiz şekil** — Tekli hücre, 2/3'lü çizgiler, 2×2/3×3 kareler, L / J / T / S / Z tetromino'lar
- **Akıllı sürükleme** — Parça parmağın üzerinden kalkar, ızgara hücresine snap'ler
- **Combo sistemi** — Aynı hamlede birden fazla çizgi patlatarak bonus puan kazan
- **Oyun sonu tespiti** — Hiçbir parça sığmadığında otomatik bitiş

### Puan Tablosu

| Aksiyon | Puan |
|---|---|
| Her yerleştirilen hücre | +1 |
| 1 çizgi temizleme | +10 |
| 2 çizgi temizleme | +35 *(10×2 + 25 bonus)* |
| 3+ çizgi temizleme | +n×10 + 50 *(combo bonusu)* |

### Görsel Geri Bildirim
- **Yeşil / Kırmızı önizleme** — Hover sırasında geçerli/geçersiz alanı anlık gösterir
- **Uçan metin efektleri** — `LINE!` · `DOUBLE!` · `COMBO x3!` animasyonları
- **"YENİ REKOR!"** — Oyun içinde rekor kırılınca badge patlar
- **Skor micro-animasyon** — Her güncelleme skor etiketini canlandırır

### Platform & UX
- **Game Center** liderlik tablosu entegrasyonu
- **Kaldığın yerden devam** — Uygulama kapansa bile oyun devam eder
- **Haptic feedback** — Yerleştirme, temizleme, oyun sonu için ayrı titreşimler
- **Ses efektleri** — Her aksiyon için özel ses
- **Loading ekranında arka plan auth** — Game Center girişi oyunu bloklamaz
- **Responsive tasarım** — Tüm iPhone boyutlarında pixel-perfect

---

## 🛠 Teknik Detaylar

| | |
|---|---|
| **Platform** | iOS 15.5+ · iPhone · Portrait |
| **Dil** | Swift 5 |
| **Framework** | SpriteKit · GameKit · UIKit |
| **Mimari** | MVC + Extension tabanlı |
| **Kalıcılık** | UserDefaults — sunucu yok, ağ bağlantısı yok |
| **Bağımlılık** | **Sıfır** — hiçbir third-party kütüphane |

---

## 📁 Proje Yapısı

```
BlockNova/
├── App/
│   ├── AppDelegate.swift           # Game Center auth başlatma
│   └── GameViewController.swift    # SpriteKit host, GKGameCenterControllerDelegate
│
├── Scenes/
│   ├── LoadingScene.swift          # Splash + arka plan auth bekleme
│   ├── HomeScene.swift             # Animasyonlu ana menü
│   ├── GameScene.swift             # Ana oyun döngüsü ve dokunma yönetimi
│   ├── GameScene+Layout.swift      # Safe area'ya duyarlı responsive yerleşim
│   └── GameScene+Overlay.swift     # Oyun sonu modal yapımı
│
├── Nodes/
│   ├── GridNode.swift              # 8×8 ızgara çizimi + oyun mantığı
│   ├── BlockNode.swift             # Tekil hücre node'u
│   └── PieceNode.swift             # BlockNode'lardan oluşan sürüklenebilir parça
│
├── Models/
│   ├── BlockShape.swift            # 12 şekil tanımı (tip, offset, renk)
│   ├── ShapeDispenser.swift        # 3 katmanlı dengeli dağıtım algoritması
│   └── GameManager.swift           # Skor, durum makinesi, Game Center entegrasyonu
│
├── ViewModels/
│   └── GameViewModel.swift         # Skor metinleri ve label formatlaması
│
└── Utils/
    ├── Constants.swift             # Tüm boyutlar screenW/screenH oransal
    ├── HapticManager.swift         # UIImpactFeedbackGenerator sarmalayıcısı
    ├── SoundManager.swift          # Ses efekti yönetimi
    └── GameSaveManager.swift       # UserDefaults ile save/restore
```

---

## 🏗 Mimari Kararlar

| Karar | Gerekçe |
|---|---|
| Fizik motoru kullanılmadı | Grid tabanlı mantık deterministik ve öngörülebilir |
| Node'lar silinmiyor, renk değiştiriliyor | Kasa (frame freeze) sorunlarını tamamen ortadan kaldırır |
| `touchesMoved`'da SKAction yok | Direkt `position` ataması ile gecikme sıfır, sürükleme akıcı |
| Tüm boyutlar `screenW/screenH` oransal | Hardcode piksel yok — her iPhone'da kusursuz |
| `GameManagerDelegate` pattern | Skor/durum değişiklikleri Scene'e gevşek bağlı — test edilebilir |

---

## 🚀 Kurulum

Xcode 15+ gereklidir. Bağımlılık yöneticisi gerekmez:

```bash
git clone https://github.com/muhammedeminalan/BlockNova.git
cd BlockNova
open BlockNova.xcodeproj
```

Simulator veya fiziksel cihazda direkt çalıştırılabilir. Game Center özellikleri fiziksel cihaz gerektirir.

---

## 👤 Geliştirici

<div align="center">

**Muhammed Emin Alan**

[![GitHub](https://img.shields.io/badge/GitHub-muhammedeminalan-181717?style=flat-square&logo=github)](https://github.com/muhammedeminalan)
[![pub.dev](https://img.shields.io/badge/pub.dev-wonzy__core__utils-02569B?style=flat-square&logo=dart&logoColor=white)](https://pub.dev/packages/wonzy_core_utils)

</div>

---

## 📄 Lisans

Bu proje **MIT Lisansı** altında dağıtılmaktadır.

---

<div align="center">
  <sub>Built with ❤️ using Swift & SpriteKit</sub>
</div>
