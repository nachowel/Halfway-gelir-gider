# Design Brief: UK Gelir Gider Takip Uygulamasi
**Tarih:** 2026-04-19
**Kaynaklar:** [Scope](C:/Users/nacho/Desktop/gider/.agent/SCOPE-gelir-gider-uk.md), [Implementation Plan](C:/Users/nacho/Desktop/gider/.agent/implementation_plan.md)
**Platform:** Android odakli mobil web app / PWA
**Tasarim Yonlendirmesi:** `skills/.agent/agents/designer.md`

## Tasarim Amaci
Bu uygulama, tek kullanicili bir isletme gelir-gider takip araci. Arayuzun birinci amaci "hizli veri girisi", ikinci amaci "haftalik finansal netlik", ucuncu amaci ise "yaklasan giderleri kacirmamayi" saglamak. Tasarim asla muhasebe paneli gibi soguk ve kalabalik hissettirmemeli; mobilde tek elde hizli kullanilan, rafine, net ve guven veren bir kontrol paneli gibi hissettirmeli.

## Urun Karakteri
- Sessiz ama premium
- Finansal ama korkutucu degil
- Profesyonel ama kucuk isletme sahibi icin pratik
- Minimal ama bos degil
- Hemen kullanilabilir, form agirligi dusuk

## Hedef Kullanici
- Uygulamayi sadece isletme sahibi kullanacak
- Android telefondan gun icinde birden cok kez veri girecek
- Teknik olarak yazilim mantigina yabanci degil ama karmasik ekran istemiyor
- En cok ihtiyac duydugu sey: "Bu hafta ne kazandim, ne harcadim, net ne kaldi?"

## Ana Tasarim Ilkeleri
- Bir ekranda tek ana is olsun
- Ana dashboard acildiginda 3 saniyede durum anlasilsin
- Gelir/gider ekleme akisi 1 dakikadan kisa hissettirsin
- Sayilar hiyerarsik olarak metinden daha baskin olsun
- Pozitif ve negatif finansal durum renk ile degil once tipografi ile ayristirilsin
- Renk sadece destekleyici olsun; kri̇tik anlam sadece renge birakilmasin
- Haftalik ozet ana odak; aylik rapor ikinci seviye derinlik

## Semantic Skeleton

### 1. Login / Sign Up
H1: Hesabina gir  
Subtitle: Gelir ve giderlerini tek yerden takip et  
Primary CTA: Giris yap  
Secondary CTA: Google ile devam et  
Tertiary CTA: Hesap olustur

### 2. Haftalik Ozet Dashboard
H1: Bu hafta  
Subtitle: Pazartesi - Pazar arasi finansal gorunum  
Primary Block: Toplam gelir / toplam gider / net kazanc  
Secondary Block: Cash gelir / card gelir  
Tertiary Block: Yaklasan odemeler  
Supporting Block: Son hareketler  
Primary CTA: Gelir ekle  
Secondary CTA: Gider ekle

### 3. Gelir Ekle
H1: Gelir ekle  
Fields: Tarih, kategori, tutar, odeme tipi, platform, aciklama, opsiyonel belge  
Primary CTA: Kaydet  
Secondary CTA: Taslak olarak sakla

### 4. Gider Ekle
H1: Gider ekle  
Fields: Tarih, kategori, tutar, odeme tipi, tedarikci/aciklama, opsiyonel belge  
Primary CTA: Kaydet  
Secondary CTA: Tekrarlayan gider olarak tanimla

### 5. Tekrarlayan Giderler
H1: Tekrarlayan giderler  
Subtitle: Yaklasan odemeleri unutma  
List: Kira, elektrik, gaz, internet, diger  
Primary CTA: Yeni tekrarlayan gider  
Inline Action: Odendi olarak isaretle

### 6. Aylik Rapor
H1: Aylik kar zarar  
Primary Block: Gelir / gider / net  
Secondary Block: Kategori bazli gider dagilimi  
Supporting Block: Haftalara gore karsilastirma

### 7. Islemler
H1: Tum kayitlar  
Controls: Ara, tarih filtrele, kategori filtrele, gelir/gider filtrele  
List: Islem satirlari  
Inline Actions: Duzenle, sil

## Ekran Listesi
- Login
- Sign up
- Haftalik ozet dashboard
- Hizli gelir ekleme
- Hizli gider ekleme
- Islem listesi
- Islem duzenleme
- Kategori yonetimi
- Tekrarlayan giderler listesi
- Tekrarlayan gider olusturma/duzenleme
- Aylik rapor
- Profil ve temel ayarlar

## Bilgi Mimarisi
Alt navigation 4 ana sekmeden olussun:

1. `Ozet`
2. `Islemler`
3. `Raporlar`
4. `Ayarlar`

Floating primary action:
`+` butonu ile hizli ekleme sheet'i acilsin

Quick actions:
- Gelir ekle
- Gider ekle
- Tekrarlayan gider ekle

## Gorsel Yon
Stil "finance dashboard" ile "artisan operational tool" arasinda olsun. Cok kurumsal banka arayuzu gibi degil; ama not uygulamasi kadar hafif de degil. Temiz kartlar, sakin ama zengin tonlar, yumusak kontrastlar, net spacing, premium mobil his.

### Renk Dili
- Ana zemin: kirli beyaz / yumusak tas tonu
- Kartlar: sicak beyaz ve acik gri katmanlar
- Birincil vurgu: derin petrol mavisi veya koyu yesil-mavi
- Pozitif veri vurgusu: dogal koyu yesil
- Negatif veri vurgusu: rafine toprak kirmizisi
- Warning/reminder: amber/turuncu ama bagirmayan ton

Kesinlikle kullanma:
- Saf mor temasi
- Neon finans uygulamasi estetiği
- Cok koyu ve agir dark mode ana yon olarak

## Tipografi
- Baslik fontu: karakterli ama okunakli bir serif veya humanist sans
- UI fontu: sade, yuksek okunurlu sans
- Sayisal veri: tabular numbers destekleyen font stili

Onerilen kombinasyon:
- Heading: `Fraunces` veya `DM Serif Display` hafif kullanim
- Body/UI: `Manrope` veya `Plus Jakarta Sans`

## Tasarim Token Seti
```css
:root {
  --color-bg: hsl(42 24% 96%);
  --color-surface: hsl(40 20% 99%);
  --color-surface-muted: hsl(36 18% 93%);
  --color-border: hsl(32 14% 84%);
  --color-text: hsl(180 18% 16%);
  --color-text-soft: hsl(180 10% 34%);

  --color-brand: hsl(191 46% 26%);
  --color-brand-strong: hsl(191 54% 20%);
  --color-income: hsl(150 38% 30%);
  --color-expense: hsl(11 48% 42%);
  --color-warning: hsl(34 72% 48%);
  --color-accent: hsl(197 32% 78%);

  --shadow-sm: 0 1px 2px hsla(191 30% 18% / 0.06);
  --shadow-md: 0 10px 30px hsla(191 30% 18% / 0.08);
  --shadow-lg: 0 18px 50px hsla(191 30% 18% / 0.12);

  --radius-sm: 10px;
  --radius-md: 18px;
  --radius-lg: 28px;
  --radius-xl: 36px;
  --radius-full: 999px;

  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 20px;
  --space-6: 24px;
  --space-8: 32px;
  --space-10: 40px;

  --duration-fast: 120ms;
  --duration-base: 220ms;
  --duration-slow: 420ms;
  --ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-expressive: cubic-bezier(0.22, 1, 0.36, 1);
}
```

## Ana Komponentler

### 1. Summary Card
- Icerik: etiket, buyuk deger, mini degisim/metin
- States: default, highlighted, warning
- Varyantlar: gelir, gider, net, platform
- Mobilde yatay swipe yerine dikey stack tercih et

### 2. Transaction Row
- Sol: kategori ikonu veya platform rozeti
- Orta: baslik + alt bilgi
- Sag: tutar + tarih
- Long press veya trailing action ile duzenle/sil

### 3. Floating Add Button
- Belirgin ama kaba degil
- Tap edince bottom sheet acsin
- Icinden `Gelir ekle`, `Gider ekle`, `Tekrarlayan gider`

### 4. Form Sheet / Form Page
- Buyuk inputlar
- Alt alta net form yapisi
- Sticky save button
- Kamera/dosya ekleme alani kucuk ama gorunur

### 5. Upcoming Payment Card
- Baslik
- Due tarihi
- Tutar
- Status chip: yaklasiyor / bugun / gecikti
- Action: odendi olarak isaretle

### 6. Filter Chips
- Tarih
- Tur
- Kategori
- Odeme tipi

## Komponent State Kurallari

### Button
- States: default, pressed, focus, disabled, loading, success
- Primary: koyu brand zemin, acik yazi
- Secondary: surface zemin, borderli
- Ghost: sade text + hafif tint

### Input
- Default: sakin border
- Focus: brand ring + hafif shadow
- Error: sadece kirmizi border degil, yardimci text ile desteklenmeli
- Filled: label kuculmus veya ustte sabit

### Card
- Default: yumusak zemin
- Active: hafif yukselme + shadow artisi
- Warning: border veya sol accent line ile vurgulanmali

## Motion Spec

### Dashboard Load
- Summary cardlar 60ms stagger ile yukaridan hafif rise-in yapsin
- Duration: 320ms
- Easing: `--ease-expressive`

### Bottom Sheet Open
- TranslateY 24px -> 0
- Opacity 0 -> 1
- Duration: 240ms
- Easing: `--ease-standard`

### Button Press
- Scale 1 -> 0.98
- Duration: 80ms
- Release: 140ms

### Save Success
- Button label fade
- Check ikon kisa sureli gorunsun
- Form kapanmadan once 300ms success geri bildirimi ver

### Card Expand / Filter Apply
- Ani layout jump olmasin
- Height ve opacity birlikte animasyonlu gecsin

## Responsive Davranis
- Mobile-first tasarla
- Ana hedef genislik: `360px - 430px`
- Tablet veya desktop'ta 560px max content width ile ortalanmis single-column ana deneyim olabilir
- Dashboard kartlari mobilden tasinmali; desktop'ta 2 kolon olabilir ama tasarim mobil mantigini bozmamali

## Erişilebilirlik Notlari
- Tum metinler WCAG AA kontrastini saglamali
- Kritik finansal bilgi yalnizca renkle verilmemeli
- Buton ve input touch target en az 44px olmali
- Focus state net ve gorunur olmali
- Sayisal alanlarda klavye turu uygun secilmeli
- Form validation hatalari alan bazli net yazilmali

## Stitch Icin Ana Prompt
Asagidaki metin Stitch veya benzeri tasarim aracina dogrudan verilebilir:

> Android odakli, tek kullanicili, premium ama sade bir gelir-gider takip uygulamasi tasarla. Bu uygulama kucuk bir isletme sahibi icin kullanilacak. Ana ekran haftalik ozet dashboard'u olmali; hafta Pazartesi baslar Pazar biter. Ekranda toplam gelir, toplam gider, net kazanc, cash gelir ve card gelir on planda gorunmeli. Ayrica yaklasan tekrarlayan odemeler ve son islemler de bulunmali. Stil banka uygulamasi gibi soguk degil; sakin, rafine, premium, mobil-first ve guven veren bir arayuz olmali. Renk paleti sicak acik zeminler, petrol mavisi/yesil vurgu, dogal yesil gelir tonlari ve rafine toprak kirmizisi gider tonlari kullanmali. Serif baslik + modern sans body kombinasyonu kullan. Buyuk sayilar, yumusak kartlar, belirgin bosluklar, rounded corners ve hafif motion kullan. Bottom navigation: Ozet, Islemler, Raporlar, Ayarlar. Floating action button ile Gelir ekle, Gider ekle, Tekrarlayan gider ekle sheet'i acilsin. Ayrica gelir ekleme, gider ekleme, islemler listesi, aylik kar-zarar, kategori yonetimi ve tekrarlayan giderler ekranlarini da ayni tasarim diliyle olustur.

## Stitch Icin Ekran Bazli Promptlar

### Prompt 1: Haftalik Ozet
> Mobile-first weekly finance dashboard for a small business owner in the UK. Show total income, total expenses, net profit, cash income, and card income. Include upcoming recurring payments and recent transactions. Warm light background, refined financial design, premium but minimal, large readable numbers, soft layered cards, bottom navigation, floating add button.

### Prompt 2: Gelir/Gider Formu
> Design a fast mobile transaction entry screen for income and expense tracking. Big touch-friendly fields, category picker, amount input, payment method, date, notes, optional receipt image upload, sticky save button. Make it feel frictionless and professional.

### Prompt 3: Tekrarlayan Giderler
> Design a recurring expenses mobile screen with list items for rent, utilities, internet and other bills. Each item shows amount, next due date, recurrence frequency, and a mark-as-paid action. Include an elegant create/edit flow.

### Prompt 4: Aylik Rapor
> Design a monthly profit and loss report screen for mobile. Show income, expenses, net profit, category breakdown, and weekly comparison. Use data visualization sparingly and clearly. Prioritize readability over dashboard complexity.

## Tasarimda Kacinilacaklar
- Generic fintech template gorunumu
- Mor agirlikli modern SaaS estetiği
- Karanlik, agir, kasvetli finans paneli
- Cok fazla chart ve veri gürültüsü
- Kucuk fontlu tablo benzeri muhasebe ekrani
- Formlarda gereksiz cok alan bir anda gosterme

## Handoff Beklentisi
Tasarimdan sonra su ciktilar hazir olmali:
- Ana ekran wireframe veya high-fidelity mock
- Gelir ekleme ve gider ekleme ekranlari
- Tekrarlayan gider listesi ve odendi akisi
- Aylik rapor ekrani
- Kullanilan renkler, yazi stilleri, spacing ve radius token listesi
- Button, input, card ve bottom nav state'leri

## Sonraki Adim
Bu dokuman Stitch'te ilk tasarim varyantlarini uretmek icin kullanilacak. Tasarim ciktiktan sonra implementation plan gerekirse ekran yapisina gore guncellenecek.
