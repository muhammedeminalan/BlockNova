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
    // Grid ölçüsü hem genişlik hem kullanılabilir yükseklikten hesaplanır
    // Böylece kısa ekranlarda taşma olmaz, uzun ekranlarda daha büyük görünür
    static var gridTotalWidth: CGFloat {
        let usableH = max(0, screenH - topPanelHeight - bottomPanelHeight)
        let maxByWidth  = screenW * 0.92
        let maxByHeight = usableH * 0.96
        return min(maxByWidth, maxByHeight)
    }
    // Kare grid: genişlik = yükseklik
    static var gridTotalHeight: CGFloat { gridTotalWidth }

    // Hücre boyutu: toplam genişliği 8 sütuna böl
    // cellSize otomatik olarak cihaza göre ölçeklenir
    static var cellSize: CGFloat { gridTotalWidth / CGFloat(cols) }

    // Hücre görsel boyutu: oran kullanarak hücreler arasında nefes alanı bırak
    static var cellVisualSize: CGFloat { cellSize * 0.88 }

    // MARK: - Panel Yükseklikleri (Responsive)
    // Üst skor paneli: ekranın %11'i
    static var topPanelHeight: CGFloat { screenH * 0.11 }
    // Alt parça paneli: ekranın %20'si — 3 parçayı rahatça barındırır
    static var bottomPanelHeight: CGFloat { screenH * 0.20 }

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
    // 0.82 oran: parcalar buyuk gorunur ama panelde tasma yapmaz
    static var previewCellSize: CGFloat { cellSize * 0.82 }

    // MARK: - Preview Slot
    static var previewSlotSize: CGSize {
        CGSize(width: screenW / 3, height: bottomPanelHeight * 0.78)
    }
    static let previewSlotPaddingFactor: CGFloat = 0.12
    static let previewScaleMin: CGFloat = 0.60
    static let previewScaleMax: CGFloat = 1.15
    static let previewScaleTransition: TimeInterval = 0.08

    // MARK: - Surukleme
    // Parmak parcayi kapatmasin diye sabit yukari ofset — hucre boyutuna gore hesaplanir
    // Sabit ofset kullanmak, parmak nereye dokunsa da parcayi gorunur tutar
    // 2.2 kat: parça parmağın üstünde kalır, ama fazla kopuk hissettirmez
    static var dragOffsetY: CGFloat { cellSize * 2.2 }
    // Küçük hareketleri yok sayma — jitter ve gereksiz hesap azaltma
    static var dragMinDistance: CGFloat { cellSize * 0.05 }
    // Drag sırasında hafif "lift" ölçeği — görsel geri bildirim
    static let dragLiftScale: CGFloat = 1.04

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
    static let bgColor          = UIColor(red: 0.06, green: 0.07, blue: 0.14, alpha: 1.0)
    // Grid arka planı — bgColor'dan biraz daha açık, grid alanını hissettirir
    static let gridBgColor      = UIColor(red: 0.09, green: 0.10, blue: 0.20, alpha: 1.0)
    // Boş hücre rengi — grid içinde görünür ama dikkat dağıtmaz
    static let cellEmptyColor   = UIColor(red: 0.14, green: 0.15, blue: 0.30, alpha: 1.0)
    // Hücre kenarlık rengi — hafif belirgin
    static let cellBorderColor  = UIColor(red: 0.22, green: 0.24, blue: 0.42, alpha: 1.0)
    // Panel arka planı — hafif saydam, içeriği öne çıkarır
    static let panelColor       = UIColor(red: 0.09, green: 0.10, blue: 0.20, alpha: 0.96)
    // Vurgu rengi (cyan) — başlık, etiket ön planları için
    static let accentColor      = UIColor(red: 0.26, green: 0.85, blue: 1.00, alpha: 1.0)
    // Altın rengi — rekor skoru için
    static let goldColor        = UIColor(red: 1.00, green: 0.86, blue: 0.10, alpha: 1.0)
    // Geçerli highlight — yerleştirilebilir alan yeşil
    static let highlightValid   = UIColor(red: 0.20, green: 0.90, blue: 0.45, alpha: 0.70)
    // Geçersiz highlight — yerleştirilemeyen alan kırmızı
    static let highlightInvalid = UIColor(red: 0.98, green: 0.30, blue: 0.30, alpha: 0.70)

    // MARK: - Blok Renkleri (Neon Palet)
    // Her şekil tipi sabit bir renk alır — oyuncu şekli renkle tanır
    static let colorSingle      = UIColor(hex: "#FF5C6C") // Canlı kırmızı
    static let colorH2          = UIColor(hex: "#FF7A3D") // Sıcak turuncu
    static let colorH3          = UIColor(hex: "#FFD166") // Altın sarı
    static let colorV2          = UIColor(hex: "#2FE38C") // Taze yeşil
    static let colorV3          = UIColor(hex: "#3A8DFF") // Parlak mavi
    static let colorSquare      = UIColor(hex: "#8B6CFF") // Canlı mor
    static let colorL           = UIColor(hex: "#FF6FB1") // Canlı pembe
    static let colorJ           = UIColor(hex: "#00D4D8") // Turkuaz
    static let colorT           = UIColor(hex: "#FF9F43") // Amber
    static let colorS           = UIColor(hex: "#52E35F") // Lime yeşil
    static let colorZ           = UIColor(hex: "#D774FF") // Orkide
    static let colorSquare3     = UIColor(hex: "#FF3D5A") // Ateş kırmızısı — 3x3 en büyük blok
    static let colorH4          = UIColor(hex: "#00C2FF") // Uzun yatay (4)
    static let colorH5          = UIColor(hex: "#2ACBFF") // Uzun yatay (5)
    static let colorV4          = UIColor(hex: "#6DD400") // Uzun dikey (4)
    static let colorV5          = UIColor(hex: "#4CD137") // Uzun dikey (5)
    static let colorRect2x3     = UIColor(hex: "#FFB347") // 2x3 dikdörtgen
    static let colorRect3x2     = UIColor(hex: "#FFA24B") // 3x2 dikdörtgen
    static let colorMiniL       = UIColor(hex: "#FF6BCB") // Mini L
    static let colorMiniJ       = UIColor(hex: "#4DE2FF") // Mini J
    static let colorCorner      = UIColor(hex: "#9C7CFF") // Corner
    static let colorSmallT      = UIColor(hex: "#FFC857") // Small T

    // MARK: - Font
    // Tipografi tutarliligi icin merkezi font adlari
    static let fontBold   = "AvenirNext-Bold"
    static let fontMedium = "AvenirNext-Medium"

    // MARK: - UserDefaults Anahtari
    // Rekor skor tek anahtar uzerinden saklanir
    static let highScoreKey = "BlockBlast_HighScore"

    // MARK: - Game Center
    static let leaderboardID = "com.novablock.highscore"
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
