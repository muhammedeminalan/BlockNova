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
    case vertical2   = "vertical2"
    case vertical3   = "vertical3"
    case square2x2   = "square2x2"
    case square3x3   = "square3x3"  // 3x3 tam kare — 9 hücre, en büyük şekil
    case lShape      = "lShape"
    case jShape      = "jShape"
    case tShape      = "tShape"
    case sShape      = "sShape"
    case zShape      = "zShape"
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
    /// 11 farklı şeklin tam listesi.
    /// Renkler Constants.swift'teki neon palete göre atanmıştır — tutarlı görünüm için.
    static let all: [BlockShape] = [
        // Tek hücre — basit, her yere sığar
        BlockShape(type: .single,
                   offsets: [(0,0)],
                   color: C.colorSingle),

        // 2'li yatay — dar yerlere sığar
        BlockShape(type: .horizontal2,
                   offsets: [(0,0),(0,1)],
                   color: C.colorH2),

        // 3'lü yatay — satır tamamlama için ideal
        BlockShape(type: .horizontal3,
                   offsets: [(0,0),(0,1),(0,2)],
                   color: C.colorH3),

        // 2'li dikey — dar sütunları doldurur
        BlockShape(type: .vertical2,
                   offsets: [(0,0),(1,0)],
                   color: C.colorV2),

        // 3'lü dikey — sütun tamamlama için ideal
        BlockShape(type: .vertical3,
                   offsets: [(0,0),(1,0),(2,0)],
                   color: C.colorV3),

        // 2x2 kare — köşe/alan doldurma
        BlockShape(type: .square2x2,
                   offsets: [(0,0),(0,1),(1,0),(1,1)],
                   color: C.colorSquare),

        // 3x3 tam dolu kare — 9 hücre, en büyük ve en yüksek skorlu şekil
        // Satır+sütun kombinasyonları silerse muazzam combo yapılabilir
        BlockShape(type: .square3x3,
                   offsets: [(0,0),(0,1),(0,2),
                              (1,0),(1,1),(1,2),
                              (2,0),(2,1),(2,2)],
                   color: C.colorSquare3),

        // L şekli — sağ alt köşeyi doldurur
        BlockShape(type: .lShape,
                   offsets: [(0,0),(1,0),(2,0),(2,1)],
                   color: C.colorL),

        // J şekli — sol alt köşeyi doldurur (L'nin aynası)
        BlockShape(type: .jShape,
                   offsets: [(0,1),(1,1),(2,0),(2,1)],
                   color: C.colorJ),

        // T şekli — orta satırı çıkıntılı doldurur
        BlockShape(type: .tShape,
                   offsets: [(0,0),(0,1),(0,2),(1,1)],
                   color: C.colorT),

        // S şekli — çapraz adım
        BlockShape(type: .sShape,
                   offsets: [(0,1),(0,2),(1,0),(1,1)],
                   color: C.colorS),

        // Z şekli — S'nin aynası
        BlockShape(type: .zShape,
                   offsets: [(0,0),(0,1),(1,1),(1,2)],
                   color: C.colorZ),
    ]

}
