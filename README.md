# TRIBUN ARENA DIRECTOR — 0.3 ALFA

**Türkçe, çevrimdışı, PC futbol menajerliği türünü telefonun yatay ekranına taşıyan özgün bir Godot projesi.**

> Bu oyun Football Manager / FM27 markasıyla bağlantılı değildir. FM'in görselleri, arayüzleri, oyunu veya ticari futbolcu veritabanı kullanılmamıştır. PC seviyesi hedeflenen bir geliştirme projesidir; mevcut APK tam teşekküllü bir FM27 kopyası değildir.

## Kapsam — bu sürümde uygulanmış sistemler

- 12 kurgusal kulüp, 264+ kurgusal oyuncu, 22 maç haftası, çift devreli gerçek fikstür, puan durumu, haftalık rakip sonuçları ve yeni sezon.
- 11 kontrol ekranı: Merkez, Kadro, Taktik, Transfer, Scout, Antrenman, Finans, Altyapı, Personel, Lig ve Haberler; maç merkezinde ayrıca canlı olaylar.
- Oyuncular için pozisyon, yaş, 7 yetenek alanı, fiziksel kondisyon, moral, gizli potansiyel, kontrat süresi, haftalık maaş, piyasa değeri, sakatlık ve rol.
- İlk 11 seçimleri, otomatik 11, oyuncu rol değişimi, sözleşme yenileme, oyuncu satışı.
- Rakip kulüplere transfer teklifleri (%105 / %130), teklif reddi, bütçe kısıtı, maaş etkisi, scouting kararı, sonraki haftaya yetişen raporlar.
- Topa sahipken ve değilken ayrı dizilişler, mentalite, pres, tempo, genişlik ve antrenman ile bağlantılı taktik etkinliği.
- İlk yarı + devre arası taktik müdahalesi + ikinci yarı olarak yönetilen olaylı maç simülasyonu. Şut, beklenen gol (xG), skor, haber akışı, maç primi ve haftalık lig sonuçları.
- Antrenman odağı ve yoğunluğu, kondisyon/sakatlık etkisi, teknik ekibi geliştirme.
- Haftalık maaş, sponsor gelirleri, stadyum bakım maliyeti, transfer gider ve gelirleri, mali hareket dökümü.
- Altyapı tesisleri, kurgusal genç yetenek üretimi, çalışanların farklı birimlerde seviye atlaması.
- JSON ile yerel kalıcı kayıt; APK çevrimdışı çalışmak üzere tasarlanmıştır.
- Otomatik Godot testleri: futbolcu, fikstür, kaleci sakatlığı, sezon simülasyonu, transfer, scouting, lig, kayıt ve 11 ekran.

## Android

GitHub Actions üzerindeki **Android APK** iş akışı yeşile döndüğünde, program doğrudan şu sayfada APK yayınlar:

- https://github.com/bilalgunes4772-max/Tribun-arena/releases/tag/v0.3.0-alpha
- İndirilecek dosya: `TribunArena-debug.apk`

## Geliştirme hedefleri — mevcut değil

Bu versiyon **ilk gerçek menajerlik alfa sürümüdür.** Tam PC seviyesi futbol evreni, birden çok ülke/lig/piramit, gerçek veri lisansları, ileri düzey scout gizliliği, temsilci görüşmeleri, canlı 2D/3D maç görünümü, derin basın etkileşimleri, kulüp yönetimi ve çevrimiçi rekabet henüz tamamlanmadı. Menajerlik simülasyonundaki bazı parametreler basitleştirilmiş ve oyun dengesi gerçek cihaz testleriyle iyileştirilmelidir.

## Test

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/director_qa.gd
```

Godot 4.4.1 / Android arm64, Compatibility renderer.
