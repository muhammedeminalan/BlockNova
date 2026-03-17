// 📁 Models/BlockShape.swift
// Oyundaki tüm blok şekillerini tanımlar.
// Her şekil: tip, hücre offsetleri (row/col), renk.
// Offset listesi (0,0) sol-üst köşe baz alınarak tanımlanır.
// Sabit renk ataması: oyuncu şekli rengiyle anında tanır, sezgisel oynanış sağlar.

import UIKit

// MARK: - Şekil Tipleri
// String rawValue eklendi — GameSaveManager'da JSON serileştirme için gerekli
enum BlockShapeType: String, CaseIterable {
    case single      = "single"
    case horizontal2 = "horizontal2"
    case horizontal3 = "horizontal3"
    case horizontal4 = "horizontal4"
    case horizontal5 = "horizontal5"
    case vertical2   = "vertical2"
    case vertical3   = "vertical3"
    case vertical4   = "vertical4"
    case vertical5   = "vertical5"
    case square2x2   = "square2x2"
    case rect2x3     = "rect2x3"
    case rect3x2     = "rect3x2"
    case square3x3   = "square3x3"  // 3x3 tam kare — 9 hücre, en büyük şekil
    case lShape      = "lShape"
    case jShape      = "jShape"
    case miniL       = "miniL"
    case miniJ       = "miniJ"
    case cornerShape = "cornerShape"
    case smallT      = "smallT"
    case tShape      = "tShape"
    case sShape      = "sShape"
    case zShape      = "zShape"
}

// MARK: - Şekil Kategorileri
enum ShapeCategory {
    case micro
    case line
    case rectangle
    case corner
    case tType
    case zigzag
}

// MARK: - BlockShape Modeli
struct BlockShape {
    /// Hangi şekil tipi — tip kontrolü ve eşleştirme için
    let type: BlockShapeType
    /// Hücre offsetleri: (0,0) şeklin sol-üst köşesi
    /// row arttıkça aşağı, col arttıkça sağa gider
    let offsets: [(row: Int, col: Int)]
    /// Şeklin rengi — her tip için sabit, oyuncu bunu ezberler
    let color: UIColor
    /// Şeklin kategorisi — üretim çeşitliliği için
    let category: ShapeCategory

    // MARK: - Ölçüler
    /// Şeklin kaç satır kapladığı — yerleştirme ve önizleme boyutlandırması için
    var rowSpan: Int { (offsets.map(\.row).max() ?? 0) + 1 }
    /// Şeklin kaç sütun kapladığı
    var colSpan: Int { (offsets.map(\.col).max() ?? 0) + 1 }
    /// Toplam hücre sayısı — skor hesabı için
    var cellCount: Int { offsets.count }
}

// MARK: - Tüm Şekiller
extension BlockShape {
    /// Tüm şekillerin tam listesi.
    /// Renkler Constants.swift'teki neon palete göre atanmıştır — tutarlı görünüm için.
    static let all: [BlockShape] = [
        // Tek hücre — basit, her yere sığar
        BlockShape(type: .single,
                   offsets: [(0,0)],
                   color: C.colorSingle,
                   category: .micro),

        // 2'li yatay — dar yerlere sığar
        BlockShape(type: .horizontal2,
                   offsets: [(0,0),(0,1)],
                   color: C.colorH2,
                   category: .line),

        // 3'lü yatay — satır tamamlama için ideal
        BlockShape(type: .horizontal3,
                   offsets: [(0,0),(0,1),(0,2)],
                   color: C.colorH3,
                   category: .line),

        // 4'lü yatay — uzun satır boşlukları için güçlü parça
        BlockShape(type: .horizontal4,
                   offsets: [(0,0),(0,1),(0,2),(0,3)],
                   color: C.colorH4,
                   category: .line),

        // 5'li yatay — uzun satır boşlukları için güçlü parça
        BlockShape(type: .horizontal5,
                   offsets: [(0,0),(0,1),(0,2),(0,3),(0,4)],
                   color: C.colorH5,
                   category: .line),

        // 2'li dikey — dar sütunları doldurur
        BlockShape(type: .vertical2,
                   offsets: [(0,0),(1,0)],
                   color: C.colorV2,
                   category: .line),

        // 3'lü dikey — sütun tamamlama için ideal
        BlockShape(type: .vertical3,
                   offsets: [(0,0),(1,0),(2,0)],
                   color: C.colorV3,
                   category: .line),

        // 4'lü dikey — uzun sütun boşlukları için güçlü parça
        BlockShape(type: .vertical4,
                   offsets: [(0,0),(1,0),(2,0),(3,0)],
                   color: C.colorV4,
                   category: .line),

        // 5'li dikey — uzun sütun boşlukları için güçlü parça
        BlockShape(type: .vertical5,
                   offsets: [(0,0),(1,0),(2,0),(3,0),(4,0)],
                   color: C.colorV5,
                   category: .line),

        // 2x2 kare — köşe/alan doldurma
        BlockShape(type: .square2x2,
                   offsets: [(0,0),(0,1),(1,0),(1,1)],
                   color: C.colorSquare,
                   category: .rectangle),

        // 2x3 dikdörtgen — alan doldurma için orta zorlukta parça
        BlockShape(type: .rect2x3,
                   offsets: [(0,0),(0,1),(0,2),
                             (1,0),(1,1),(1,2)],
                   color: C.colorRect2x3,
                   category: .rectangle),

        // 3x2 dikdörtgen — 2x3'ün yatay versiyonu
        BlockShape(type: .rect3x2,
                   offsets: [(0,0),(0,1),
                             (1,0),(1,1),
                             (2,0),(2,1)],
                   color: C.colorRect3x2,
                   category: .rectangle),

        // 3x3 tam dolu kare — 9 hücre, en büyük ve en yüksek skorlu şekil
        // Satır+sütun kombinasyonları silerse muazzam combo yapılabilir
        BlockShape(type: .square3x3,
                   offsets: [(0,0),(0,1),(0,2),
                              (1,0),(1,1),(1,2),
                              (2,0),(2,1),(2,2)],
                   color: C.colorSquare3,
                   category: .rectangle),

        // L şekli — sağ alt köşeyi doldurur
        BlockShape(type: .lShape,
                   offsets: [(0,0),(1,0),(2,0),(2,1)],
                   color: C.colorL,
                   category: .corner),

        // J şekli — sol alt köşeyi doldurur (L'nin aynası)
        BlockShape(type: .jShape,
                   offsets: [(0,1),(1,1),(2,0),(2,1)],
                   color: C.colorJ,
                   category: .corner),

        // Mini L — kısa köşe parçası
        BlockShape(type: .miniL,
                   offsets: [(0,0),(1,0),(1,1)],
                   color: C.colorMiniL,
                   category: .corner),

        // Mini J — mini L'nin aynası
        BlockShape(type: .miniJ,
                   offsets: [(0,1),(1,0),(1,1)],
                   color: C.colorMiniJ,
                   category: .corner),

        // Corner şekli — farklı köşe orientasyonu
        BlockShape(type: .cornerShape,
                   offsets: [(0,0),(0,1),(1,1)],
                   color: C.colorCorner,
                   category: .corner),

        // Small T — dar T
        BlockShape(type: .smallT,
                   offsets: [(0,0),(0,1),(0,2),
                             (1,1),(2,1)],
                   color: C.colorSmallT,
                   category: .tType),

        // T şekli — orta satırı çıkıntılı doldurur
        BlockShape(type: .tShape,
                   offsets: [(0,0),(0,1),(0,2),(1,1)],
                   color: C.colorT,
                   category: .tType),

        // S şekli — çapraz adım
        BlockShape(type: .sShape,
                   offsets: [(0,1),(0,2),(1,0),(1,1)],
                   color: C.colorS,
                   category: .zigzag),

        // Z şekli — S'nin aynası
        BlockShape(type: .zShape,
                   offsets: [(0,0),(0,1),(1,1),(1,2)],
                   color: C.colorZ,
                   category: .zigzag),
    ]

}
