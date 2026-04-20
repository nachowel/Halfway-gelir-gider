# Scope: UK Gelir Gider Takip Uygulamasi
**Tarih:** 2026-04-19
**Karar Verenler:** Kullanici, Codex

## Problem
Tek isyeri icin, sadece kullanicinin Android telefondan kullanacagi, private ama bulutta yedeklenen bir gelir-gider uygulamasi gerekiyor. Amaç gunluk ve haftalik gelirleri, tek seferlik ve tekrarlayan giderleri, duzeltilebilir kayitlarla takip edip haftalik ozet, aylik kar-zarar ve genel net kazanci net sekilde gorebilmek. Buna ek olarak, kira gibi buyuk ve uzun vadeli tekrarlayan giderler icin kullaniciya her hafta ne kadar para ayirmasi gerektigini gosteren bir `reserve planner` katmani da olmali. Su an bu is icin mevcut bir sistem yok; bu nedenle ilk surum kullanicinin gercek hayatta hemen kullanabilecegi kadar hizli ve basit olmali.

## Kapsam Ici
- Tek kullanicili hesap yapisi
- Tek isyeri / tek sube mantigi
- Android telefon odakli kullanim
- Bulut senkronizasyonu ve cihaz degisiminde veri kaybetmeme
- Internet yokken kayit alip sonra senkron olma
- Gelir kayitlari: cash, card, Uber, Just Eat ve sonradan eklenebilir dinamik gelir kategorileri
- Gider kayitlari: dinamik kategoriler, aciklama, odeme tipi, tarih, tutar
- Fotograf/fatura ekleme: opsiyonel
- Haftalik delivery settlement mantigi: Uber ve Just Eat gelirleri gunluk degil haftalik toplu kayit
- Tekrarlayan gider tanimi
- Tekrarlayan giderler icin due-date hatirlatmasi
- Tekrarlayan giderler odendi diye onaylaninca kesin gider kaydina donusmesi
- Reserve planner: tekrarlayan/buyuk giderler icin haftalik ayrilmasi onerilen tutarin hesaplanmasi
- Gecmise donuk kayit duzenleme ve silme
- Haftalik ozet ekrani: hafta Pazartesi baslar, Pazar biter
- Raporlar: haftalik ozet, aylik kar-zarar, kategori bazli gider dagilimi, yaklasan odemeler, reserve onerileri
- Net kazanc hesaplama
- Stok tarafinda ilk surumde sadece stok alimi giderlerinin haftalar arasi karsilastirilmasi
- Giris: e-posta/sifre ve Google ile giris
- Para birimi: GBP

## Kapsam Disi
- Cok kullanicili rol sistemi
- Birden fazla sube veya isletme yonetimi
- Tam stok sayimi ve eldeki mevcut urun adedi takibi
- Urun bazli tuketim analizi (ornegin kac bacon kullanildi) ilk surumde kesin degil
- Fis/fatura OCR ve otomatik kategori dagitimi ilk surumde zorunlu degil
- Delivery platform komisyon, reklam ve kesinti kalemlerinin tam muhasebe modeli
- VAT/KDV ayrimi
- Banka entegrasyonu
- Personel vardiya/planning modulu
- Muhasebeci veya vergi beyani icin resmi finans modulu
- Iceride ikinci bir PIN/biyometri kilidi

## Basari Kriterleri
1. Kullanici telefondan 1 dakika icinde gelir veya gider kaydi olusturabilmeli.
2. Haftalik toplam gelir, toplam gider, cash gelir, card gelir ve net kazanc tek ekranda gorulebilmeli.
3. Aylik kar-zarar ozetinden paranin nereye gittigi kategori bazinda anlasilmali.
4. Tekrarlayan giderler unutulmamali; uygulama due-date gelmeden hatirlatmali.
5. Yanlis kayitlar sonradan duzeltilebilir olmali; veri kilitli kalmamali.
6. Cihaz degisince veri kaybolmamali ve kullanici hesabina tekrar girince kayitlar geri gelmeli.
7. Buyuk/tekrarlayan giderler icin sistem kullaniciya bu hafta ne kadar reserve ayirmasi gerektigini gosterebilmeli.

## Dogrulanmamis Varsayimlar
- Offline senkronizasyon kullanicinin bekledigi kadar sorunsuz olacak.
  - Dogrulama: ilk MVP'de ucak modunda kayit + tekrar online senkron testi
- Haftalik delivery settlement kaydi, operasyonel ihtiyac icin yeterli detay saglayacak.
  - Dogrulama: 2-3 haftalik gercek veri ile kullanip rapor okunabilirligini test et
- Dinamik kategori sistemi kullaniciyi yormadan sade kalacak.
  - Dogrulama: ilk kurulumda varsayilan kategori seti + sonradan ekleme deneyimini test et
- Fotograf/fatura opsiyonel olsa bile veri girisi yeterince duzenli olacak.
  - Dogrulama: manuel kayit davranisini 1-2 hafta gozlemle
- Stok alimi giderlerini haftalik karsilastirmak, ilk asamada stok modulu ihtiyacini geciktirecek.
  - Dogrulama: gider raporlarinin karar vermek icin yeterli olup olmadigini kontrol et
- Reserve planner formulu kullanicinin karar vermesi icin yeterince faydali olacak.
  - Dogrulama: kira ve aylik giderler uzerinden 2-3 haftalik kullanimla reserve onerilerinin anlamli bulunup bulunmadigini test et

## Alternatifler
| Yaklasim | Artilar | Eksiler | Risk | Caba |
|----------|---------|---------|------|------|
| A. Flutter Android-first uygulama + bulut senkron | Native'e yakin mobil deneyim, offline davranis daha guclu, Android kamera/dosya entegrasyonu daha dogal | Web tabanli kadar hizli degil, mobil app yapisi ve paket secimi daha disiplin ister | Dusuk-Orta | 2-3 hafta |
| B. Tam native Android uygulama | Daha iyi mobil deneyim ve cihaz entegrasyonu | Gelistirme ve iterasyon daha yavas, tasarim ve deploy daha agir | Orta | 4-8 hafta |
| C. Spreadsheet/Notion tabanli gecici sistem | En hizli baslangic | Mobil veri girisi kotu, tekrarlayan gider ve raporlama zayif | Orta | 1-3 gun |
| D. Hic yapmama / manuel takip | Sifir teknik maliyet | Dağinik veri, rapor yok, hata riski yuksek | Yuksek | 0 gun |

## Secilen Yaklasim
Yaklasim A secildi: tek kullanicili, Android odakli, Flutter tabanli bir mobil uygulama. Bu secim kullanicinin uygulamayi esas olarak telefondan kullanacak olmasina, offline kayit ve sonradan senkron ihtiyacina, kamera/dosya ekleme akisinin mobilde daha dogal olmasina ve 2-3 haftalik makul MVP hedefine en uygun yol. Ilk surumde asil deger gelir-gider kayitlarinin hizli girilmesi, haftalik ozetin guclu olmasi ve tekrarlayan giderlerin kacirilmamasi. Tam OCR ve detayli stok sistemi sonraya birakilacak.

## Ilk Slice (MVP)
- Hesap olusturma ve giris
- Tek kullanicili veri modeli
- Gelir ekleme / duzenleme / silme
- Gider ekleme / duzenleme / silme
- Dinamik kategori yonetimi
- Haftalik ozet ana ekran
- Aylik kar-zarar ozeti
- Tekrarlayan gider tanimi + hatirlatma + odendi olarak kesinlestirme
- Reserve planner: tekrarlayan buyuk giderler icin haftalik ayrilmasi onerilen tutar
- Delivery settlement icin haftalik Uber / Just Eat girisi
- Opsiyonel fotograf ekleme
- Bulut yedegi ve temel offline kayit/senkron akisi

## Sonraya Birakilanlar
- Fis/fatura OCR
- Otomatik kategori tahmini
- Detayli stok sayimi
- Urun bazli tuketim analizi
- Banka baglantilari
- Delivery platform detayli komisyon ayristirma

## Sonraki Adim
Bu scope'tan hareketle Flutter uygulama iskeleti, veri modeli, ekran listesi ve MVP backlog'u uygulanacak.
