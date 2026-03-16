<div align="center">

<img src="BlockNova/Resources/Assets.xcassets/AppIcon.appiconset/app_icon_fixed.png" width="120" alt="Nova Block Icon"/>

# Nova Block

**Swift + SpriteKit ile geliştirilmiş native iOS blok bulmaca oyunu**

*Sürükle. Yerleştir. Patlat.*

<br/>

[![iOS](https://img.shields.io/badge/iOS-15.5%2B-0A84FF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SpriteKit](https://img.shields.io/badge/SpriteKit-Framework-9B59B6?style=for-the-badge&logo=apple&logoColor=white)]()
[![Lisans](https://img.shields.io/badge/Lisans-MIT-22C55E?style=for-the-badge)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-BlockNova-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/muhammedeminalan/BlockNova)
[![App Store](https://img.shields.io/badge/App%20Store-%C4%B0ndir-000000?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/us/app/nova-block/id6760556862)

</div>

---

## Ekran Görüntüleri

<div align="center">

| Ana Ekran | Oyun Başlangıcı | Oynanış | Oyun Sonu |
|:---------:|:---------------:|:-------:|:---------:|
| <img src="screenshot/02_home.png" width="170"/> | <img src="screenshot/03_game_start.png" width="170"/> | <img src="screenshot/04_game_play.png" width="170"/> | <img src="screenshot/05_game_over.png" width="170"/> |

</div>

---

## Oyun Hakkında

**Nova Block**, 8×8 bir ızgaraya renkli blok parçaları sürükleyip bıraktığın, dolu satır ve sütunları temizleyerek puan kazandığın bir bulmaca oyunudur. Zaman baskısı yoktur — her hamle düşünerek yapılabilir. Asıl zorluk, ızgaranın dolmasına izin vermeden ne kadar uzun hayatta kalabileceğindir.

> Basit kurallar, derin strateji. Bir kez başlayınca bırakmak zordur.

---

## Özellikler

### Temel Oynanış
- **8×8 ızgara** — 64 hücreli klasik blok bulmaca alanı
- **23 şekil tipi** — tekli hücre, yatay/dikey çizgiler (2–5 hücre), dikdörtgenler, L/J/T/S/Z varyantları, köşe şekilleri ve daha fazlası
- **Sürükle-bırak** — parça parmağın üstüne kalkar, en yakın geçerli ızgara hücresine otomatik snap'lenir
- **Combo sistemi** — tek hamlede birden fazla satır/sütun temizleyerek katlamalı bonus puan kazan
- **Oyun sonu tespiti** — mevcut parçaların hiçbiri ızgaraya sığmadığında oyun otomatik biter

### Puan Sistemi

| Aksiyon | Puan |
|---------|------|
| Her yerleştirilen hücre | +2 |
| 1 satır / sütun temizleme | +20 |
| 2 çizgi aynı anda temizleme | +50 *(combo bonusu)* |
| 3+ çizgi aynı anda temizleme | +n×20 + bonus |

### Görsel Geri Bildirim
- **Yeşil / Kırmızı önizleme** — sürükleme sırasında geçerli/geçersiz alana anlık renk gösterimi
- **Uçan metin efektleri** — `LINE!` · `DOUBLE!` · `COMBO x3!` ekran animasyonları
- **"YENİ REKOR!" badge'i** — rekor kırılınca patlama animasyonu
- **Skor micro-animasyon** — her puan güncellemesinde label canlanır

### Platform & UX
- **Game Center liderlik tablosu** — dünyadaki diğer oyuncularla global sıralama
- **Otomatik kayıt & devam** — uygulama kapansa, çöküse ya da telefon kilitlense bile oyun kaldığı yerden devam eder
- **Haptic feedback** — yerleştirme, çizgi temizleme ve oyun sonu için ayrı titreşim profilleri
- **Ses efektleri** — her aksiyon için özel ses tasarımı (pop, temizleme, başarı, oyun sonu)
- **Arka plan Game Center auth** — kimlik doğrulama loading ekranında oyunu bloklamadan tamamlanır
- **Responsive tasarım** — SE'den Pro Max'e tüm iPhone boyutlarında pixel-perfect görünüm

---

## Teknik Detaylar

| | |
|---|---|
| **Platform** | iOS 15.5+ · iPhone · Portrait |
| **Dil** | Swift 5 |
| **Framework'ler** | SpriteKit · GameKit · UIKit |
| **Mimari** | MVC + extension tabanlı scene ayrımı |
| **Kalıcılık** | UserDefaults (JSON encoding) — sunucu yok, ağ bağlantısı gerekmez |
| **Bağımlılık** | **Sıfır** — yalnızca Apple framework'leri kullanıldı |
| **Boyutlandırma** | Tüm değerler `screenW / screenH` oransal — hardcode piksel yok |

---

## Mimari Kararlar

| Karar | Gerekçe |
|-------|---------|
| Fizik motoru kullanılmadı | Grid tabanlı mantık deterministik ve öngörülebilir olmalıydı |
| Node'lar silinmiyor, renk değiştiriliyor | Node oluşturma/silmeden kaynaklanan frame drop sorunlarını tamamen ortadan kaldırır |
| `touchesMoved`'da SKAction yok | Direkt `position` atamasıyla gecikme sıfır, sürükleme akıcı |
| `GameManagerDelegate` pattern | Skor ve durum değişiklikleri scene'e gevşek bağlı — test edilebilir |
| 3 katmanlı şekil dağıtımı | Tekrar önleme + ızgara analizi + set dengesi oyunu adil ve monoton olmayan tutar |
| Extension tabanlı scene dosyaları | `GameScene+Layout` ve `GameScene+Overlay` her dosyayı odaklı ve okunabilir tutar |

---

## Proje Yapısı

```
BlockNova/
├── App/
│   ├── AppDelegate.swift               # Uygulama yaşam döngüsü
│   └── GameViewController.swift        # SKView host, safe area yönetimi, GKGameCenterControllerDelegate
│
├── Core/
│   ├── Constants.swift                 # Boyut sabitleri (screenW/screenH oranları), renkler, puan değerleri, Game Center ID
│   ├── GameSaveManager.swift           # UserDefaults kalıcılığı (JSON encoding/decoding)
│   ├── HapticManager.swift             # UIImpactFeedbackGenerator sarmalayıcısı
│   └── SoundManager.swift              # SKAction tabanlı ses yönetimi, ses başına cooldown
│
├── Game/
│   ├── Models/
│   │   ├── BlockShape.swift            # 23 şekil tipi tanımı (offset dizileri, renkler, kategoriler)
│   │   └── GameManager.swift           # Skor yönetimi, durum makinesi, Game Center entegrasyonu
│   ├── Logic/
│   │   └── ShapeDispenser.swift        # 3 katmanlı akıllı parça üretim sistemi
│   └── ViewModels/
│       └── GameViewModel.swift         # Skor metni formatlama ve durum sorguları
│
├── UI/
│   ├── Scenes/
│   │   ├── LoadingScene.swift          # Splash ekranı + arka plan Game Center auth
│   │   ├── HomeScene.swift             # Animasyonlu ana menü
│   │   ├── GameScene.swift             # Ana oyun döngüsü ve dokunma yönetimi
│   │   ├── GameScene+Layout.swift      # Safe area'ya duyarlı responsive yerleşim
│   │   └── GameScene+Overlay.swift     # Oyun sonu modal yapısı
│   └── Nodes/
│       ├── GridNode.swift              # 8×8 ızgara görsel ve veri katmanı
│       ├── BlockNode.swift             # Tekil hücre node'u
│       ├── PieceNode.swift             # Sürüklenebilir çok hücreli parça
│       └── PreviewSlotNode.swift       # Alt tepsi slot konteyneri
│
├── Resources/
│   ├── Assets.xcassets/                # Uygulama ikonu, accent renk
│   └── Sounds/                         # pop.wav · long-pop.wav · achievement.wav · game-over.wav
│
└── SupportingFiles/
    └── BlockNova.entitlements          # Game Center yetkisi
```

---

## Öne Çıkan Teknik Detaylar

**ShapeDispenser — 3 Katmanlı Sistem**

`Game/Logic/ShapeDispenser.swift` dosyasındaki parça üreteci rastgeleliği ve adaleti dengeler:

1. **Tekrar önleme** — son 6 üretilen şekil tipini takip eder, erken tekrar eden şekillere 0.5× ceza uygular
2. **Izgara analizi** — her 3 parçada bir tahtayı analiz eder; bir satır veya sütun ≥5/8 doluysa o yönü temizleyebilecek parçaları öne çıkarır
3. **Set dengesi** — her 3'lü grup en az bir küçük, bir büyük ve bir ipucu tabanlı parça içermesi garanti edilir

Bunun üzerine bir fit-count bağ bozucu, her şekli mevcut ızgarada yerleştirilebileceği konum sayısına göre ağırlıklandırır; yerleştirilemez parçaların sunulması önlenir.

**Node Havuzu**

64 ızgara hücresi node'u oyun başlangıcında bir kez oluşturulur. Oyun sırasında yalnızca renkleri güncellenir — hiçbir node eklenmez ya da kaldırılmaz. Bu, ızgara ne kadar yoğun kullanılırsa kullanılsın render hattını 60 fps'de stabil tutar.

**Responsive Yerleşim**

Her boyut (hücre büyüklüğü, panel yükseklikleri, font boyutları, parça ofsetleri) `Constants.C` üzerinden `screenW` ve `screenH` oranlarıyla hesaplanır. Aynı binary, herhangi bir size class dallanması olmaksızın desteklenen tüm iPhone modellerinde doğru çalışır.

---

## Kurulum

Xcode 15+ gereklidir. Paket yöneticisi veya harici bağımlılık gerekmez:

```bash
git clone https://github.com/muhammedeminalan/BlockNova.git
cd BlockNova
open BlockNova.xcodeproj
```

Simulator veya fiziksel cihazda doğrudan çalıştırılabilir.

> **Not:** Game Center özellikleri (liderlik tablosu) yalnızca Apple ID ile giriş yapılmış fiziksel bir cihazda çalışır.

---

## Geliştirici

<div align="center">

**Muhammed Emin Alan**

[![GitHub](https://img.shields.io/badge/GitHub-muhammedeminalan-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/muhammedeminalan)

</div>

---

## Lisans

Bu proje [MIT Lisansı](LICENSE) altında dağıtılmaktadır.

---

<div align="center">
  <a href="https://apps.apple.com/us/app/nova-block/id6760556862">
    <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="50" alt="App Store'dan İndir"/>
  </a>
  <br/><br/>
  <sub>Swift &amp; SpriteKit ile geliştirildi</sub>
</div>
