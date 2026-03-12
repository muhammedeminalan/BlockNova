// 📁 Models/ShapeDispenser.swift
// Üç katmanlı şekil dağıtım sistemi.
//
// KATMANLAR:
// 1. Shuffle Bag   — tüm 11 şeklin karıştırılmış kopyası; bitince yeniden doldurulur
// 2. Geçmiş Bellek — son 5 şeklin tipi saklanır; aynı tip yüksek olasılıkla reddedilir (%72)
// 3. Tur Tekliği   — aynı tur içinde 3 slota aynı şekil gelmemesi için 4 deneme hakkı

import Foundation

// MARK: - ShapeDispenser

final class ShapeDispenser {

    // MARK: - Ayarlar

    /// Geçmişte tutulan şekil sayısı — tekrar önlemenin "hafıza" derinliği
    private let gecmisBoyutu = 5
    /// Geçmişteki bir şeklin yeniden seçilmesini reddetme olasılığı (%72)
    private let reddetmeOlasiligi: Double = 0.72
    /// Aynı tur içinde farklı şekil bulmak için kaç deneme yapılacağı
    private let turDenemeSayisi = 4

    // MARK: - Durum

    /// Shuffle bag — boşaldıkça yeniden doldurulur
    private var torba: [BlockShape] = []
    /// Son N şeklin tip geçmişi — tekrar algılama için
    private var sonGecmis: [BlockShapeType] = []

    // MARK: - Arayüz

    /// Aynı tur içinde 3 benzersiz şekil döndürür.
    /// Hem geçmiş hem tur tekliği kuralları uygulanır.
    func ucunu() -> [BlockShape] {
        var secilen: [BlockShape] = []
        var buTurTipler: [BlockShapeType] = []

        for _ in 0..<3 {
            // Bu tur içinde zaten seçilen tipleri kaçın, geçmişi de gözet
            let sekil = cekDeneyerek(kacinilacaklar: buTurTipler)
            secilen.append(sekil)
            buTurTipler.append(sekil.type)
            gecmiseEkle(sekil.type)
        }

        return secilen
    }

    /// Yeni oyunda torba ve geçmiş sıfırlanır
    func sifirla() {
        torba.removeAll()
        sonGecmis.removeAll()
    }

    // MARK: - İç Yardımcılar

    /// Kaçınılacak tipleri göz önünde bulundurarak bir şekil çeker.
    /// turDenemeSayisi kadar dener; uygun bulamazsa rastgele çeker.
    private func cekDeneyerek(kacinilacaklar: [BlockShapeType]) -> BlockShape {
        for _ in 0..<turDenemeSayisi {
            let aday = torbadanCek()

            // Aynı tur içinde zaten var mı?
            if kacinilacaklar.contains(aday.type) { continue }

            // Geçmişte var mı ve reddedilmeli mi?
            if sonGecmis.contains(aday.type),
               Double.random(in: 0..<1) < reddetmeOlasiligi { continue }

            return aday
        }
        // Deneme hakkı bitti — geçmişi ihlal ederek rastgele çek
        return torbadanCek()
    }

    /// Torbadan bir sonraki şekli çeker; torba boşalınca yeniden doldurulur.
    private func torbadanCek() -> BlockShape {
        if torba.isEmpty { torbayiDoldur() }
        return torba.removeFirst()
    }

    /// Tüm şekilleri karıştırarak torbayı doldurur
    private func torbayiDoldur() {
        torba = BlockShape.all.shuffled()
    }

    /// Geçmişe yeni tipi ekler; boyutu gecmisBoyutu ile sınırlar
    private func gecmiseEkle(_ tip: BlockShapeType) {
        sonGecmis.append(tip)
        if sonGecmis.count > gecmisBoyutu {
            sonGecmis.removeFirst()
        }
    }
}
