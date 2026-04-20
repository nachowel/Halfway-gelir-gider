# Implementation Plan: UK Gelir Gider Takip Uygulamasi
**Tarih:** 2026-04-20
**Tahmini Sure:** 12-15 is gunu
**Kaynak:** [Scope Doc](C:/Users/nacho/Desktop/gider/.agent/SCOPE-gelir-gider-uk.md)
**Tasarim Referanslari:** [Design Brief](C:/Users/nacho/Desktop/gider/.agent/design.md), [Hi-Fi Export](C:/Users/nacho/Desktop/gider/.agent/design-reference/gider-hi-fi.html), [Wireframe Export](C:/Users/nacho/Desktop/gider/.agent/design-reference/gider-wireframes-standalone.html)

## Ozet
Bu plan, tek kullanicili ve Android odakli bir Flutter uygulamasi olarak calisacak gelir-gider uygulamasinin ilk kullanilabilir surumunu cikarir. Ilk hedef, gelir ve gider kayitlarini hizli girmek, haftalik ozet ve aylik kar-zarar raporlarini gostermek, tekrarlayan giderleri hatirlatmak, reserve planner ile buyuk giderler icin haftalik ayirma onerisi sunmak ve veriyi bulutta yedeklerken offline kayit alip sonra senkron edebilmektir.

Plan, ilk surumde sadece is degeri ureten cekirdegi kapsar: auth, veri modeli, kategori sistemi, kayit ekranlari, tekrarlayan giderler, reserve planner, ozet/raporlar ve temel offline sync. OCR, detayli stok sayimi ve delivery platform kesinti muhasebesi bilerek disarida tutulur.

Bu plan artik `design-first` ve `Flutter-first` uygulanacaktir. Kodlama asamasinda secilen export ve `design.md` resmi kaynak kabul edilecek; UI implementasyonunda tasarim yeniden yorumlanmayacak, mevcut referans yuksek sadakatle Flutter widget yapisina tasinacaktir.

## Tech Stack Kararlari
| Alan | Secim | Gerekce |
|------|-------|---------|
| Uygulama tipi | Flutter Android-first mobil uygulama | Android kullanimina dogrudan uygun, native'e yakin deneyim, tek kod tabani |
| Dil | Dart | Flutter ekosistemi ve tip guvenligi icin |
| State management | Riverpod | Moduler, test edilebilir ve feature-first yapiya uygun |
| Routing | go_router | Auth ve tab tabanli navigasyonu duzenli kurmak icin |
| Auth | supabase_flutter | E-posta/sifre ve Google girisini hizli saglar |
| Veritabani | Supabase Postgres | Bulut yedek, basit backend, SQL raporlama kolayligi |
| Dosya yukleme | Supabase Storage | Fatura/fotograf ekleri icin yeterli |
| Offline veri | Drift + SQLite | Lokal veri, outbox queue ve guclu query ihtiyaci icin |
| Sync | Ozel outbox queue + retry mantigi | Offline kayit alip online olunca gondermek icin |
| Ag durumu | connectivity_plus | Online/offline gecislerini izlemek icin |
| Grafik/rapor | fl_chart | Basit ve yeterli mobil grafik ihtiyaci icin |
| Medya secimi | image_picker / file_picker | Fis-fatura gorseli ekleme icin |
| Bildirim MVP | In-app due reminder | Push notification ek karmasini ilk surumde ertelemek icin |
| Test | flutter_test + integration_test | Domain, widget ve kritik akislari birlikte dogrulamak icin |

## Tasarim Handoff Kurallari
- `design.md`, lokal Hi-Fi export ve wireframe exportlari resmi UI kaynagidir.
- `gider-hi-fi.html` final visual source of truth kabul edilir.
- Ekran yapisi, kart hiyerarsisi, bottom navigation, haftalik ozet akisi ve temel yerlesim korunacaktir.
- Uygulama kodlanirken tasarim yeniden tasarlanmayacak; sadece responsive, accessibility ve teknik implementasyon geregi minimum uyarlama yapilacaktir.
- Yapilacak uyarlamalar sadece urunun kendi icerigi, form alanlari, reserve planner bolumu ve gercek veri durumlarini tasarima yerlestirmek icindir.
- Handwritten / script tipografi kullanilmayacak; ayni hiyerarsi temiz urun tipografisiyle uygulanacaktir.
- Renk, tipografi, radius ve shadow sistemi Hi-Fi exporta sadik kalacak; final UI production-ready kontrast seviyesine tasinacaktir.

## Etkilenen Alanlar
Bu repo su an urun kodu icermiyor; asagidaki alanlar yeni olusacak.

```text
lib/
  app/
    app.dart
    router/
    shell/
    theme/
  core/
    auth/
    domain/
    utils/
  data/
    local/
    remote/
    sync/
  features/
    auth/
    dashboard/
    transactions/
    recurring/
    reports/
    settings/
  shared/
    widgets/
    navigation/
    layout/
assets/
  fonts/
  icons/
  images/
android/
test/
integration_test/
supabase/
  migrations/
```

## Dosya ve Sorumluluk Haritasi
| Alan | Durum | Not |
|------|-------|-----|
| `lib/app/` | Yeni | App bootstrap, theme, router, shell |
| `lib/core/` | Yeni | Auth yardimcilari, domain kurallari, ortak util katmani |
| `lib/data/remote/` | Yeni | Supabase repository fonksiyonlari |
| `lib/data/local/` | Yeni | Drift schema, local cache ve outbox queue |
| `lib/data/sync/` | Yeni | Online/offline sync orchestration |
| `lib/features/auth/` | Yeni | Login, signup ve session akislari |
| `lib/features/dashboard/` | Yeni | Haftalik ozet kartlari ve yaklasan odemeler widget'i |
| `lib/features/transactions/` | Yeni | Gelir, gider, liste ve edit ekranlari |
| `lib/features/recurring/` | Yeni | Recurring giderler ve reserve planner akisleri |
| `lib/features/reports/` | Yeni | Aylik kar-zarar ve kategori dagilimi |
| `lib/features/settings/` | Yeni | Profil, kategori ve business settings akislari |
| `assets/` | Yeni | Font, icon ve static UI assetleri |
| `supabase/migrations/` | Var | Tablo, index, row-level security yapisi |
| `test/`, `integration_test/` | Yeni | Unit, widget ve device/integration testleri |

## Veri Modeli Karari
Ilk surumde asagidaki cekirdek tablolar yeterli:

- `profiles`
  - Supabase auth kullanicisini uygulama profiline baglar
- `categories`
  - `type`: `income` veya `expense`
  - Dinamik kategori tanimi, archive destegi
- `transactions`
  - Gelir/gider ortak tablo
  - Alanlar: `occurred_on`, `amount_minor`, `currency`, `category_id`, `payment_method`, `source_platform`, `note`, `vendor`, `attachment_path`
- `recurring_expenses`
  - Tutar, kategori, frequency, next_due_on, reminder_days_before, is_active, reserve_enabled
- `business_settings`
  - Hafta baslangici, para birimi, timezone ve temel is ayarlari

Reserve planner icin ilk surumde ayri bir ledger tutulmasi zorunlu degil. Haftalik reserve onerisi, `recurring_expenses` kayitlarindan turetilmis hesaplanan bir gorunum olarak baslayacak.

## Gorevler

### Asama 0: Tasarimdan Flutter Uygulamasina Gecis

- [ ] **T0: Tasarim handoff ve ekran eslestirmesi** `[CHECKPOINT]`
  - Dosyalar: `.agent/design.md`, `.agent/design-reference/gider-hi-fi.html`, `.agent/design-reference/gider-wireframes-standalone.html`, gerekirse `.agent/ui-handoff.md`
  - Icerik: Referans ekranlari MVP ekranlariyla eslestirme, eksik ekranlari not etme, komponent listesi cikarma, hangi alanlarin birebir korunacagini yazili hale getirme
  - Bagimlilik: Yok
  - Test: Haftalik ozet, islemler, raporlar, kategori/ayarlar ve hizli ekleme akislari net sekilde eslestirilmis; layout sadakat kurallari yazili hale gelmis

- [ ] **T0.1: Design tokens ve Flutter theme kurallari cikarimi** `[CHECKPOINT]`
  - Dosyalar: `lib/app/theme/app_theme.dart`, `lib/app/theme/app_tokens.dart`, gerekirse `.agent/ui-handoff.md`
  - Icerik: Renkler, spacing, radius, shadow, tipografi olcekleri ve component durumlari
  - Bagimlilik: T0
  - Test: Kod tarafinda kullanilacak token seti ve tipografi sistemi netlesmis

### Asama 1: Temel Kurulum

- [ ] **T1: Flutter proje iskeleti ve uygulama kabugu** `[CHECKPOINT]`
  - Dosyalar: `pubspec.yaml`, `lib/main.dart`, `lib/app/app.dart`, `android/app/src/main/AndroidManifest.xml`
  - Icerik: Flutter iskeleti, temel app shell, tema, environment baglantisi ve Android konfigurasyonu
  - Bagimlilik: T0.1
  - Test: Uygulama emulator veya cihazda aciliyor, temel shell ve navigation yukleniyor

- [ ] **T2: Supabase baglanti katmani ve ortam degiskenleri**
  - Dosyalar: `.env.example`, `.env.local`, `lib/core/supabase/supabase_client.dart`, `lib/core/auth/session_controller.dart`
  - Icerik: Supabase client kurulumu, environment okuma, session yonetimi
  - Bagimlilik: T1
  - Test: Auth client olusuyor, ortam degiskenleri eksikken kontrollu hata veriyor

- [ ] **T3: Veritabani migration'lari ve temel seed verisi** `[RISK][CHECKPOINT]`
  - Dosyalar: `supabase/migrations/001_initial_schema.sql`, `supabase/migrations/002_rls_policies.sql`, `supabase/seed.sql`
  - Icerik: `profiles`, `business_settings`, `categories`, `transactions`, `recurring_expenses` tablolari ve varsayilan kategori seed'leri
  - Bagimlilik: T2
  - Test: Migration temiz veritabaninda calisiyor, ornek varsayilan kategoriler ekleniyor

### Asama 2: Domain ve Auth

- [ ] **T4: Domain modelleri ve validation katmani**
  - Dosyalar: `lib/core/domain/types.dart`, `lib/core/domain/transaction_model.dart`, `lib/core/domain/category_model.dart`, `lib/core/domain/recurring_model.dart`
  - Icerik: Tutar, tarih, kategori, odeme tipi ve settlement kurallari
  - Bagimlilik: T3
  - Test: Geceerli/gecersiz payload unit testleri geciyor

- [ ] **T5: Auth akisi ve route protection** `[CHECKPOINT]`
  - Dosyalar: `lib/features/auth/presentation/login_screen.dart`, `lib/features/auth/presentation/signup_screen.dart`, `lib/app/router/app_router.dart`
  - Icerik: E-posta/sifre girisi, Google ile giris, korumali route ve auth redirect mantigi
  - Bagimlilik: T2
  - Test: Giris yapmayan kullanici dashboard'a giremiyor, giris yapan dashboard goruyor

- [ ] **T6: Profil ve business settings bootstrap akisi**
  - Dosyalar: `lib/features/settings/presentation/onboarding_screen.dart`, `lib/data/remote/profile_repository.dart`, `lib/data/remote/settings_repository.dart`
  - Icerik: Ilk acilista GBP, timezone ve hafta baslangici ayarlari
  - Bagimlilik: T3, T5
  - Test: Ilk login sonrasi ayar kaydi olusuyor ve tekrar login'de tekrar sormuyor

### Asama 3: UI Temeli ve Tasarima Sadik Iskelet

- [ ] **T6.1: App shell, bottom navigation ve base screen chrome** `[CHECKPOINT]`
  - Dosyalar: `lib/app/shell/app_shell.dart`, `lib/shared/navigation/bottom_nav.dart`, `lib/shared/layout/mobile_scaffold.dart`
  - Icerik: Referans tasarimdaki tek kolon mobil shell, alt navigation, ust bar ve floating action button
  - Bagimlilik: T0.1, T1, T5
  - Test: Tum ana ekranlar ayni shell icinde render oluyor ve referans yerlesime uyuyor

- [ ] **T6.2: Design system temel komponentleri**
  - Dosyalar: `lib/shared/widgets/app_button.dart`, `lib/shared/widgets/app_card.dart`, `lib/shared/widgets/app_input.dart`, `lib/shared/widgets/app_chip.dart`, `lib/shared/widgets/app_sheet.dart`
  - Icerik: Kart, buton, input, chip, bottom sheet ve durum varyantlari
  - Bagimlilik: T6.1
  - Test: Temel UI komponentleri design tokenlariyla calisiyor

- [ ] **T6.3: Dashboard summary card ve liste item UI'lari**
  - Dosyalar: `lib/features/dashboard/widgets/summary_cards.dart`, `lib/features/dashboard/widgets/transaction_list_item.dart`, `lib/features/dashboard/widgets/upcoming_payment_item.dart`
  - Icerik: Tasarimdaki ozet kartlari, islem satiri ve yaklasan odeme item'lari
  - Bagimlilik: T6.2
  - Test: Mock veri ile referans tasarima yakin kart hiyerarsisi kuruluyor

### Asama 4: Offline Katman ve Sync

- [ ] **T7: Drift local schema ve outbox queue** `[RISK][CHECKPOINT]`
  - Dosyalar: `lib/data/local/app_database.dart`, `lib/data/local/tables.dart`, `lib/data/local/outbox_repository.dart`
  - Icerik: Local transaction cache, pending mutation queue, temel retry metadata
  - Bagimlilik: T4
  - Test: Offline modda kayit local'e dusuyor, queue kaydi olusuyor

- [ ] **T8: Sync motoru ve conflict kurallari** `[RISK][CHECKPOINT]`
  - Dosyalar: `lib/data/sync/sync_engine.dart`, `lib/data/sync/sync_service.dart`, `lib/data/sync/conflict_policy.dart`
  - Icerik: Online olunca pending kayitlari Supabase'e gonderme, basit last-write-wins guncelleme kurali
  - Bagimlilik: T2, T7
  - Test: Offline eklenen kayit online olunca remote'a cikiyor, duplicate olusmuyor

### Asama 5: Kategori ve Kayit Girisi

- [ ] **T9: Kategori yonetimi CRUD**
  - Dosyalar: `lib/features/settings/presentation/category_management_screen.dart`, `lib/features/settings/widgets/category_form.dart`, `lib/data/remote/category_repository.dart`
  - Icerik: Gelir/gider kategorisi ekleme, guncelleme, archive etme
  - Bagimlilik: T4, T8, T6.2
  - Test: Kullanici yeni kategori ekliyor, eski kategori archive edilebiliyor

- [ ] **T10: Gelir kaydi akisi**
  - Dosyalar: `lib/features/transactions/presentation/income_form_screen.dart`, `lib/features/transactions/widgets/income_form.dart`, `lib/data/remote/transaction_repository.dart`
  - Icerik: Cash, card, Uber, Just Eat ve diger gelir kayitlari; Uber/Just Eat haftalik settlement mantigi
  - Bagimlilik: T4, T8, T9, T6.2
  - Test: Gelir create/update/delete repository akisi ve income entry form submit entegrasyonu calisiyor; settlement kaydinda `source_platform` dogru persist ediliyor

- [ ] **T11: Gider kaydi akisi**
  - Dosyalar: `lib/features/transactions/presentation/expense_form_screen.dart`, `lib/features/transactions/widgets/expense_form.dart`, `lib/features/transactions/widgets/attachment_field.dart`
  - Icerik: Gider formu, opsiyonel foto/fatura ekleme, vendor/aciklama alanlari
  - Bagimlilik: T4, T8, T9, T6.2
  - Test: Gider kaydi olusuyor, opsiyonel attachment yuklenebiliyor, kayit duzenlenip silinebiliyor

- [ ] **T12: Kayit listesi ve gecmise donuk duzenleme**
  - Dosyalar: `lib/features/transactions/presentation/transaction_list_screen.dart`, `lib/features/transactions/widgets/transaction_list.dart`, `lib/features/transactions/presentation/transaction_edit_screen.dart`
  - Icerik: Filtreleme, detay, edit ve delete
  - Bagimlilik: T10, T11, T6.3
  - Test: Var olan kayit bulunuyor, guncelleniyor, siliniyor

### Asama 6: Tekrarlayan Giderler

- [ ] **T13: Recurring expense tanimi ve liste ekranlari**
  - Dosyalar: `lib/features/recurring/presentation/recurring_list_screen.dart`, `lib/features/recurring/widgets/recurring_form.dart`, `lib/data/remote/recurring_repository.dart`
  - Icerik: Haftalik, aylik, 3 aylik, yillik gider tanimi; aktif/pasif durumu; reserve planner'a dahil edilip edilmeyecegi
  - Bagimlilik: T4, T8, T9, T6.2
  - Test: Yeni recurring tanimlanabiliyor, listeleniyor, guncelleniyor

- [ ] **T14: Due reminder ve odendi olarak kesinlestirme** `[CHECKPOINT]`
  - Dosyalar: `lib/core/domain/recurring_engine.dart`, `lib/features/dashboard/widgets/upcoming_payments.dart`, `lib/features/recurring/presentation/mark_paid_sheet.dart`
  - Icerik: Yaklasan odemeleri hesaplama, in-app reminder, odendi denince gercek gider transaction'i olusturma ve `next_due_on` ilerletme
  - Bagimlilik: T13, T6.3
  - Test: Vadesi yaklasan kayit dashboard'da gorunuyor, "paid" islemi gider yaratip bir sonraki tarihi dogru ayarliyor

### Asama 7: Ozet ve Raporlar

- [ ] **T14.1: Reserve planner hesap motoru ve ozet karti** `[CHECKPOINT]`
  - Dosyalar: `lib/core/domain/reserve_planner.dart`, `lib/features/dashboard/widgets/reserve_planner_card.dart`, gerekirse `lib/features/recurring/presentation/reserve_detail_screen.dart`
  - Icerik: Tekrarlayan buyuk giderler icin `haftalik ayrilmasi onerilen tutar` hesaplama, toplam reserve onerisi, kalem bazli liste
  - Bagimlilik: T13, T14, T6.3
  - Test: Kira, broadband ve benzeri orneklerde reserve onerileri tarih/frekans mantigina gore dogru hesaplaniyor

- [ ] **T15: Haftalik ozet dashboard'u** `[CHECKPOINT]`
  - Dosyalar: `lib/features/dashboard/presentation/dashboard_screen.dart`, `lib/features/dashboard/widgets/summary_cards.dart`, `lib/core/domain/weekly_summary.dart`
  - Icerik: Pazartesi-Pazar arasi toplam gelir, toplam gider, cash gelir, card gelir, net kazanc, yaklasan odemeler ve reserve planner ozeti
  - Bagimlilik: T10, T11, T14, T14.1, T6.3
  - Test: Ornek veri ile haftalik toplamlar dogru hesaplaniyor

- [ ] **T16: Aylik kar-zarar ve kategori dagilimi**
  - Dosyalar: `lib/features/reports/presentation/monthly_report_screen.dart`, `lib/features/reports/widgets/monthly_profit_loss.dart`, `lib/features/reports/widgets/category_breakdown.dart`
  - Icerik: Aylik toplamlari ve gider kategorisi kirilimini gosteren rapor
  - Bagimlilik: T10, T11, T6.2
  - Test: Aylik filtre ile gelir/gider/net hesaplari dogru gorunuyor

### Asama 8: Kalite ve Yayin Hazirligi

- [ ] **T17: Kritik integration test akislari**
  - Dosyalar: `integration_test/auth_flow_test.dart`, `integration_test/income_expense_flow_test.dart`, `integration_test/recurring_flow_test.dart`, `integration_test/offline_sync_flow_test.dart`
  - Icerik: Login, gelir-gider kaydi, recurring odeme ve offline-sync senaryolari
  - Bagimlilik: T15, T16
  - Test: Tanimli tum integration senaryolari geciyor

- [ ] **T18: Android build, release hazirligi ve veri yedek dogrulamasi** `[CHECKPOINT]`
  - Dosyalar: `README.md`, `docs/deploy.md` veya `.agent/deploy-checklist.md`
  - Icerik: Ortam degiskenleri, Supabase kurulum notlari, Android APK/AAB build akisi ve veri geri yukleme kontrol listesi
  - Bagimlilik: T17
  - Test: Uygulama Android cihazda build oluyor, yeni cihazda login ile veri gorunuyor

## Bagimlilik Grafigi
```text
T0 -> T0.1 -> T1 -> T2 -> T3 -> T4
                     |          |
                     |          -> T7 -> T8 -> T9 -> T10 -> T12 -> T15 -> T17 -> T18
                     |                   |      -> T11 -> T12
                     |                   |      -> T13 -> T14 -> T15
                     -> T5 -> T6 -> T6.1 -> T6.2 -> T6.3
T10 + T11 + T6.2 -> T16 -> T17
```

## Paralel Calisma Firsatlari
- `T5` ve `T3` kismen paralel ilerleyebilir; auth UI, schema tamamlanirken hazirlanabilir.
- `T0` sonrasinda `T0.1` ile birlikte theme token cikarimi ve component inventory hizlica paralel netlestirilebilir.
- `T6.1`, `T6.2` ve mock veriye dayali `T6.3` UI omurgasini backend tamamlanmadan once hazirlayabilir.
- `T10` ve `T11` ortak form altyapisi cikarildiktan sonra paralel ilerleyebilir.
- `T14.1` reserve planner UI'si mock recurring verisiyle erken hazirlanabilir.
- `T15` dashboard UI'si, `weekly_summary` domain fonksiyonu mock veriyle hazirlanarak kismen paralel baslayabilir.
- `T16` rapor komponentleri, transaction sorgulari netlesince paralel gelistirilebilir.

## Risk Listesi
| Risk | Olasilik | Etki | Onlem |
|------|----------|------|-------|
| Referans tasarim kodlama sirasinda sessizce degisir veya yorumlanir | Orta | Yuksek | `design.md` + lokal exportu source of truth kabul et, UI review'leri referansa gore yap |
| Reserve planner formulu kullanici beklentisine gore fazla basit veya fazla sert kalir | Orta | Orta-Yuksek | MVP'de sadece onerisel hesap yap, formuleyi belgeleyip gercek kullanimla test et |
| Offline sync duplicate veya kayip kayit uretir | Orta | Yuksek | Outbox idempotency key ve integration testleri yaz |
| Recurring gider mantigi tarih kaymalarinda hata uretir | Orta | Yuksek | Domain unit testleri ile haftalik/aylik/3 aylik/yillik senaryolari kapsa |
| Flutter mimarisi kontrolsuz buyurse feature klasorleri daginiklasir | Orta | Orta | Feature-first klasor yapisi ve Riverpod sinirlari bastan kilitlenmeli |
| Supabase policy hatasi veri gorunurlugunu bozar | Dusuk-Orta | Yuksek | RLS migration testleri ve tek kullanici senaryosu dogrulama |
| Dinamik kategori yapisi raporlari karmasiklastirir | Orta | Orta | Varsayilan seed kategorileri ver, archive mantigi kullan |
| Fotograf yukleme form deneyimini yavaslatir | Orta | Dusuk-Orta | Attachment tamamen opsiyonel kalsin, async upload kullan |

## Tanimlanmamis Noktalar
- [ ] Due reminder'in sadece in-app mi kalacagi, yoksa Android local notification olarak da acilip acilmayacagi sonraki karar
- [ ] Varsayilan kategori seed listesinde hangi basliklarin gelecegi
- [ ] Haftalik ozet ekraninda Uber ve Just Eat ozetlerinin kart olarak mi yoksa alt liste olarak mi gosterilecegi
- [ ] Attachment saklama limitinin ne olacagi
- [ ] Reserve planner formulu gun/hafta bazinda mi, yoksa sabit haftalik mantikta mi gosterilecek son ince ayar

## Checkpoint Plani
1. **Checkpoint A:** `T0.1` bitince design handoff ve theme/token sistemi kilitlenecek.
2. **Checkpoint B:** `T3` bitince schema ve RLS gozden gecirilecek.
3. **Checkpoint C:** `T8` bitince offline-sync mantigi gercek cihaz senaryosuyla test edilecek.
4. **Checkpoint D:** `T14` bitince recurring gider akisi dogrulanacak.
5. **Checkpoint E:** `T15` bitince MVP'in cekirdek is degeri kullanici gozuyle kontrol edilecek.
6. **Checkpoint F:** `T18` bitince Android release ve cihaz degisimi senaryosu onaylanacak.

## MVP Cikis Kriteri
Asagidaki maddeler tamamlanmadan MVP "hazir" sayilmaz:

- Kullanici hesap acip giris yapabiliyor
- Gelir ve gider kaydi telefondan hizli girilebiliyor
- Kayitlar duzenlenip silinebiliyor
- Kategoriler eklenip arsivlenebiliyor
- Haftalik dashboard temel sayilari dogru veriyor
- Aylik kar-zarar ve kategori dagilimi gorunuyor
- Tekrarlayan giderler yaklasan odemelerde gorunuyor
- Reserve planner buyuk giderler icin haftalik ayirma onerisi uretiyor
- Offline kayit alip online olunca senkron olabiliyor
- Yeni cihazdan login yapinca veriler gorunuyor

## Sonraki Adim
1. Flutter proje iskeletini olusturmak.
2. Supabase migration ve seed akisini tamamlamak.
3. App shell + auth + ilk dashboard slice ile uygulamaya baslamak.
