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

    /// Son turlarda tekrar eden tipler için ağırlık düşürme katsayısı
    /// 0.5 = tekrar eden tipin seçilme şansı yarıya düşer
    private let tekrarAzaltmaKatsayisi: Double = 0.5

    /// Aynı kategori tekrarını azaltma katsayısı
    /// 0.65 = aynı kategorideki parça tekrar ederse ağırlık düşer
    private let kategoriAzaltmaKatsayisi: Double = 0.65

    /// Grid doluluğu bu eşiği aşarsa küçük/yardımcı parçalara hafif ağırlık ekle
    private let crowdingHelperThreshold: Double = 0.62

    /// Yardımcı parça bias katsayısı — düşük tutulur, bariz kıyak hissi vermez
    private let crowdingHelperBoost: Double = 1.15

    // MARK: - Production Havuzları

    /// Production pool — Block Blast hissine yakın set
    private let productionPool: [BlockShapeType] = [
        .single,
        .horizontal2, .horizontal3, .horizontal4, .horizontal5,
        .vertical2, .vertical3, .vertical4, .vertical5,
        .square2x2, .square3x3, .rect2x3, .rect3x2,
        .miniL, .miniJ, .lShape, .jShape, .cornerShape,
        .smallT, .tShape,
        .sShape, .zShape
    ]

    /// Sıklık havuzları — ağırlıklandırma için
    private let commonPool: Set<BlockShapeType> = [
        .single, .horizontal2, .horizontal3, .vertical2, .vertical3, .square2x2, .miniL, .miniJ
    ]

    private let uncommonPool: Set<BlockShapeType> = [
        .horizontal4, .vertical4, .rect2x3, .rect3x2, .smallT, .lShape, .jShape, .sShape, .zShape, .cornerShape
    ]

    private let rarePool: Set<BlockShapeType> = [
        .horizontal5, .vertical5, .square3x3, .tShape
    ]

    /// Yardımcı parça havuzu — grid sıkışınca hafif bias alır
    private let helperPool: Set<BlockShapeType> = [
        .single, .horizontal2, .horizontal3, .vertical2, .vertical3, .square2x2, .miniL, .miniJ
    ]

    /// Tip → kategori map'i — tekrar penaltesi için
    private lazy var categoryMap: [BlockShapeType: ShapeCategory] = {
        Dictionary(uniqueKeysWithValues: BlockShape.all.map { ($0.type, $0.category) })
    }()

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
        return dengeliSet(hint: .any, fitMap: [:], crowding: 0)
    }

    /// Yeni oyun başladığında geçmiş temizlenir — taze başlangıç sağlanır
    func sifirla() {
        recentShapes.removeAll()
    }

    // MARK: - Tıkanma Önleyici Üretici

    /// Üretilen parçaların grid'e sığıp sığmadığını kontrol eder.
    /// Hiçbiri sığmıyorsa küçük parçalar döndürülür — oyuncuya son şans.
    private func guvenliUret(grid: [[UIColor?]]) -> [BlockShape] {
        let hint     = gridiAnalizeEt(grid)
        let fitMap   = fitCountMap(grid)
        let crowding = gridCrowdingFactor(grid)
        let parcalar = dengeliSet(hint: hint, fitMap: fitMap, crowding: crowding)

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
    private func dengeliSet(hint: GenerationHint, fitMap: [BlockShapeType: Int], crowding: Double) -> [BlockShape] {
        // Küçük parça: nefes aldırır
        let kucukTip   = sec(kucukler: true, fitMap: fitMap, kacinilacaklar: [], crowding: crowding)
        let kucukParca = BlockShape.shape(for: kucukTip)
        recenteEkle(kucukTip)

        // Büyük parça: meydan okur
        let buyukTip   = sec(kucukler: false, fitMap: fitMap, kacinilacaklar: [kucukTip], crowding: crowding)
        let buyukParca = BlockShape.shape(for: buyukTip)
        recenteEkle(buyukTip)

        // Hint parçası: grid'in anlık durumuna göre seçilir
        let hintTip    = hintHavuzdan(hint: hint, kacinilacaklar: [kucukTip, buyukTip], fitMap: fitMap, crowding: crowding)
        let hintParca  = BlockShape.shape(for: hintTip)
        recenteEkle(hintTip)

        // Sırayı karıştır — oyuncu seti öngörmesin
        return [kucukParca, buyukParca, hintParca].shuffled()
    }

    // MARK: - Havuz Seçiciler

    /// Küçük parça havuzundan tekrar kuralına uyan bir tip seçer.
    /// Küçük parçalar: single, horizontal2, vertical2
    private func sec(kucukler: Bool,
                     fitMap: [BlockShapeType: Int],
                     kacinilacaklar: [BlockShapeType],
                     crowding: Double) -> BlockShapeType {
        let kucukHavuz: [BlockShapeType] = [
            .single, .horizontal2, .horizontal3, .vertical2, .vertical3, .square2x2, .miniL, .miniJ
        ]
        let buyukHavuz: [BlockShapeType] = productionPool.filter { !kucukHavuz.contains($0) }
        let havuz = kucukler ? kucukHavuz : buyukHavuz
        return agirlikliSec(from: havuz, kacinilacaklar: kacinilacaklar, fitMap: fitMap, crowding: crowding)
    }

    /// Hint'e göre yön uyumlu tip seçer. Seçilen diğerleriyle aynı olabilir.
    private func hintHavuzdan(hint: GenerationHint,
                              kacinilacaklar: [BlockShapeType],
                              fitMap: [BlockShapeType: Int],
                              crowding: Double) -> BlockShapeType {
        let havuz = hintIcinHavuz(hint)
        return agirlikliSec(from: havuz, kacinilacaklar: kacinilacaklar, fitMap: fitMap, crowding: crowding)
    }

    /// Hint türüne göre uygun şekil havuzunu döndürür.
    /// Yatay hint: satır tamamlamaya yardımcı yatay uzun parçalar
    /// Dikey hint: sütun tamamlamaya yardımcı dikey uzun parçalar
    private func hintIcinHavuz(_ hint: GenerationHint) -> [BlockShapeType] {
        switch hint {
        case .horizontal:
            // Satır tamamlamada işe yarayan yatay ağırlıklı şekiller
            return [.horizontal2, .horizontal3, .horizontal4, .horizontal5, .rect3x2, .tShape, .smallT, .sShape, .zShape]
        case .vertical:
            // Sütun tamamlamada işe yarayan dikey ağırlıklı şekiller
            return [.vertical2, .vertical3, .vertical4, .vertical5, .rect2x3, .lShape, .jShape, .miniL, .miniJ, .cornerShape]
        case .any:
            // Yön fark etmez — tüm şekiller eşit şanslı
            return productionPool
        }
    }

    // MARK: - Tekrarsız Seçim

    /// Verilen havuzdan tekrar kuralına ve kaçınılacak listeye göre seçim yapar.
    /// Uygun aday bulunamazsa kısıtı kaldırarak rastgele seçer — hiç takılmaz.
    private func agirlikliSec(from havuz: [BlockShapeType],
                              kacinilacaklar: [BlockShapeType],
                              fitMap: [BlockShapeType: Int],
                              crowding: Double) -> BlockShapeType {
        let sonN = recentShapes.suffix(maksArdArdaTekrar)

        var adaylar = havuz.filter { !kacinilacaklar.contains($0) }
        if adaylar.isEmpty { adaylar = havuz }
        if adaylar.isEmpty { adaylar = productionPool }

        // Fit count olanlar varken 0-fit olanları ele — gereksiz tıkanmayı azalt
        let fitliAdaylar = adaylar.filter { (fitMap[$0] ?? 0) > 0 }
        if !fitliAdaylar.isEmpty { adaylar = fitliAdaylar }

        var weights: [Int] = []
        weights.reserveCapacity(adaylar.count)

        for tip in adaylar {
            // Üst üste tekrar kuralı: son N aynıysa tamamen engelle
            if sonN.count == maksArdArdaTekrar && sonN.allSatisfy({ $0 == tip }) {
                weights.append(0)
                continue
            }

            let fitCount = max(1, fitMap[tip] ?? 1)
            let tekrarSayisi = recentShapes.filter { $0 == tip }.count
            let tekrarCarpani = pow(tekrarAzaltmaKatsayisi, Double(tekrarSayisi))
            let kategori = categoryMap[tip] ?? .micro
            let kategoriTekrarSayisi = recentShapes.map { categoryMap[$0] ?? .micro }.filter { $0 == kategori }.count
            let kategoriCarpani = pow(kategoriAzaltmaKatsayisi, Double(kategoriTekrarSayisi))

            let baseWeight = agirlikTabani(for: tip)
            var weightDouble = Double(baseWeight) * Double(fitCount) * tekrarCarpani * kategoriCarpani

            // Grid çok doluysa küçük/yardımcı parçalara hafif bias
            if crowding >= crowdingHelperThreshold, helperPool.contains(tip) {
                weightDouble *= crowdingHelperBoost
            }

            let weight = max(1, Int(weightDouble.rounded(.toNearestOrAwayFromZero)))
            weights.append(weight)
        }

        // Eğer tüm ağırlıklar 0 olduysa düz random fallback
        if weights.allSatisfy({ $0 == 0 }) {
            return adaylar.randomElement() ?? (BlockShapeType.allCases.randomElement() ?? .single)
        }

        return agirlikliRastgeleSec(adaylar, weights: weights)
    }

    /// Ağırlıklı rastgele seçim — performans: küçük havuz, basit O(n)
    private func agirlikliRastgeleSec(_ adaylar: [BlockShapeType], weights: [Int]) -> BlockShapeType {
        let toplam = weights.reduce(0, +)
        guard toplam > 0 else { return adaylar.randomElement() ?? .single }
        var hedef = Int.random(in: 0..<toplam)
        for (i, w) in weights.enumerated() {
            hedef -= w
            if hedef < 0 { return adaylar[i] }
        }
        return adaylar.last ?? .single
    }

    /// Tipin base ağırlığını üretir — frequency kontrolü
    private func agirlikTabani(for tip: BlockShapeType) -> Int {
        if commonPool.contains(tip) { return 10 }
        if uncommonPool.contains(tip) { return 6 }
        if rarePool.contains(tip) { return 3 }
        return 5
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

    /// Grid doluluk oranını 0...1 aralığında verir — helper bias için
    private func gridCrowdingFactor(_ grid: [[UIColor?]]) -> Double {
        let satirSayisi = grid.count
        guard satirSayisi > 0 else { return 0 }
        let sutunSayisi = grid[0].count
        guard sutunSayisi > 0 else { return 0 }
        let toplam = satirSayisi * sutunSayisi
        var dolu = 0
        for satir in 0..<satirSayisi {
            for sutun in 0..<sutunSayisi {
                if grid[satir][sutun] != nil { dolu += 1 }
            }
        }
        return Double(dolu) / Double(toplam)
    }

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

    // MARK: - Fit Sayımı (Akıllı Üretim)

    /// Grid üzerinde her tip için kaç farklı yerleşim noktası olduğunu sayar.
    /// Değer büyüdükçe parça daha "esnek" kabul edilir.
    private func fitCountMap(_ grid: [[UIColor?]]) -> [BlockShapeType: Int] {
        var map: [BlockShapeType: Int] = [:]
        for shape in BlockShape.all {
            map[shape.type] = fitCount(shape, grid: grid)
        }
        return map
    }

    /// Verilen şeklin grid'e kaç farklı pozisyona sığabildiğini sayar.
    /// 8x8 küçük alan için brute force güvenli ve hızlı.
    private func fitCount(_ parca: BlockShape, grid: [[UIColor?]]) -> Int {
        let satirSayisi = grid.count
        guard satirSayisi > 0 else { return 0 }
        let sutunSayisi = grid[0].count
        guard sutunSayisi > 0 else { return 0 }

        let minSatir = parca.offsets.map(\.row).min() ?? 0
        let minSutun = parca.offsets.map(\.col).min() ?? 0

        var count = 0
        for satir in 0..<satirSayisi {
            for sutun in 0..<sutunSayisi {
                var sigiyorMu = true
                for offset in parca.offsets {
                    let r = satir + offset.row - minSatir
                    let c = sutun + offset.col - minSutun
                    if r < 0 || r >= satirSayisi || c < 0 || c >= sutunSayisi {
                        sigiyorMu = false; break
                    }
                    if grid[r][c] != nil {
                        sigiyorMu = false; break
                    }
                }
                if sigiyorMu { count += 1 }
            }
        }
        return count
    }
}

// MARK: - BlockShape Yardımcı Uzantısı

extension BlockShape {
    /// Tip'e göre tanımlı BlockShape nesnesini döndürür.
    /// ShapeDispenser içinde tip seçildikten sonra nesneye dönüştürmek için kullanılır.
    static func shape(for type: BlockShapeType) -> BlockShape {
        // Güvenli arama: yeni type eklenip all'a eklenmezse crash yerine varsayılan döner
        guard let shape = all.first(where: { $0.type == type }) else {
            return all[0]
        }
        return shape
    }
}
