// 📁 Models/ShapeDispenser.swift
// Akıllı parça üretim sistemi — 3 katmanlı denge algoritması.
//
// NEDEN SAF RANDOM YETERSİZ?
// - 11 şekil arasında saf random, kısa vadede aynı şekli üst üste verebilir.
// - Oyuncu "neden hep aynı şekil geliyor" hissiyle şikayet eder.
// - Ama tamamen belirleyici sistem de oyun hissini öldürür: tahmin edilebilir = sıkıcı.
//
// ÇÖZÜM: 3 KATMANLI AKİLLI SİSTEM
//
// KATMAN 1 — TEKRAR ÖNLEME:
//   Son 2 turda aynı tip üst üste gelmiş mi izlenir.
//   Aynı tip 2 kereden fazla üst üste gelirse havuzdan çıkarılır.
//   Oyuncu "hep aynı parça geliyor" hissi yaşamaz.
//
// KATMAN 2 — GRİD ANALİZİ:
//   Her 3'lü üretimden önce grid'in doluluk durumu incelenir.
//   Neredeyse tamamlanan satır/sütun varsa o yönde uzun parça üretilir.
//   Oyuncuya "şans" tanınmış gibi hissettirirken oyun dengesi korunur.
//
// KATMAN 3 — SET DENGESİ:
//   3'lü setin içinde daima en az 1 küçük ve 1 büyük parça bulunur.
//   3. parça hint'e göre seçilir — anlık grid durumunu ödüllendirir.
//   Sıra karıştırılır: oyuncu her zaman sürprizle karşılaşır.
//
// SINIR KOŞULU — TIKANMA ÖNLEMESİ:
//   Üretilen hiçbir parça grid'e sığmıyorsa küçük parça seti döndürülür.
//   Oyunun "önce sığmaz parça üret, sonra game over tetikle" gibi haksız
//   davranışı engellenir.

import UIKit

// MARK: - Üretim İpucu

/// Grid analizinden çıkan üretim yönlendirmesi.
/// Hangi tür parçaların seçileceğini belirler.
enum GenerationHint {
    /// Yatay uzun parça öner — neredeyse dolu satır tespit edildi
    case horizontal
    /// Dikey uzun parça öner — neredeyse dolu sütun tespit edildi
    case vertical
    /// Yön fark etmez — grid dengeli ya da boş
    case any
}

// MARK: - ShapeDispenser

final class ShapeDispenser {

    // MARK: - Sabitler

    /// Aynı tipin üst üste gelebileceği maksimum sayı.
    /// 2: "son 2 aynıysa bir daha aynı gelmesin" kuralı
    private let maksArdArdaTekrar = 2

    /// Son kaç turda üretilen tip izlenecek — tekrar tespiti için
    private let gecmisKapasite = 6

    /// Grid doluluk eşiği: bu değer veya üzeri hücre doluysa o yöne ipucu verilir.
    /// 5/8 = %62.5 doluluk — çok erken ipucu verme, çok geç de kalma
    private let gridIpucuEsigi = 5

    // MARK: - Durum

    /// Son üretilen şekil tiplerinin geçmişi — tekrar önleme için kayan pencere
    private var recentShapes: [BlockShapeType] = []

    // MARK: - Arayüz

    /// Akıllı 3'lü set döndürür. Grid analizi için mevcut cellColors iletilir.
    /// grid: GridNode.cellColors — nil=boş, UIColor=dolu
    func ucunu(grid: [[UIColor?]]? = nil) -> [BlockShape] {
        // Grid varsa tıkanma önleme ile üret, yoksa basit üretim yap
        if let grid = grid {
            return guvenliUret(grid: grid)
        }
        // Grid bilgisi yoksa (ilk tur gibi durumlarda) dengeli set üret
        return dengeliSet(hint: .any)
    }

    /// Yeni oyun başladığında geçmiş temizlenir — taze başlangıç sağlanır
    func sifirla() {
        recentShapes.removeAll()
    }

    // MARK: - Tıkanma Önleyici Üretici

    /// Üretilen parçaların grid'e sığıp sığmadığını kontrol eder.
    /// Hiçbiri sığmıyorsa küçük parçalar döndürülür — oyuncuya son şans.
    private func guvenliUret(grid: [[UIColor?]]) -> [BlockShape] {
        let hint   = gridiAnalizeEt(grid)
        let parcalar = dengeliSet(hint: hint)

        // Üretilen parçalardan en az biri grid'e sığıyor mu?
        let herhangiiBirisigiyorMu = parcalar.contains { parca in
            herhangibirYereSigiyorMu(parca, grid: grid)
        }

        if herhangiiBirisigiyorMu {
            // Normal durum: üretilen set geçerli
            return parcalar
        }

        // Hiçbiri sığmıyor — oyuncuya son şans olarak küçük parçalar ver.
        // Bu noktaya gelinmesi game over'ı geciktirmez, sadece haksız bitiş önler.
        return [
            BlockShape.shape(for: .single),
            BlockShape.shape(for: .horizontal2),
            BlockShape.shape(for: .vertical2)
        ]
    }

    // MARK: - Dengeli Set Üretimi

    /// 3'lü sette 1 küçük + 1 büyük + 1 hint parçası bulunur.
    /// Sıra karıştırılır — her zaman küçük, büyük, hint değil, rastgele sıralı gelir.
    private func dengeliSet(hint: GenerationHint) -> [BlockShape] {
        // Küçük parça: her yere sığar, nefes aldırır
        let kucukTip  = kucukHavuzdan()
        let kucukParca = BlockShape.shape(for: kucukTip)
        recenteEkle(kucukTip)

        // Büyük parça: yüksek skor potansiyeli, meydan okur
        let buyukTip  = buyukHavuzdan(kacinilacak: kucukTip)
        let buyukParca = BlockShape.shape(for: buyukTip)
        recenteEkle(buyukTip)

        // Hint parçası: grid'in anlık durumuna göre seçilir
        let hintTip   = hintHavuzdan(hint: hint, kacinilacaklar: [kucukTip, buyukTip])
        let hintParca  = BlockShape.shape(for: hintTip)
        recenteEkle(hintTip)

        // Sırayı karıştır — oyuncu seti öngörmesin
        return [kucukParca, buyukParca, hintParca].shuffled()
    }

    // MARK: - Havuz Seçiciler

    /// Küçük parça havuzundan tekrar kuralına uyan bir tip seçer.
    /// Küçük parçalar: single, horizontal2, vertical2
    private func kucukHavuzdan() -> BlockShapeType {
        let kucukler: [BlockShapeType] = [.single, .horizontal2, .vertical2]
        return tekrarsizSec(from: kucukler, kacinilacaklar: [])
    }

    /// Büyük parça havuzundan seçer. Küçük parça ile aynı olmasın.
    /// Büyük parçalar: 4+ hücreli veya 2D şekiller
    /// square3x3 de buraya dahil — nadir gelir ama gelince yüksek puan potansiyeli
    private func buyukHavuzdan(kacinilacak: BlockShapeType) -> BlockShapeType {
        let buyukler: [BlockShapeType] = [
            .square2x2, .square3x3, .lShape, .jShape, .tShape,
            .sShape, .zShape, .horizontal3, .vertical3
        ]
        return tekrarsizSec(from: buyukler, kacinilacaklar: [kacinilacak])
    }

    /// Hint'e göre yön uyumlu tip seçer. Seçilen diğerleriyle aynı olabilir.
    private func hintHavuzdan(hint: GenerationHint, kacinilacaklar: [BlockShapeType]) -> BlockShapeType {
        let havuz = hintIcinHavuz(hint)
        // Hint havuzunda kaçınılacak yoksa istediğini seç — hint öncelikli
        return tekrarsizSec(from: havuz, kacinilacaklar: kacinilacaklar)
    }

    /// Hint türüne göre uygun şekil havuzunu döndürür.
    /// Yatay hint: satır tamamlamaya yardımcı yatay uzun parçalar
    /// Dikey hint: sütun tamamlamaya yardımcı dikey uzun parçalar
    private func hintIcinHavuz(_ hint: GenerationHint) -> [BlockShapeType] {
        switch hint {
        case .horizontal:
            // Satır tamamlamada işe yarayan yatay ağırlıklı şekiller
            return [.horizontal2, .horizontal3, .tShape, .sShape, .zShape]
        case .vertical:
            // Sütun tamamlamada işe yarayan dikey ağırlıklı şekiller
            return [.vertical2, .vertical3, .lShape, .jShape]
        case .any:
            // Yön fark etmez — tüm şekiller eşit şanslı
            return Array(BlockShapeType.allCases)
        }
    }

    // MARK: - Tekrarsız Seçim

    /// Verilen havuzdan tekrar kuralına ve kaçınılacak listeye göre seçim yapar.
    /// Uygun aday bulunamazsa kısıtı kaldırarak rastgele seçer — hiç takılmaz.
    private func tekrarsizSec(from havuz: [BlockShapeType],
                               kacinilacaklar: [BlockShapeType]) -> BlockShapeType {
        // Tekrar engelini uygula: son 2'si aynıysa o tipi çıkar
        var filtrelenmisHavuz = havuz.filter { tip in
            // Bu tip kaçınılacaklar listesinde mi?
            if kacinilacaklar.contains(tip) { return false }
            // Bu tip son `maksArdArdaTekrar` sayısında üst üste gelmiş mi?
            let sonN = recentShapes.suffix(maksArdArdaTekrar)
            if sonN.count == maksArdArdaTekrar && sonN.allSatisfy({ $0 == tip }) {
                // Üst üste limit aşıldı — bu tipi engelle
                return false
            }
            return true
        }

        // Filtreleme sonucu havuz boşaldıysa (çok kısıtlayıcı durum) kısıtı kaldır
        if filtrelenmisHavuz.isEmpty {
            filtrelenmisHavuz = havuz.filter { !kacinilacaklar.contains($0) }
        }

        // Hâlâ boşsa tüm havuzu kullan — oyun hiç takılmaz
        if filtrelenmisHavuz.isEmpty {
            filtrelenmisHavuz = havuz.isEmpty ? Array(BlockShapeType.allCases) : havuz
        }

        return filtrelenmisHavuz.randomElement()!
    }

    // MARK: - Geçmiş Yönetimi

    /// Seçilen tipi geçmişe ekler; kapasiteyi aşınca en eskiyi siler.
    /// Halka tampon mantığı: sabit boyutlu kayan pencere — bellek şişmez.
    private func recenteEkle(_ tip: BlockShapeType) {
        recentShapes.append(tip)
        // Kapasite aşıldıysa en eski kaydı sil — kayan pencere
        if recentShapes.count > gecmisKapasite {
            recentShapes.removeFirst()
        }
    }

    // MARK: - Grid Analizi

    /// Grid'in doluluk durumunu analiz eder ve üretim ipucu çıkarır.
    ///
    /// MANTIK:
    /// - Her satır için o satırdaki dolu hücre sayısı hesaplanır (0-8 arası).
    /// - Her sütun için aynı hesap yapılır.
    /// - Herhangi bir satır eşiği (örn. 5+) aşmışsa → yatay parça ipucu.
    /// - Herhangi bir sütun eşiği aşmışsa → dikey parça ipucu.
    /// - İkisi de eşiği aşmamışsa → rastgele.
    ///
    /// NEDEN 5 EŞİĞİ?
    /// 8 hücreli bir satırda 5 dolu hücre = %62.5 doluluk.
    /// Bu noktada o satıra 3'lü yatay parça koyup tamamlama ihtimali yüksek.
    /// Çok erken ipucu (3-4) gürültülü; çok geç (7) zaten anlamsız.
    private func gridiAnalizeEt(_ grid: [[UIColor?]]) -> GenerationHint {
        let satirSayisi = grid.count
        guard satirSayisi > 0 else { return .any }
        let sutunSayisi = grid[0].count
        guard sutunSayisi > 0 else { return .any }

        // Her satırın dolu hücre sayısını hesapla
        var satirDoluluklar = [Int]()
        for satir in 0..<satirSayisi {
            let doluSayisi = (0..<sutunSayisi).filter { grid[satir][$0] != nil }.count
            satirDoluluklar.append(doluSayisi)
        }

        // Her sütunun dolu hücre sayısını hesapla
        var sutunDoluluklar = [Int]()
        for sutun in 0..<sutunSayisi {
            let doluSayisi = (0..<satirSayisi).filter { grid[$0][sutun] != nil }.count
            sutunDoluluklar.append(doluSayisi)
        }

        let enCokDoluSatir = satirDoluluklar.max() ?? 0
        let enCokDoluSutun = sutunDoluluklar.max() ?? 0

        // İki yön de eşiği aşıyorsa daha yüksek olanı tercih et — daha acil olan
        if enCokDoluSatir >= gridIpucuEsigi && enCokDoluSutun >= gridIpucuEsigi {
            return enCokDoluSatir >= enCokDoluSutun ? .horizontal : .vertical
        }

        // Sadece satır eşiği aşıldı → yatay parça gönder
        if enCokDoluSatir >= gridIpucuEsigi { return .horizontal }
        // Sadece sütun eşiği aşıldı → dikey parça gönder
        if enCokDoluSutun >= gridIpucuEsigi { return .vertical }

        // Grid dengeli veya yeterince boş — rastgele seç
        return .any
    }

    // MARK: - Yerleşebilirlik Kontrolü

    /// Verilen parçanın grid'de herhangi bir yere sığıp sığmadığını kontrol eder.
    /// Tüm (row, col) kombinasyonlarını dener — 8x8 küçük alan, brute force hızlı.
    private func herhangibirYereSigiyorMu(_ parca: BlockShape, grid: [[UIColor?]]) -> Bool {
        let satirSayisi = grid.count
        guard satirSayisi > 0 else { return false }
        let sutunSayisi = grid[0].count
        guard sutunSayisi > 0 else { return false }

        // Şeklin sol-üst referansını almak için minimum offsetleri hesapla
        let minSatir = parca.offsets.map(\.row).min() ?? 0
        let minSutun = parca.offsets.map(\.col).min() ?? 0

        for satir in 0..<satirSayisi {
            for sutun in 0..<sutunSayisi {
                // Bu pozisyona parçanın tüm hücreleri sığıyor mu?
                var sigiyorMu = true
                for offset in parca.offsets {
                    let r = satir + offset.row - minSatir
                    let c = sutun + offset.col - minSutun
                    // Sınır dışı veya dolu hücre → bu pozisyon geçersiz
                    if r < 0 || r >= satirSayisi || c < 0 || c >= sutunSayisi {
                        sigiyorMu = false; break
                    }
                    if grid[r][c] != nil {
                        sigiyorMu = false; break
                    }
                }
                if sigiyorMu { return true }  // En az bir pozisyon bulundu
            }
        }
        return false  // Hiçbir pozisyon uygun değil
    }
}

// MARK: - BlockShape Yardımcı Uzantısı

extension BlockShape {
    /// Tip'e göre tanımlı BlockShape nesnesini döndürür.
    /// ShapeDispenser içinde tip seçildikten sonra nesneye dönüştürmek için kullanılır.
    static func shape(for type: BlockShapeType) -> BlockShape {
        // all listesinde her tip kesinlikle var — force unwrap güvenli
        return all.first { $0.type == type }!
    }
}
