# Domain Freeze: UK Gelir Gider Takip Uygulamasi
**Tarih:** 2026-04-20
**Durum:** Domain davranis kontrati kilit dokuman
**Kapsam:** MVP davranis kurallari
**Bagli Dokumanlar:** [Product](C:/Users/nacho/Desktop/gider/.agent/product.md), [Scope](C:/Users/nacho/Desktop/gider/.agent/SCOPE-gelir-gider-uk.md), [Design](C:/Users/nacho/Desktop/gider/.agent/design.md), [UI Handoff](C:/Users/nacho/Desktop/gider/.agent/ui-handoff.md), [Implementation Plan](C:/Users/nacho/Desktop/gider/.agent/implementation_plan.md)

## 1. Amac
Bu dokumanin amaci, UI ve kod implementasyonu baslamadan once finansal davranis kurallarini netlestirmektir.

Bu dokuman su konulari kilitler:
- gelir ve giderler nasil hesaplanir
- recurring gider ne zaman gercek gider sayilir
- hafta ve tarih sinirlari nasil hesaplanir
- dashboard hangi veri kaynaklariyla dolar
- category ve payment method neyi etkiler
- reserve planner hangi formul ile calisir
- transaction kayitlari nasil duzenlenir veya silinir

Bu dokuman yazildiktan sonra domain kurallari runtime sirasinda sessizce degistirilmez. Yeni ihtiyac cikarsa once bu dosya guncellenir, sonra kod degisir.

## 2. Temel Domain Ilkeleri
1. Uygulama tek kullanicili ve tek isletmelidir.
2. Uygulama bir ERP veya resmi muhasebe sistemi degildir; operasyonel finans takip aracidir.
3. Finansal dogruluk, ekran esteginden once gelir.
4. Urunun birincil degeri `Bu hafta ne oldu?` sorusuna hizli cevap vermektir.
5. Gerceklesen para hareketleri ile reminder/planning katmani birbirine karistirilmaz.
6. Reserve planner gercek para hareketi degil, planlama gorunumudur.
7. MVP'de kullanici hatali veriyi duzeltebilmeli veya silebilmelidir.

## 3. Net Profit Formulu

### 3.1 Ana Formul
**Net profit = toplam gerceklesmis gelir - toplam gerceklesmis gider**

Bu hesap sadece secilen tarih araligindaki `kesinlesmis` kayitlari kullanir.

### 3.2 Dahil Edilen Gelirler
- cash income
- card income
- Uber settlement income
- Just Eat settlement income
- diger manuel income kayitlari

### 3.3 Dahil Edilen Giderler
- manuel expense kayitlari
- recurring expense uzerinden `paid` ile kesinlestirilmis gider transaction'lari
- stok alim giderleri
- diger manuel expense kategorileri

### 3.4 Dahil Edilmeyenler
- sadece reminder durumundaki recurring giderler
- reserve planner onerileri
- taslak niteligindeki gecici girisler varsa bunlar
- attachment metadata
- silinmis transaction'lar

### 3.5 Net Profit Notu
Reserve planner dashboard'da gorunebilir, ama net profit hesabini degistirmez. Reserve planner ikinci katman analizdir; net profit'in alternatifi degildir.

## 4. Transaction Domain Modeli

### 4.1 Tek Ortak Transaction Mantigi
MVP'de gelir ve giderler ortak transaction modeli ile tutulur.

Her transaction en az su alanlara sahip olmalidir:
- `id`
- `user_id`
- `type` -> `income` | `expense`
- `occurred_on`
- `amount_minor`
- `currency` -> varsayilan `GBP`
- `category_id`
- `payment_method`
- `source_platform` (opsiyonel)
- `note` (opsiyonel)
- `vendor` (opsiyonel, agirlikla expense icin)
- `attachment_path` (opsiyonel)
- `created_at`
- `updated_at`
- `deleted_at` (soft delete tercih edilirse)

### 4.1.1 `occurred_on` Veri Tipi ve Semantigi
`occurred_on`, MVP'de `local business date` mantigiyla ele alinir.

Yani:
- is anlami olarak bir `date` alanidir
- timestamp gibi davranmaz
- business timezone `Europe/London` kabul edilerek yorumlanir
- haftalik ve aylik raporlar `occurred_on` uzerinden calisir
- `created_at` ve `updated_at` audit icindir; finansal sinir hesaplarinda source of truth degildir

Bu karar bilincli olarak secilmistir:
- UI ve rapor mantigini basitlestirir
- UTC kaymasi yuzunden kayitlarin yanlis haftaya dusmesini engeller
- kullanicinin "bu gider hangi gune ait" dusunme bicimiyle uyumludur

### 4.1.2 `user_id` Kurali
Urun tek kullanicili ve tek isletmeli olsa da `user_id` alani MVP'de korunur.

Nedeni:
- uygulama bulut tabanli auth kullanacaktir
- veri sahipligi ve satir izolasyonu gerekir
- cihaz degisimi sonrasi ayni hesaba bagli verilerin geri gelmesi gerekir

Bu alanin anlami:
- cok kullanicili rol sistemi degil
- sadece verinin hangi auth hesaba ait oldugunu belirtmek

Yani:
- urun davranisi tek kullanicili kalir
- veri modeli auth sahipligini acik tutar

### 4.2 Amount Kurali
- Tum tutarlar veritabani seviyesinde minor unit ile tutulur.
- GBP icin bu `pence` mantigidir.
- UI'da kullaniciya decimal formatta gosterilir.
- Hesap motoru float ile calismaz.

### 4.2.1 Currency Kurali
MVP `single-currency` sistemdir.

Kesin karar:
- sistem para birimi `GBP`'dir
- multi-currency desteklenmez
- conversion mantigi yoktur
- kullanici transaction bazli farkli currency secmez

`currency` alani veri modelinde kalsa bile:
- sabit deger `GBP` olur
- kullanici tarafindan duzenlenmez
- urunde bir ozellik sinyali olarak sunulmaz

Bu alan ancak veri acikligi ve ileride genisleme ihtimali icin tutulur; MVP davranisinda degisken bir alan degildir.

### 4.3 Type Kurali
- `income` ve `expense` ayni tabloda olsa da davranissal olarak ayridir.
- `type` sonradan degistirilemez.
- UI'da edit ekraninda `type` alanı gosterilmez.
- Income kaydi sadece income editor ile, expense kaydi sadece expense editor ile duzenlenir.

## 5. Recurring Expense Lifecycle

### 5.1 Temel Prensip
Recurring expense, vadesi gelince otomatik olarak gercek gider yaratmaz. Sadece reminder ve planning nesnesidir.

Secilen urun karari:
- sistem once hatirlatir
- kullanici `odendi` dediginde gider kesinlesir

### 5.1.1 Frequency Kurali
Recurring expense kayitlari MVP'de serbest/custom tekrar mantigi ile degil, kontrollu frequency enum'u ile calisir.

Desteklenen degerler:
- `weekly`
- `monthly`
- `quarterly`
- `yearly`

Not:
- `quarterly` = 3 ayda bir
- custom interval MVP disindadir

`next_due_on` hesaplari bu frequency alanina gore yapilir.

### 5.2 Lifecycle
Recurring expense lifecycle su durumlari tasir:
1. `active`
2. `due_soon`
3. `due_today`
4. `overdue`
5. `paid` eventi

Not:
`paid` kalici bir durum olarak recurring kaydin ustunde tutulmak zorunda degildir; bu bir aksiyondur. Aksiyon sonrasi recurring kayit aktif kalir ve `next_due_on` ileri tasinir.

### 5.3 Paid Islemi Sirasinda Ne Olur
Kullanici recurring expense icin `paid` dediginde:
1. tek seferlik gercek bir `expense transaction` olusur
2. varsayilan tutar recurring kayittan gelir
3. kullanici odeme sirasinda gercek odeme tutarini override edebilir
4. `occurred_on` tarihi kullanicinin sectigi odeme tarihi olur
5. ilgili category uygulanir
6. payment method secilir veya varsa default kullanilir
7. recurring kaydin `next_due_on` alani bir sonraki periyoda kaydirilir
8. recurring kayit aktif kalmaya devam eder

### 5.3.1 Paid Override ve Audit Tradeoff'u
Recurring template uzerindeki planlanan tutar ile kullanicinin odeme aninda girdigi gercek tutar farkli olabilir.

MVP karari:
- gercek expense transaction `actual paid amount` ile olusur
- recurring kayit uzerindeki mevcut tutar bir sonraki donem icin varsayilan planlanan tutar olarak kalir
- MVP'de `scheduled_amount vs actual_paid_amount` farki icin ayri bir audit ledger tutulmaz

Bu bilincli bir tradeoff'tur:
- veri modelini sade tutar
- gercek odemeyi dogru transaction olarak kaydeder
- ama ilk surumde planlanan/gerceklesen sapma analizi uretilmez

Ileride gerekirse bu fark ayri bir audit alanina veya event tablosuna tasinabilir.

### 5.4 Recurring Kayit Gercek Gider Degildir
Recurring nesnenin kendisi:
- raporda gider olarak sayilmaz
- aylik profit/loss hesabina girmez
- sadece reminder/planning katmanidir

### 5.5 Overdue Davranisi
Due tarihi gecmisse ama paid edilmemisse:
- gider otomatik olusmaz
- net profit'e girmez
- upcoming listede `overdue` olarak gorunur
- kullanici daha sonra paid edip transaction yaratabilir

### 5.6 Recurring Expense Mutability ve Silme Kurallari
Recurring expense kayitlari icin MVP state modeli tek alan ile sade tutulur:
- `is_active`

Davranis:
- `is_active = true` ise reminder/planner akisi devam eder
- `is_active = false` ise kayit yeni reminder akisina girmez
- gecmiste bu recurring kayittan uretilmis transaction'lar korunur

Silme kurali:
- MVP varsayilani hard delete degildir
- kullanici recurring kaydi artik kullanmiyorsa once `is_active = false` yapilmasi beklenir
- eger teknik olarak silme akisi gerekiyorsa, bu sadece gelecekteki reminder nesnesini etkiler
- gecmiste olusan gercek expense transaction'lar asla bu islem yuzunden silinmez veya bozulmaz

## 6. Week Boundary ve Timezone Kurallari

### 6.1 Hafta Siniri
Bu uygulamada hafta:
- Pazartesi baslar
- Pazar biter

Bu kural weekly summary icin source of truth'tur.

### 6.2 Timezone
MVP'de temel business timezone:
- `Europe/London`

Tum haftalik ve aylik sinirlar bu timezone'a gore hesaplanir.

### 6.3 Tarih Alanlari
- `occurred_on` is mantiginda kullanilan ana tarihtir
- dashboard ve raporlar bu tarihe gore hesaplanir
- `created_at` sadece audit ve yardimci siralama alanidir
- finansal rapor `created_at` uzerinden yapilmaz

### 6.4 Gun Sonu Kurali
Gun sinirlari local business timezone'a gore kapanir. UTC kaynakli kaymalar yuzunden bir kaydin yanlis haftaya dusmesine izin verilmez.

### 6.5 Date Difference Kurali
Date farki hesaplari timestamp uzerinden degil, `local business date` uzerinden yapilir.

Yani:
- `today`, `Europe/London` timezone'undaki bugunun tarihidir
- saat/dakika bileşeni reserve planner ve weekly boundary hesaplarina dahil edilmez
- date diff sadece gun bazli hesaplanir

Bu kural ozellikle `remaining_weeks` ve due-state hesaplarinda zorunludur.

## 7. Dashboard Query Contracts
Dashboard urunun kalbidir. Bu ekran acildiginda kullanici haftalik durumu hizla anlamalidir.

### 7.1 Varsayilan Tarih Araligi
- current week
- Monday 00:00 -> Sunday 23:59:59
- Europe/London timezone

### 7.2 Primary Summary Cards

#### Toplam Gelir
- `type = income`
- secilen hafta araliginda
- silinmemis kayitlar

#### Toplam Gider
- `type = expense`
- secilen hafta araliginda
- silinmemis kayitlar

#### Net Kazanc
- `toplam gelir - toplam gider`

### 7.3 Secondary Summary

#### Cash Gelir
- `type = income`
- `payment_method = cash`
- secilen hafta araligi

#### Card Gelir
- `type = income`
- `payment_method = card`
- secilen hafta araligi

Not:
Bu KPI'lar income tarafi icindir. Expense payment method dagilimi MVP'de ana dashboard KPI'si degildir.

### 7.4 Upcoming Payments
Upcoming bolumu su kaynaktan dolar:
- `recurring_expenses`
- `active = true`
- due reminder penceresine girmis kayitlar
- siralama: once `overdue`, sonra `due_today`, sonra en yakin `due_soon`

Onerilen dashboard limiti:
- en fazla 3 veya 5 kalem

### 7.5 Recent Transactions
Recent bolumu su kaynaktan dolar:
- `transactions`
- silinmemis kayitlar
- `occurred_on desc`, sonra `created_at desc`
- en son 5 kayit

### 7.6 Reserve Planner Summary
Reserve planner summary su kaynaktan gelir:
- reserve planner engine sonucu
- sadece `reserve_enabled = true` recurring kayitlar
- gercek para hareketi degil
- dashboard'da ozet karti olarak gorunur
- ozet kartinda toplam haftalik reserve onerisi ve en fazla 2-3 ana reserve kalemi gosterilebilir

## 8. Category Kurallari

### 8.1 Genel Kural
Category sistemi dinamiktir. Kullanici yeni category ekleyebilir, mevcut category'leri archive edebilir.

### 8.2 Category Type
Her category kesin olarak bir tipe baglidir:
- `income`
- `expense`

Bir category ayni anda iki tipe ait olamaz.

### 8.3 Varsayilan Seed Category Seti
MVP baslangicinda varsayilan kategori seti gelir.

#### Income Seed List
- Cash Sales
- Card Sales
- Uber Settlement
- Just Eat Settlement
- Other Income

#### Expense Seed List
- Rent
- Utilities
- Internet
- Stock Purchase
- Supplies
- Maintenance
- Delivery/Transport
- Other Expense

### 8.4 Archive Kurali
Category silinmek yerine archive edilir.
Archive edilen category:
- yeni kayitlarda secilemez
- eski kayitlarla baglantisi korunur

### 8.5 Rename Kurali
Kategori adi sonradan degistirilebilir. Transaction'lar category id bazli bagli kaldigi icin veri kopmamali.

### 8.6 Rename Sonrasi Display Davranisi
MVP karari:
- transaction'lar category'ye `category_id` ile bagli kalir
- ayri bir `transaction-time category name snapshot` tutulmaz
- bu nedenle bir category yeniden adlandirilirsa, eski transaction'lar da category'nin guncel adini gosterir

Bu bilincli tradeoff'tur:
- veri modelini sade tutar
- kategori yonetimini kolaylastirir
- ama tam tarihsel gorunumde "o gun hangi isim vardi" bilgisini saklamaz

Ileride gerekirse kategori snapshot mantigi ayri alan veya event log ile eklenebilir.

## 9. Payment Method ve Source Platform Kurallari

### 9.1 Payment Method
MVP icin payment method enum kontrollu olmalidir.

Onerilen degerler:
- `cash`
- `card`
- `bank_transfer`
- `other`

Kurallar:
- `income` transaction'lar icin `payment_method` zorunludur
- `expense` transaction'lar icin de MVP'de `payment_method` zorunludur
- kullanici bilmiyorsa `other` ile kayit tamamlayabilir

Bu karar bilincli secilmistir:
- analytics ve filtreleme tarafini sade tutar
- bos/null payment method kaynakli rapor karmasasini azaltir

### 9.2 Source Platform
Bu alan ozellikle income tarafinda kaynagi belirtir.

Onerilen degerler:
- `direct`
- `uber`
- `just_eat`
- `other`

### 9.3 Analytics Etkisi
Payment method su alanlari etkiler:
- cash gelir
- card gelir
- payment breakdown raporlari
- filtreleme

Ama payment method:
- transaction `type` degistirmez
- category yerine gecmez

### 9.4 Uber / Just Eat Mantigi
Uber ve Just Eat gelirleri MVP'de:
- gunluk siparis bazli degil
- haftalik settlement mantigiyla girilir

Bu nedenle:
- her settlement bir income transaction'dir
- `occurred_on`, paranin fiilen settlement olarak gerceklestigi tarihi temsil eder
- `source_platform` ilgili delivery platform olur
- `payment_method` cogunlukla `bank_transfer` olur, ama teknik olarak ayri alan olarak kalir
- dashboard'da normal income toplamina dahildir

Kritik olan UI sunumu degil; settlement'in bagimsiz transaction olarak tutulmasidir.

### 9.4.1 Settlement `occurred_on` Kurali
Uber / Just Eat settlement icin `occurred_on` kesin olarak su anlama gelir:
- settlement odemesinin gerceklestigi business date

Bu alan sunlari temsil etmez:
- siparislerin dagildigi operasyonel gunler
- settlement donem baslangici
- settlement donem sonu etiketi

Yani MVP'de:
- kullanici haftalik settlement geldigi gun ya da odemenin finansal olarak ait oldugu odeme tarihini girer
- dashboard ve raporlar bu geliri o `occurred_on` tarihinin dustugu hafta/ay icinde sayar

Bu bilincli karardir:
- nakit akis mantigini sade tutar
- delivery platformlarin karmasik komisyon ve donem dagitimlarini MVP disina iter

## 10. Reserve Planner Formulu

### 10.1 Amac
Reserve planner, buyuk veya periyodik giderler icin:
`Bu hafta ne kadar ayirman gerekir?`
sorusuna cevap verir.

Bu bir muhasebe kaydi degil, planlama katmanidir.

### 10.2 Dahil Etme Kriteri
Sadece:
- recurring expense olan
- `reserve_enabled = true` olarak isaretlenen
kalemler reserve planner'a dahildir.

### 10.3 Temel Formul
MVP icin reserve onerisi:

**weekly_reserve_recommendation = amount_minor / remaining_weeks**

### 10.4 Remaining Weeks Kurali
- `days_until_due = next_due_on - today`
- `remaining_weeks = max(1, ceil(days_until_due / 7))`

Bu sayede:
- sifira bolme olmaz
- due tarihi cok yakin olsa bile en az 1 hafta kabul edilir
- overdue durumunda bile hesap bozulmaz

Buradaki `today` degeri:
- `Europe/London` local business date'tir
- time component ignore edilir

### 10.5 Overdue Reserve Davranisi
Overdue recurring giderler reserve planner'da:
- warning ile gosterilebilir
- onerilen reserve yuksek olabilir
- ama yine de gercek gider sayilmaz

### 10.6 MVP Basitlik Karari
MVP'de sistem:
- kullanicinin gercekte ne kadar reserve ettigini takip etmez
- sadece onerilen haftalik ayirma tutarini gosterir
- ayri reserve wallet/ledger tutmaz

### 10.7 Reserve ve Net Profit Ayrimi
Reserve planner:
- net profit'i degistirmez
- gider yaratmaz
- sadece planlama bilgisidir

## 11. Transaction Mutability ve Edit/Delete Kurallari

### 11.1 Editlenebilir Alanlar
MVP'de bir transaction olustuktan sonra su alanlar duzenlenebilir:
- `occurred_on`
- `amount_minor`
- `category_id`
- `payment_method`
- `source_platform`
- `note`
- `vendor`
- `attachment_path`

### 11.1.1 Vendor Kurali
`vendor` alani MVP'de:
- opsiyonel
- free-text
- normalize edilmez
- ayri vendor tablosuna baglanmaz
- analytics source of truth olarak kullanilmaz

Vendor alani yalnizca kullanicinin kendi kaydina baglam eklemek icindir.

### 11.2 Editlenemeyecek Alanlar
Asagidaki alanlar sonradan degistirilmez:
- `id`
- `user_id`
- `type`

Yanlis tipte kayit girildiyse eski kayit silinip ya da iptal edilip dogrusu yeniden olusturulur.

### 11.3 Recurring'den Uretilen Transaction
Recurring expense uzerinden olusan gercek expense transaction:
- normal expense transaction gibi davranir
- sonradan note, amount, date vb. duzenlenebilir
- recurring parent ile audit baglantisi tutulmasi tercih edilir

### 11.4 Delete Davranisi
MVP icin varsayilan tercih:
- UI'da silme vardir
- teknik olarak `soft delete` kullanilir

Yani:
- kayit kullaniciya silinmis gorunur
- raporlardan cikar
- `deleted_at` tutulur

Hard delete ancak bilincli bir tradeoff olarak secilmelidir; varsayilan davranis degildir.

### 11.4.1 Soft Delete Query Kurali
Soft delete kullanilan tum sorgular varsayilan olarak:
- `deleted_at IS NULL`
filtrelemesi ile calismalidir.

Bu kural:
- dashboard sorgulari
- rapor sorgulari
- liste ekranlari
- kategori/recurring bagli transaction listeleri
icin gecerlidir.

Not:
- performans icin index stratejisi gerekebilir
- bu nedenle transaction ve ilgili ana listelerde `deleted_at` filtreli sorgular temel davranis kabul edilir

### 11.5 Attachment Davranisi
Attachment opsiyoneldir.
- sonradan eklenebilir
- degistirilebilir
- silinebilir
- finansal hesaplara etki etmez

### 11.6 Source Platform Editlenebilirlik Notu
`source_platform` alaninin editlenebilir olmasi bilincli bir MVP kararidir.

Sonuc:
- kullanici yanlis platform secimini duzeltebilir
- ama bu degisiklik gecmis analytics dagilimini de degistirir

Bu tradeoff kabul edilmistir:
- veri giris hatalarini duzeltmek, analitik katmanin immutable olmasindan daha onceliklidir
- audit gereksinimi buyurse ileride degisiklik gecmisi ayri tutulabilir

## 12. Reminder Kurallari

### 12.1 Reminder Tipi
MVP'de reminder:
- `in-app reminder` olarak calisir

Push notification zorunlu degildir.

### 12.2 Reminder Penceresi
Recurring expense icin:
- `reminder_days_before` alani kadar once hatirlatma gosterilir

### 12.3 Reminder State'leri
- `due_soon`
- `due_today`
- `overdue`

Bu state'ler UI'da ayri gorunebilir ama hepsi reminder katmanidir.

## 13. Dashboard ve Reports Arasi Fark

### 13.1 Dashboard
Dashboard:
- hizli haftalik bakis
- operasyonel netlik
- son hareketler
- upcoming recurring
- reserve summary

### 13.2 Reports
Reports:
- daha derin analiz
- aylik profit/loss
- kategori dagilimi
- haftalar arasi karsilastirma

Dashboard ve reports ayni veriden beslense de ayni sunum katmani degildir.

## 14. MVP Disinda Bilincli Olarak Cozulmeyenler
Asagidaki konular bilincli sekilde sonraya birakilmistir:
- reserve ledger / gercek reserve takibi
- push notification
- OCR
- banka entegrasyonu
- VAT/KDV ayrimi
- delivery platform komisyon detay muhasebesi
- cok kullanicili davranislar
- resmi muhasebe uyumlulugu

Bu eksikler MVP baslangicina engel degildir.

## 15. Son Karar Ozetleri

### Kesin Kararlar
- hafta Pazartesi baslar, Pazar biter
- timezone `Europe/London`
- net profit sadece gercek transaction'lardan hesaplanir
- recurring gider paid olana kadar gercek gider degildir
- reserve planner planlama katmanidir, gider degildir
- Uber / Just Eat haftalik settlement transaction olarak tutulur
- category sistemi dinamik ve type-bazlidir
- payment method analytics'i etkiler
- transaction `type` sonradan degismez
- kullanici yanlis kayitlari duzenleyebilir veya silebilir
- monetary hesaplar minor unit ile tutulur
- varsayilan silme yaklasimi soft delete'tir

### Uygulama Kurali
Bu dokuman domain source of truth'tur.
Kod, UI veya migration kararlari bu kurallari sessizce asamaz.

Yeni ihtiyac cikarsa once bu dokuman guncellenir, sonra kod degisir.
