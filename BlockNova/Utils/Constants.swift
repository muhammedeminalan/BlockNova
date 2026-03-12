// 📁 Utils/Constants.swift
// Oyun genelinde kullanılan tüm sabit ve hesaplanmış değerler burada merkezi olarak tutulur.
// Tek bir yerden değiştirmek tüm oyunu etkiler — "magic number" kullanımını önler.
// Responsive tasarım: sabit px değeri yok, her şey scene boyutuna göre hesaplanır.

import SpriteKit
import UIKit

// MARK: - Merkezi Sabitler
enum C {

    // MARK: - Scene Boyutlari
    // Scene size tek kaynak olarak tutulur; layout hesaplari buradan beslenir.
    private static var sceneSize: CGSize = UIScreen.main.bounds.size

    /// Scene boyutu degistiginde merkezi hesaplari gunceller
    static func updateSceneSize(_ size: CGSize) {
        // Boyut degisimi sonrasinda tum responsive degerler yeni size'a gore hesaplanir
        sceneSize = size
    }

    /// Scene genisligi — tum responsive hesaplarin temel girdisi
    static var screenW: CGFloat { sceneSize.width }
    /// Scene yuksekligi — tum responsive hesaplarin temel girdisi
    static var screenH: CGFloat { sceneSize.height }

    // MARK: - Sütun / Satır Sayısı
    // Oyun mekaniği 8x8 üzerine kurulu — değiştirme
    static let cols: Int = 8
    static let rows: Int = 8

    // MARK: - Grid Boyutu (Responsive)
    // Scene genişliğinin %88'i: iPhone SE (375pt) → 330pt, Pro Max (430pt) → 378pt
    // Kenarlardan padding bırakarak tüm cihazlarda taşmayı önler
    static var gridTotalWidth: CGFloat { screenW * 0.88 }
    // Kare grid: genişlik = yükseklik
    static var gridTotalHeight: CGFloat { gridTotalWidth }

    // Hücre boyutu: toplam genişliği 8 sütuna böl
    // cellSize otomatik olarak cihaza göre ölçeklenir
    static var cellSize: CGFloat { gridTotalWidth / CGFloat(cols) }

    // Hücre görsel boyutu: aralarında 2pt boşluk bırakmak için
    // cellSize - 3: hücreler arasında nefes alanı bırakır, grid daha modern görünür
    static var cellVisualSize: CGFloat { cellSize - 3 }

    // MARK: - Panel Yükseklikleri (Responsive)
    // Üst skor paneli: ekranın %12'si
    static var topPanelHeight: CGFloat { screenH * 0.12 }
    // Alt parça paneli: ekranın %22'si — 3 parçayı rahatça barındırır
    static var bottomPanelHeight: CGFloat { screenH * 0.22 }

    // MARK: - Grid Merkezi (Varsayılan)
    // Bu hesap safe area bilgisi olmayan durumlar için varsayılan merkezdir
    static var gridCenterX: CGFloat { screenW / 2 }
    static var gridCenterY: CGFloat {
        // Üst ve alt paneller için boşluk bırakmadan grid'i ortalamak kritik
        let usable = screenH - topPanelHeight - bottomPanelHeight
        return bottomPanelHeight + usable / 2
    }

    // MARK: - Parça Önizleme Ölçeği
    // Alt paneldeki parcalar grid hucrelerinden biraz kucuk gorunmeli
    // 0.85 oran: parcalar buyuk gorunur ama panelde tasma yapmaz
    static var previewCellSize: CGFloat { cellSize * 0.85 }

    // MARK: - Surukleme
    // Parmak parcayi kapatmasin diye yukari ofset — hucre boyutuna gore hesaplanir
    static var dragOffsetY: CGFloat { cellSize * 1.1 }

    // MARK: - Z Pozisyonları (Katman Sırası)
    // Daha büyük zPosition daha önde görünür — katman çakışmasını önler
    static let zBackground: CGFloat = 0
    static let zGrid:       CGFloat = 1
    static let zCell:       CGFloat = 2
    static let zPanel:      CGFloat = 5
    static let zPiece:      CGFloat = 10
    static let zDrag:       CGFloat = 100
    static let zUI:         CGFloat = 20
    static let zOverlay:    CGFloat = 200

    // MARK: - Renkler
    // Koyu lacivert arka plan — gözü yormaz, bloklar öne çıkar
    static let bgColor          = UIColor(red: 0.07, green: 0.07, blue: 0.16, alpha: 1.0)
    // Grid arka planı — bgColor'dan biraz daha açık, grid alanını hissettirir
    static let gridBgColor      = UIColor(red: 0.09, green: 0.09, blue: 0.20, alpha: 1.0)
    // Boş hücre rengi — grid içinde görünür ama dikkat dağıtmaz
    static let cellEmptyColor   = UIColor(red: 0.13, green: 0.13, blue: 0.28, alpha: 1.0)
    // Hücre kenarlık rengi — hafif belirgin
    static let cellBorderColor  = UIColor(red: 0.20, green: 0.20, blue: 0.40, alpha: 1.0)
    // Panel arka planı — hafif saydam, içeriği öne çıkarır
    static let panelColor       = UIColor(red: 0.10, green: 0.10, blue: 0.22, alpha: 0.95)
    // Vurgu rengi (açık mavi) — başlık, etiket ön planları için
    static let accentColor      = UIColor(red: 0.40, green: 0.80, blue: 1.00, alpha: 1.0)
    // Altın rengi — rekor skoru için
    static let goldColor        = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 1.0)
    // Geçerli highlight — yerleştirilebilir alan yeşil
    static let highlightValid   = UIColor(red: 0.18, green: 0.85, blue: 0.40, alpha: 0.65)
    // Geçersiz highlight — yerleştirilemeyen alan kırmızı
    static let highlightInvalid = UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 0.65)

    // MARK: - Blok Renkleri (Neon Palet)
    // Her şekil tipi sabit bir renk alır — oyuncu şekli renkle tanır
    static let colorSingle      = UIColor(hex: "#FF4757") // Kırmızı
    static let colorH2          = UIColor(hex: "#FF6B35") // Turuncu
    static let colorH3          = UIColor(hex: "#FFD700") // Altın
    static let colorV2          = UIColor(hex: "#2ED573") // Yeşil
    static let colorV3          = UIColor(hex: "#1E90FF") // Mavi
    static let colorSquare      = UIColor(hex: "#7B68EE") // Mor
    static let colorL           = UIColor(hex: "#FF69B4") // Pembe
    static let colorJ           = UIColor(hex: "#00CED1") // Turkuaz
    static let colorT           = UIColor(hex: "#FFA500") // Koyu Turuncu
    static let colorS           = UIColor(hex: "#32CD32") // Lime Yesil
    static let colorZ           = UIColor(hex: "#DA70D6") // Orkide

    // MARK: - Font
    // Tipografi tutarliligi icin merkezi font adlari
    static let fontBold   = "AvenirNext-Bold"
    static let fontMedium = "AvenirNext-Medium"

    // MARK: - UserDefaults Anahtari
    // Rekor skor tek anahtar uzerinden saklanir
    static let highScoreKey = "BlockBlast_HighScore"
}

// MARK: - UIColor Hex Uzantisi
// "#RRGGBB" formatinda renk tanimlamayi kolaylastirir — renk kodu dogrudan yazilabilir
extension UIColor {
    /// Hex string'den UIColor uretir. "#" prefix opsiyonel. Gecersiz hex → siyah.
    convenience init(hex: String) {
        // String temizligi: bosluk ve yeni satir karakterlerini sil
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        // "#" varsa kaldir — parsingle uyum icin
        if s.hasPrefix("#") { s.removeFirst() }
        // RGB degerini okuma
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        // 0-255 araligini 0-1 araligina cevir — UIColor beklediginden
        self.init(
            red:   CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8)  & 0xFF) / 255,
            blue:  CGFloat(rgb         & 0xFF) / 255,
            alpha: 1
        )
    }

    /// UIColor → SKColor donusumu (iOS'ta ayni sinif, ama acik cevirim icin)
    var sk: SKColor { SKColor(cgColor: self.cgColor) }
}
