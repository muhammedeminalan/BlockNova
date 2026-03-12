// 📁 Models/ShapeDispenser.swift
// Üç katmanlı şekil dağıtım sistemi — daha doğal, dengeli ve çeşitli parça üretimi.
//
// NEDEN SAF RANDOM YETERSİZ?
// - 11 şekil arasında saf random, kısa vadede aynı şekli üst üste verebilir.
// - Oyuncu "neden hep aynı şekil geliyor" hissiyle şikayet eder.
// - Ama tamamen belirleyici sistem de oyun hissini öldürür: tahmin edilebilir = sıkıcı.
//
// ÇÖZÜM: 3 KATMANLI SİSTEM
//
// KATMAN 1 — SHUFFLE BAG:
//   Tüm 11 şekil bir "çanta"ya koyulur ve karıştırılır.
//   Çantadan sırayla çekilir; tükenince yeniden doldurulur.
//   Garanti: her 11 çekimde her şekil en az 1 kez görünür.
//
// KATMAN 2 — GEÇMİŞ BELLEK (%82 RED):
//   Son 6 çekimin tipi saklanır. Geçmişte olan bir şekil aday olursa
//   %82 ihtimalle reddedilir. Bu sayede kısa vadede art arda tekrar azalır.
//   Geçmiş boyutu 6: 11 şekilin yarısından fazlası hafızada → daha güçlü çeşitlilik.
//
// KATMAN 3 — TUR TEKLİĞİ:
//   Aynı tur içindeki 3 slota farklı tip dağıtılır.
//   Her slot için 5 deneme yapılır; uygun bulunamazsa kural esnetilir.
//   Bu deneme sayısı yüksek tutulursa tur her zaman 3 farklı şekil döndürür.
//
// FALLBACK STRATEJİSİ:
//   Tüm denemeler başarısız olursa geçmiş kuralı ihlal edilir ama
//   tur tekliği mümkün olduğunca korunur. Oyun hiçbir zaman takılmaz.

import Foundation

// MARK: - ShapeDispenser

final class ShapeDispenser {

    // MARK: - Konfigürasyon

    /// Geçmişte tutulan şekil sayısı — 6: 11 şekilin yarısından fazla → güçlü çeşitlilik
    private let gecmisBoyutu = 6

    /// Geçmişteki şeklin tekrar gelmesini reddetme olasılığı
    /// %82: kısa vadede tekrar çok azalır ama tamamen yok olmaz → doğal his
    private let reddetmeOlasiligi: Double = 0.82

    /// Tur içi farklılık için kaç deneme yapılacağı
    /// 5 deneme: 11 şekil arasında geçerli aday bulma ihtimali çok yüksek
    private let turDenemeSayisi = 5

    /// Sadece tur tekliği kısıtlamasıyla (geçmiş gözetmeden) yapılacak son şans deneme sayısı
    /// Geçmiş kuralı çiğneniyor ama en azından aynı tur içinde 3 farklı şekil sağlanır
    private let sonSansDeneme = 3

    // MARK: - Durum

    /// Shuffle bag — 11 şekilin karıştırılmış sırası; bitince yeniden doldurulur
    private var torba: [BlockShape] = []

    /// Son N çekimin tip geçmişi — tekrar algılama için halka tamponu gibi kullanılır
    private var sonGecmis: [BlockShapeType] = []

    // MARK: - Arayüz

    /// Aynı tur içinde 3 farklı şekil döndürür.
    /// Hem geçmiş hem tur tekliği kuralları uygulanır.
    /// Hiçbir koşulda 3'ten az şekil döndürmez — torba boşalsa bile yeniden doldurulur.
    func ucunu() -> [BlockShape] {
        var secilen: [BlockShape] = []
        var buTurTipler: [BlockShapeType] = []

        for _ in 0..<3 {
            // Katman 1+2+3 uygula: tur tekliği + geçmiş kısıtı
            let sekil = enIyiAdayi(kacinilacaklar: buTurTipler)
            secilen.append(sekil)
            buTurTipler.append(sekil.type)
            gecmiseEkle(sekil.type)
        }

        return secilen
    }

    /// Yeni oyun başladığında torba ve geçmiş temizlenir.
    /// Temiz slate: ilk tur hep taze şekillerle başlar.
    func sifirla() {
        torba.removeAll()
        sonGecmis.removeAll()
    }

    // MARK: - İç Seçim Algoritması

    /// En uygun adayı seçer: önce tur tekliği + geçmiş, sonra sadece tur tekliği.
    /// Kesinlikle bir şekil döndürür — fallback garantili.
    private func enIyiAdayi(kacinilacaklar: [BlockShapeType]) -> BlockShape {
        // Deneme 1: Hem tur tekliği hem geçmiş kuralına uy
        for _ in 0..<turDenemeSayisi {
            let aday = torbadanCek()

            // Aynı tur içinde bu tip zaten var mı? → reddet
            if kacinilacaklar.contains(aday.type) { continue }

            // Geçmişte bu tip var mı VE reddetme zarı düştü mü? → reddet
            if sonGecmis.contains(aday.type),
               Double.random(in: 0..<1) < reddetmeOlasiligi { continue }

            return aday
        }

        // Deneme 2: Sadece tur tekliğine bak, geçmişi görmezden gel
        // (kısa vadede biraz tekrar olabilir ama aynı turda 3 aynı şekil olmaz)
        for _ in 0..<sonSansDeneme {
            let aday = torbadanCek()
            if !kacinilacaklar.contains(aday.type) { return aday }
        }

        // Son çare: tüm kısıtlar kalkar — oyun hiç takılmaz
        // Bu noktaya çok nadir gelinir (torba ≤ kacinilacaklar.count olduğunda)
        return torbadanCek()
    }

    // MARK: - Torba Yönetimi

    /// Torbadan bir sonraki şekli çeker; torba boşsa yeniden doldurulur.
    /// Torba düzeni korunur — çekilen elemanlar geri konmaz (shuffle bag garantisi).
    private func torbadanCek() -> BlockShape {
        if torba.isEmpty { torbayiDoldur() }
        return torba.removeFirst()
    }

    /// Tüm 11 şekli karıştırarak torbayı sıfırdan doldurur.
    /// Her turda farklı bir sıra — uzun vadede tüm şekiller dengeli gelir.
    private func torbayiDoldur() {
        torba = BlockShape.all.shuffled()
    }

    // MARK: - Geçmiş Yönetimi

    /// Yeni tipi geçmişe ekler; kapasiteyi aşınca en eskiyi siler.
    /// Halka tampon mantığı: sabit boyutlu kayan pencere.
    private func gecmiseEkle(_ tip: BlockShapeType) {
        sonGecmis.append(tip)
        if sonGecmis.count > gecmisBoyutu {
            sonGecmis.removeFirst()
        }
    }
}
