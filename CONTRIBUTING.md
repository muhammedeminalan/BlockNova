# Contributing to BlockNova

Katkın için teşekkürler. Bu dosya, projeye güvenli ve tutarlı katkı yapma standardını tanımlar.

## 1) Ön Koşullar

- Güncel stabil Xcode
- iOS 15.6+ hedefleyebilen cihaz/simulator
- Git

## 2) Kurulum

```bash
git clone https://github.com/muhammedeminalan/BlockNova.git
cd BlockNova
open BlockNova.xcodeproj
```

## 3) Branch Stratejisi

Önerilen branch adları:
- `feature/<kisa-aciklama>`
- `fix/<kisa-aciklama>`
- `refactor/<kisa-aciklama>`
- `docs/<kisa-aciklama>`

Örnek:
`refactor/hud-layout-cleanup`

## 4) Commit Standardı

Önerilen format:

`<type>: <kısa açıklama>`

Type örnekleri:
- `feat`
- `fix`
- `refactor`
- `docs`
- `chore`

Örnek:
`fix: combo overlay tetikleme eşiğini düzelt`

## 5) Kod Standartları

- Davranışı bozmayan küçük, odaklı değişiklikler yap.
- Gameplay çekirdeğinde gereksiz refactor yapma.
- Yorum satırları kısa ve neden odaklı olsun.
- Force unwrap (`!`) ve crash üreten pattern’lerden kaçın.
- Safe area ve state akışını bozmadan ilerle.

## 6) PR Açmadan Önce

Lokal olarak en az şu kontrolleri geç:

```bash
xcodebuild -project BlockNova.xcodeproj -scheme BlockNova -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project BlockNova.xcodeproj -scheme BlockNova -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project BlockNova.xcodeproj -scheme BlockNova -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO analyze
```

Manuel smoke test:
- Home -> Game -> Settings -> Home
- Drag/drop ve combo akışı
- Game over -> replay/home
- Arka plan/ön plan state devamı

## 7) PR İçeriği

PR açıklamasında şunlar olmalı:
- Ne değişti?
- Neden değişti?
- Riskli nokta var mı?
- Nasıl test edildi?
- UI değiştiyse ekran görüntüsü/video

PR template’i otomatik gelir: `.github/PULL_REQUEST_TEMPLATE.md`

## 8) Issue Açma

- Hata bildirimi için bug template’i kullan.
- Özellik isteği için feature template’i kullan.
- Tek issue = tek problem/fikir.

## 9) Davranış Kuralları

Bu repo `CODE_OF_CONDUCT.md` dosyasına uyar. Profesyonel ve saygılı iletişim zorunludur.

