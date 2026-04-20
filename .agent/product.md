# Product Reference: Gider
**Tarih:** 2026-04-20
**Durum:** Referans urun dokumani
**Ilgili Dokumanlar:** [Scope](C:/Users/nacho/Desktop/gider/.agent/SCOPE-gelir-gider-uk.md), [Design Brief](C:/Users/nacho/Desktop/gider/.agent/design.md), [Implementation Plan](C:/Users/nacho/Desktop/gider/.agent/implementation_plan.md), [Hi-Fi Export](C:/Users/nacho/Desktop/gider/.agent/design-reference/gider-hi-fi.html), [Wireframe Export](C:/Users/nacho/Desktop/gider/.agent/design-reference/gider-wireframes-standalone.html)

## Urun Ozeti
`Gider`, UK'de tek bir isletme icin kullanilacak, tek kullanicili, Android odakli bir Flutter gelir-gider takip uygulamasidir. Uygulamanin ana amaci, gunluk gelirleri ve farkli periyotlarda olusan giderleri hizli sekilde kaydetmek, haftalik finansal gorunumu net gostermek, aylik kar-zarar takibi yapmak ve tekrarlayan odemelerin kacirilmasini onlemektir. Buna ek olarak urun, buyuk ve periyodik giderler icin kullaniciya her hafta ne kadar para ayirmasi gerektigini gosteren bir `reserve planner` mantigi da sunacaktir.

Bu urun bir muhasebe sistemi, ERP ya da cok kullanicili SaaS paneli degildir. Ilk surumde hedef, gercek dunyada hemen kullanilabilecek kadar hizli, sade ve guvenilir bir operasyon aracidir.

## Problem
Kullanici su anda isletme gelir ve giderlerini takip etmek icin oturmus bir sisteme sahip degil. Bu da su sorunlari dogurur:

- Haftalik ne kadar kazanildigi net gorulemez
- Giderlerin nereye gittigi parca parca kaybolur
- Tekrarlayan odemeler unutulabilir
- Kira gibi buyuk giderler son haftaya kalirsa odeme baskisi yaratir
- Ay sonu kar-zarar geriye donuk toparlanmak zorunda kalir
- Yanlis veya eksik kayitlar tum tabloyu bozar

Urun, bu daginikligi mobilde hizli veri girisi ve sade ozet ekranlari ile cozmelidir.

## Hedef Kullanici
- Tek kullanici
- Tek isyeri / tek sube
- Uygulamayi esas olarak Android telefondan kullanacak
- Verilerini kimseyle paylasmayacak
- Teknik olarak tamamen yabanci degil ama karmasik sistem istemiyor
- En onemli ihtiyaci: `Bu hafta ne kazandim, ne harcadim, ne kaldi?`

## Temel Urun Hedefleri
- Gelir ve gider girisini telefondan hizli yapmak
- Haftalik ozet ekraninda finansal durumu hemen anlamak
- Aylik kar-zarar ve kategori dagilimini gormek
- Tekrarlayan giderleri unutmayi onlemek
- Buyuk tekrarlayan giderler icin haftalik reserve ihtiyacini onceden gormek
- Veriyi bulutta saklayip cihaz degistirince kaybetmemek
- Internet olmadiginda da kayit alip sonra senkron etmek

## Basari Kriterleri
- Kullanici 1 dakika icinde gelir veya gider kaydi girebilmeli
- Haftalik ozet ekraninda toplam gelir, toplam gider, cash gelir, card gelir ve net kazanc gorulebilmeli
- Aylik raporda paranin hangi kategorilere gittigi net okunabilmeli
- Tekrarlayan giderler hatirlatilmali ve odendi olarak kesinlestirilebilmeli
- Reserve planner kullaniciya bu hafta ne kadar para ayirmasi gerektigini gosterebilmeli
- Yanlis kayitlar sonradan duzenlenebilmeli veya silinebilmeli
- Yeni cihazda tekrar giris yapildiginda tum veriler geri gelmeli

## MVP Kapsami

### Dahil
- Tek kullanicili hesap sistemi
- E-posta/sifre ve Google ile giris
- Android odakli Flutter uygulamasi
- Bulut yedegi
- Offline kayit + sonra senkron
- Gelir kayitlari
- Gider kayitlari
- Dinamik kategori yonetimi
- Opsiyonel fis/fatura fotografi ekleme
- Haftalik Uber / Just Eat settlement kaydi
- Tekrarlayan gider tanimi
- Due-date hatirlatma
- Odendi olarak isaretleyince gercek gider kaydi olusturma
- Reserve planner / haftalik ayirma onerisi
- Haftalik ozet ekranı
- Aylik kar-zarar raporu
- Kategori bazli gider dagilimi
- Gecmis kayitlari duzenleme ve silme

### Dahil Degil
- Cok kullanicili roller
- Birden fazla sube
- Tam stok sayimi
- Urun bazli tuketim analizi
- OCR ile fis/fatura otomatik okuma
- Banka entegrasyonu
- Delivery platform detayli komisyon muhasebesi
- VAT/KDV ayrimi
- Ic uygulama PIN/biyometri kilidi

## Veri ve Is Kurallari

### Gelirler
- Cash ve card gelirleri gunluk girilebilir
- Uber ve Just Eat gelirleri gunluk degil, haftalik settlement mantigiyla girilecek
- Gelir kategorileri dinamik olacak

### Giderler
- Gider kategorileri dinamik olacak
- Tutarlar toplam tutar olarak girilecek
- Fotograf/fatura ekleme opsiyonel olacak
- Her kayit sonradan duzenlenebilir veya silinebilir olacak

### Tekrarlayan Giderler
- Haftalik, aylik, 3 aylik ve yillik gibi periyotlar desteklenecek
- Vade zamani yaklasinca hatirlatma gosterilecek
- Gider otomatik kesin kayit olarak dusmeyecek
- Kullanici `odendi` dediginde islem kesinlesecek

### Reserve Planner
- Buyuk ve tekrarlayan giderler icin ayri bir planning katmani olacak
- Bu alan `net kazanc`in yerine gecmeyecek; ayri bir analiz bolumu olacak
- Sistem, her gider icin `odemeye kalan sureye gore haftalik ne kadar reserve ayrilmasi gerektigini` hesaplayacak
- Ilk surumde sistem sadece `onerilen reserve` gosterecek
- Ilk surumde kullanicinin gercekten ne kadar reserve ettigini takip etmek zorunlu olmayacak

### Stok Mantigi
- Ilk surumde tam stok modulu olmayacak
- Sadece stok alimi giderleri kaydedilecek
- Haftalar arasi stok harcama karsilastirmasi yapilabilecek

## Platform ve Teknik Yakinlik
- Platform: Android odakli Flutter mobil uygulamasi
- Hedef cihaz: Android
- Ulke: UK
- Para birimi: GBP
- Veri: Bulutta saklanacak
- Offline senaryo: Lokal kayit, sonra senkron

## Secilen Tasarim Yonu
Urunun resmi tasarim referansi:
- [Design Brief](C:/Users/nacho/Desktop/gider/.agent/design.md)
- [Hi-Fi Export](C:/Users/nacho/Desktop/gider/.agent/design-reference/gider-hi-fi.html)
- [Wireframe Export](C:/Users/nacho/Desktop/gider/.agent/design-reference/gider-wireframes-standalone.html)

Tasarim prensipleri:
- Tek kolon mobil yerlesim
- Haftalik ozet ana ekran
- Kart tabanli bilgi hiyerarsisi
- Bottom navigation
- Floating action button
- El yazisi tipografi yok
- Referans tasarimdaki mint/cream/teal/yellow yonu korunacak
- Tasarim yeniden icat edilmeyecek; referansa sadik kodlanacak

## Ana Ekranlar
- Login / Sign up
- Haftalik ozet dashboard
- Gelir ekleme
- Gider ekleme
- Islemler listesi
- Islem duzenleme
- Aylik rapor
- Tekrarlayan giderler
- Kategori yonetimi
- Ayarlar

## En Onemli Urun Deneyimi
Kullanici uygulamayi actiginda once `Bu hafta` ekranini gorecek. Bu ekran urunun kalbidir. Kullanici burada:

- toplam gelir
- toplam gider
- cash gelir
- card gelir
- net kazanc
- reserve planner ozeti
- yaklasan odemeler
- son islemler

bilgilerini hizli sekilde anlamalidir.

Bu ekran yeterince guclu degilse urunun temel degeri zayiflar.

## Urun Kisitlari
- Ilk surum cok buyumemeli
- OCR gibi zor AI ozellikleri sonraya kalmali
- Tasarim referansina sadakat korunmali
- Kod temiz, surdurulebilir ve AI ile genisletilebilir olmali

## Karar Ozeti
- Bu urun bir `personal business finance tracker`
- Ilk hedef `gelir-gider ve net kazanc`
- Reserve planner ile buyuk odemeler icin onceden para ayirma mantigi urune dahil edildi
- Stok, OCR ve daha agir muhasebe ozellikleri ikinci faz
- Tasarim artik secildi ve referans dosya proje icinde mevcut
- Implementation plan design-first ve Flutter-first hale getirildi

## Sonraki Adim
- Referans tasarima gore uygulama gorevlerini uygulamaya baslamak
- Gerekirse bu dokumani Task Master veya prompt girisi icin temel referans olarak kullanmak
