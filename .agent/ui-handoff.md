# UI Handoff: Gider
**Tarih:** 2026-04-20
**Plan Maddesi:** `T0: Tasarim handoff ve ekran eslestirmesi`
**Durum:** T0 cikti dokumani

## 1. Kapsam
Bu dokuman sadece su isi kilitler:
- Referans ekranlari MVP ekranlariyla eslestirmek
- Hi-fi'da dogrudan olmayan ama planda olan ekranlari not etmek
- Hangi varyantin secildigini yazili hale getirmek
- Hangi layout ve component kararlarinin birebir korunacagini netlestirmek

Bu dokuman yeni ekran onermiyor, scope genisletmiyor, polish backlog'u acmiyor.

## 2. Source Of Truth
Ana kaynaklar:
- `.agent/implementation_plan.md`
- `.agent/product.md`
- `.agent/design.md`

Gorsel referans zinciri:
- `design.md` icindeki final visual source of truth: `.agent/design-reference/gider-hi-fi.html`
- Destekleyici layout referansi: `.agent/design-reference/gider-wireframes-standalone.html`

Karar hiyerarsisi:
1. MVP kapsami ve task sirasi: `implementation_plan.md`
2. Urun sinirlari ve davranis hedefi: `product.md`
3. Gorsel dil ve UI davranisi: `design.md`
4. Ekran kompozisyonu ve varyant secimi: bu dokuman

## 3. Aktif T0 Ciktisi
T0 tamamlanmis sayilmasi icin su bes madde bu dokumanda net olmak zorunda:
1. Haftalik ozet dashboard eslestirmesi
2. Islemler listesi eslestirmesi
3. Aylik rapor eslestirmesi
4. Kategori ve ayarlar eslestirmesi
5. Hizli ekleme sheet eslestirmesi

Asagidaki bolumler bu bes maddeyi kilitler.

## 4. Ekran Eslestirme Matrisi
| MVP yuzeyi | Plan task | Hi-fi referansi | Secilen varyant | Karar |
|---|---|---|---|---|
| App shell + bottom nav + FAB | `T6.1` | 01, 03, 04, 05, 06, 07, 08 | Ortak shell yapisi | Tek kolon mobil shell, 4 tab bottom nav ve sag altta FAB korunur |
| Haftalik ozet dashboard | `T6.3`, `T15` | 01 Weekly dashboard | `A - Net-first hero` | MVP ana ekran bu varyantin hiyerarsisi ile kurulur: hafta araligi, net odak, summary kartlari, upcoming, recent |
| Gelir ekleme | `T10` | 02 Income & expense entry | `C - Income twin` | Gelir formu, klasik form akisini korur; income palette ve platform alani bu varyanttan alinir |
| Gider ekleme | `T11` | 02 Income & expense entry | `A - Classic form` | Gider formu tam gorunen alanlar ve sticky save ile uygulanir |
| Islemler listesi | `T12` | 03 Transactions | `A - By day` | Tum kayitlar gun bazli gruplanir; arama ve filtre chipleri bu yapinin ustune eklenir |
| Islem duzenleme | `T12` | 02 Income & expense entry | Turetilmis | Ayrica hi-fi ekran yok; gelir/gider form layout'u mevcut veri ile doldurulmus edit ekranina donusturulur |
| Aylik rapor | `T16` | 04 Monthly profit & loss | `A - P&L statement` | Aylik gelir/gider/net ve kategori dagilimi icin resmi temel budur |
| Tekrarlayan giderler listesi | `T13` | 05 Recurring expenses | `A - Next-up list` | Sira mantigi, status chip ve list item yapisi buradan alinir |
| Odendi olarak isaretleme | `T14` | 05 Recurring expenses | `B - Mark-paid flow` | Ayrica ekran degil, bottom sheet akisidir |
| Kategori yonetimi | `T9` | 06 Categories | `A - List with usage` | CRUD ve archive ihtiyaci nedeniyle liste varyanti secilir |
| Ayarlar | `T6` | 07 Settings & profile | `A - Quiet drawer` | MVP ayarlari grouped row duzeniyle uygulanir |
| Hizli ekleme sheet | `T6.1` | 08 Add sheet | `A - Clean list` | Uc aksiyon esit agirlikla listelenir: gelir, gider, tekrarlayan gider |
| Login / sign up | `T5` | Hi-fi'da yok | Mevcut auth yeterli | Bu task T0 icinde sadece not edilir; auth'a yeni polish acilmaz |
| Ilk login bootstrap / onboarding | `T6` | Hi-fi'da yok | Settings'ten turetilmis | Grup satir mantigi Settings A'dan turetilir, yeni bir gorsel dil icat edilmez |
| Tekrarlayan gider create/edit | `T13` | Hi-fi'da yok | Expense form + recurring list'ten turetilmis | Gider formunun alan mantigi korunur, recurring'e ozel frequency ve due alanlari eklenir |

## 5. Secilen Varyantlar Ve Acik Retler
Bu bolum T0'un en kritik parcasi: hangi hi-fi varyantinin resmi referans oldugunu ve hangilerinin secilmedigini yazar.

### Dashboard
- Secilen: `01-A Net-first hero`
- Secilmeyen: `01-B Editorial ledger`, `01-C 7-day spine`
- Gerekce: `product.md` ana deneyimi "Bu hafta ne kazandim, ne harcadim, net ne kaldi?" diye tanimliyor. Net-first hero bunu en hizli cozen varyant.

### Entry
- Gelir: `02-C Income twin`
- Gider: `02-A Classic form`
- Secilmeyen: `02-B Amount-first`
- Gerekce: MVP'de hizli ve okunur tam form akisi isteniyor. Custom keypad varyanti bu asamada zorunlu degil ve plan maddesinde gecmiyor.

### Transactions
- Secilen: `03-A By day`
- Secilmeyen: `03-B Split tabs`
- Gerekce: `product.md` "Tum kayitlar" ve geriye donuk duzenleme/silme ihtiyacini one koyuyor. Gun bazli tek liste, tum kayitlar mantigina daha dogrudan uyuyor.

### Reports
- Secilen: `04-A P&L statement`
- Secilmeyen: `04-B Weeks compared`
- Gerekce: `implementation_plan.md` T16 cikti tanimi aylik kar-zarar ve kategori dagilimi. Haftalik karsilastirma destekleyici olabilir ama ana layout referansi A'dir.

### Categories
- Secilen: `06-A List with usage`
- Secilmeyen: `06-B Icon grid`
- Gerekce: MVP ihtiyaci CRUD + archive. Liste varyanti operasyonel olarak daha net.

### Settings
- Secilen: `07-A Quiet drawer`
- Secilmeyen: `07-B Shortcut tiles`
- Gerekce: `07-B` icindeki export ve app lock, `product.md` MVP disi. Bu nedenle grouped row yapisi korunur, MVP disi tile'lar alinmaz.

### Add Sheet
- Secilen: `08-A Clean list`
- Secilmeyen: `08-B Bold tiles`
- Gerekce: `design.md` quick actions listesi uc esit eylem tanimliyor. Recurring aksiyonunu ikinci plana itmemek icin A secilir.

## 6. Hi-fi'da Dogrudan Olmayan Ama Planda Olan Ekranlar
Bu ekranlar plan dahilidir ama hi-fi'da ayri blok olarak yoktur. T0 karari olarak bunlar sadece mevcut referanstan turetilir; yeni tasarim dili acilmaz.

| Ekran | Plan task | Turetildigi kaynak | Not |
|---|---|---|---|
| Login | `T5` | `design.md` semantic skeleton | Mevcut auth yeterli; yeni polish yok |
| Sign up | `T5` | Login ile ayni gorsel sistem | Ayrica hi-fi beklenmez |
| Islem edit | `T12` | 02-A / 02-C | Form tekrar kullanilir, ust bar ve delete aksiyonu eklenir |
| Recurring create/edit | `T13` | 02-A + 05-A | Expense form tabani, recurring alanlari eklenir |
| Onboarding / business settings bootstrap | `T6` | 07-A | Grouped row ve temel ayar formu |
| Reserve planner card | `T14.1` | 01-A dashboard icine yerlestirilmis urun uyarlamasi | `design.md` bunu urune ozel uyarlama olarak acikca izinli sayiyor |

## 7. Korunacak Layout Sadakat Kurallari
Asagidaki maddeler T0'dan sonra degistirilmeyecek temel UI kurallaridir.

- Tek kolon mobil deneyim korunur.
- Ana hedef genislik `360px - 430px`; buyuk ekranda 560px max content width kullanilir.
- Bottom nav her zaman 4 sekme olarak kalir: `Ozet`, `Islemler`, `Raporlar`, `Ayarlar`.
- FAB sag altta sabit kalir ve sadece hizli ekleme sheet'ini acar.
- Dashboard ilk ekran olarak kalir.
- Summary kartlar yatay carousel'e donusturulmez.
- Kart tabanli hiyerarsi korunur; tablo benzeri yogun layout kullanilmaz.
- Grafikler destekleyicidir; sayilar ve metin birincildir.
- Serif heading + sade sans body hiyerarsisi korunur; handwritten tipografi kullanilmaz.
- Sicak acik zemin + petrol vurgu + gelir yesili + gider toprak kirmizisi yonu korunur.
- Radius ve shadow yumusak kalir; keskin, soguk fintech dili kullanilmaz.
- Add sheet bottom sheet olarak kalir; ayrica tam ekran menuye cevrilmez.
- Settings grouped rows mantigi korunur; MVP disi export/app lock gibi ek alanlar tasinmaz.
- Categories ekrani CRUD-first kalir; icon grid MVP default olmaz.

## 8. MVP Component Envanteri
Bu liste T0 kapsaminda sadece envanteri kilitler. Kodlama T0.1, T6.2 ve T6.3'te yapilacak.

| Component | Kaynak | Kullanilacagi tasklar |
|---|---|---|
| `MobileScaffold` | Tum hi-fi ekranlar | `T6.1` |
| `BottomNav` | 01/03/04/05/06/07 | `T6.1` |
| `FloatingAddButton` | 01/06/07/08 | `T6.1` |
| `AppTopBar` / section header | 01/03/04/05/06/07 | `T6.1` |
| `SummaryCard` | 01 | `T6.3`, `T15`, `T16` |
| `TransactionListItem` | 01, 03 | `T6.3`, `T12` |
| `UpcomingPaymentItem` | 01, 05 | `T6.3`, `T14` |
| `ReservePlannerCard` | Urun uyarlamasi | `T14.1`, `T15` |
| `AppButton` | 02, 08 | `T6.2` |
| `AppInput` | 02 | `T6.2` |
| `AppChip` / `FilterChip` | 02, 03, 05 | `T6.2`, `T12`, `T14` |
| `AppCard` | Tum kartli yuzeyler | `T6.2` |
| `AppSheet` | 05-B, 08-A | `T6.2`, `T14` |
| `AttachmentField` | 02-A | `T11` |
| `CategoryListRow` | 06-A | `T9` |
| `MonthNavigator` | 04-A | `T16` |

## 9. Plan Disi Ogeler
Asagidaki ogeler hi-fi'da gorunse bile MVP'ye tasinmaz:
- Export CSV
- App lock / PIN
- Shortcut tiles settings varyanti
- Categories drag reorder davranisi
- Dashboard icin 7-day spine alternatif layout
- Entry icin custom keypad zorunlulugu

## 10. T0 Sonucu
Bu dokumana gore T0 kabul kosulu saglanmistir:
- Haftalik ozet eslestirildi
- Islemler eslestirildi
- Raporlar eslestirildi
- Kategori ve ayarlar eslestirildi
- Hizli ekleme eslestirildi
- Eksik ekranlar not edildi
- Component envanteri cikarildi
- Layout sadakat kurallari yazili hale getirildi
