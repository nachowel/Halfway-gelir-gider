import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../data/app_models.dart';
import '../features/expense_detail/domain/expense_detail_models.dart';
import '../features/income_detail/domain/income_detail_models.dart';
import '../features/net_profit_detail/domain/net_profit_detail_models.dart';
import 'app_locale.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final AppLocale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> globalDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? value = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    if (value == null) {
      throw StateError('AppLocalizations is not available in this context.');
    }
    return value;
  }

  String get appTitle => 'Gider';
  String get checkingSession => switch (locale) {
    AppLocale.en => 'Checking your session...',
    AppLocale.tr => 'Oturumunuz kontrol ediliyor...',
  };
  String get preparingBusinessSetup => switch (locale) {
    AppLocale.en => 'Preparing your business setup...',
    AppLocale.tr => 'Isletme kurulumu hazirlaniyor...',
  };
  String get bootstrapSettingsLoadError => switch (locale) {
    AppLocale.en => 'We could not load your business settings.',
    AppLocale.tr => 'Isletme ayarlariniz yuklenemedi.',
  };
  String get tryAgain => switch (locale) {
    AppLocale.en => 'Try again',
    AppLocale.tr => 'Tekrar dene',
  };
  String get today => switch (locale) {
    AppLocale.en => 'Today',
    AppLocale.tr => 'Bugun',
  };
  String get english => switch (locale) {
    AppLocale.en => 'English',
    AppLocale.tr => 'Ingilizce',
  };
  String get turkish => switch (locale) {
    AppLocale.en => 'Turkish',
    AppLocale.tr => 'Turkce',
  };
  String languageName(AppLocale value) => switch (value) {
    AppLocale.en => english,
    AppLocale.tr => turkish,
  };

  String get income => switch (locale) {
    AppLocale.en => 'Income',
    AppLocale.tr => 'Gelir',
  };
  String get incomes => switch (locale) {
    AppLocale.en => 'Income',
    AppLocale.tr => 'Gelir',
  };
  String get expense => switch (locale) {
    AppLocale.en => 'Expense',
    AppLocale.tr => 'Gider',
  };
  String get expenses => switch (locale) {
    AppLocale.en => 'Expenses',
    AppLocale.tr => 'Giderler',
  };
  String get netProfit => switch (locale) {
    AppLocale.en => 'Net profit',
    AppLocale.tr => 'Net kar',
  };
  String get netProfitLoss => switch (locale) {
    AppLocale.en => 'Net profit / loss',
    AppLocale.tr => 'Net kar / zarar',
  };
  String get reports => switch (locale) {
    AppLocale.en => 'Reports',
    AppLocale.tr => 'Raporlar',
  };
  String get settings => switch (locale) {
    AppLocale.en => 'Settings',
    AppLocale.tr => 'Ayarlar',
  };
  String get transactions => switch (locale) {
    AppLocale.en => 'Transactions',
    AppLocale.tr => 'Islemler',
  };
  String get dashboardSummary => switch (locale) {
    AppLocale.en => 'Summary',
    AppLocale.tr => 'Ozet',
  };
  String get addNew => switch (locale) {
    AppLocale.en => 'Add new',
    AppLocale.tr => 'Yeni ekle',
  };
  String get cancel => switch (locale) {
    AppLocale.en => 'Cancel',
    AppLocale.tr => 'Iptal',
  };
  String get close => switch (locale) {
    AppLocale.en => 'Close',
    AppLocale.tr => 'Kapat',
  };
  String get save => switch (locale) {
    AppLocale.en => 'Save',
    AppLocale.tr => 'Kaydet',
  };
  String get saveChanges => switch (locale) {
    AppLocale.en => 'Save changes',
    AppLocale.tr => 'Degisiklikleri kaydet',
  };
  String get delete => switch (locale) {
    AppLocale.en => 'Delete',
    AppLocale.tr => 'Sil',
  };
  String get remove => switch (locale) {
    AppLocale.en => 'Remove',
    AppLocale.tr => 'Kaldir',
  };
  String get newLabel => switch (locale) {
    AppLocale.en => 'New',
    AppLocale.tr => 'Yeni',
  };
  String get back => switch (locale) {
    AppLocale.en => 'Back',
    AppLocale.tr => 'Geri',
  };
  String get continueLabel => switch (locale) {
    AppLocale.en => 'Continue',
    AppLocale.tr => 'Devam et',
  };
  String get apply => switch (locale) {
    AppLocale.en => 'Apply',
    AppLocale.tr => 'Uygula',
  };
  String get reset => switch (locale) {
    AppLocale.en => 'Reset',
    AppLocale.tr => 'Sifirla',
  };
  String get clearAll => switch (locale) {
    AppLocale.en => 'Clear all',
    AppLocale.tr => 'Tumunu temizle',
  };
  String get any => switch (locale) {
    AppLocale.en => 'Any',
    AppLocale.tr => 'Hepsi',
  };
  String get anyTime => switch (locale) {
    AppLocale.en => 'Any time',
    AppLocale.tr => 'Tum zamanlar',
  };
  String get thisWeek => switch (locale) {
    AppLocale.en => 'This week',
    AppLocale.tr => 'Bu hafta',
  };
  String get lastWeek => switch (locale) {
    AppLocale.en => 'Last week',
    AppLocale.tr => 'Gecen hafta',
  };
  String get thisMonth => switch (locale) {
    AppLocale.en => 'This month',
    AppLocale.tr => 'Bu ay',
  };
  String get lastMonth => switch (locale) {
    AppLocale.en => 'Last month',
    AppLocale.tr => 'Gecen ay',
  };
  String get custom => switch (locale) {
    AppLocale.en => 'Custom',
    AppLocale.tr => 'Ozel',
  };
  String get last30Days => switch (locale) {
    AppLocale.en => 'Last 30 days',
    AppLocale.tr => 'Son 30 gun',
  };
  String get search => switch (locale) {
    AppLocale.en => 'Search',
    AppLocale.tr => 'Ara',
  };
  String get filter => switch (locale) {
    AppLocale.en => 'Filter',
    AppLocale.tr => 'Filtre',
  };
  String get active => switch (locale) {
    AppLocale.en => 'Active',
    AppLocale.tr => 'Aktif',
  };
  String get loading => switch (locale) {
    AppLocale.en => 'Loading...',
    AppLocale.tr => 'Yukleniyor...',
  };
  String get net => switch (locale) {
    AppLocale.en => 'Net',
    AppLocale.tr => 'Net',
  };
  String get noActivity => switch (locale) {
    AppLocale.en => 'No activity',
    AppLocale.tr => 'Hareket yok',
  };
  String get startRecordingMonth => switch (locale) {
    AppLocale.en => 'Start recording the month to assess business health.',
    AppLocale.tr =>
      'Isletme sagligini degerlendirmek icin ayi kaydetmeye baslayin.',
  };
  String get costsTooCloseToIncome => switch (locale) {
    AppLocale.en => 'Costs are pressing too close to income.',
    AppLocale.tr => 'Maliyetler gelire fazla yaklasiyor.',
  };
  String get monthPositiveButTight => switch (locale) {
    AppLocale.en => 'The month is positive but still tight.',
    AppLocale.tr => 'Ay pozitif ama hala sikisik.',
  };
  String get incomeAheadOfCosts => switch (locale) {
    AppLocale.en => 'Income is staying comfortably ahead of costs.',
    AppLocale.tr => 'Gelir maliyetlerin rahat sekilde onunde gidiyor.',
  };
  String get noActiveDay => switch (locale) {
    AppLocale.en => 'No active day',
    AppLocale.tr => 'Aktif gun yok',
  };
  String get selectedRange => switch (locale) {
    AppLocale.en => 'Selected range',
    AppLocale.tr => 'Secilen aralik',
  };
  String get activeDaysOnly => switch (locale) {
    AppLocale.en => 'Active days only',
    AppLocale.tr => 'Yalnizca aktif gunler',
  };
  String get acrossCalendarDays => switch (locale) {
    AppLocale.en => 'Across calendar days',
    AppLocale.tr => 'Takvim gunlerine gore',
  };
  String get acrossActiveDays => switch (locale) {
    AppLocale.en => 'Across active days',
    AppLocale.tr => 'Aktif gunlere gore',
  };
  String get selectedRangeIsEmpty => switch (locale) {
    AppLocale.en => 'Selected range is empty',
    AppLocale.tr => 'Secilen aralik bos',
  };
  String acrossDays(int count) => switch (locale) {
    AppLocale.en => 'Across $count days',
    AppLocale.tr => '$count gun boyunca',
  };
  String get checkConnectionAndTryAgain => switch (locale) {
    AppLocale.en => 'Check your connection and try again.',
    AppLocale.tr => 'Baglantinizi kontrol edip tekrar deneyin.',
  };
  String get uncategorized => switch (locale) {
    AppLocale.en => 'Uncategorized',
    AppLocale.tr => 'Kategorisiz',
  };

  String get signIn => switch (locale) {
    AppLocale.en => 'Sign in',
    AppLocale.tr => 'Giris yap',
  };
  String get useEmailOrGoogle => switch (locale) {
    AppLocale.en => 'Use your email or Google to get back to this week.',
    AppLocale.tr => 'Bu haftaya donmek icin e-posta veya Google kullanin.',
  };
  String get email => switch (locale) {
    AppLocale.en => 'Email',
    AppLocale.tr => 'E-posta',
  };
  String get password => switch (locale) {
    AppLocale.en => 'Password',
    AppLocale.tr => 'Sifre',
  };
  String get orContinueWith => switch (locale) {
    AppLocale.en => 'or continue with',
    AppLocale.tr => 'veya sunla devam et',
  };
  String get continueWithGoogle => switch (locale) {
    AppLocale.en => 'Continue with Google',
    AppLocale.tr => 'Google ile devam et',
  };
  String get dontHaveAccount => switch (locale) {
    AppLocale.en => 'Don’t have an account?',
    AppLocale.tr => 'Hesabiniz yok mu?',
  };
  String get createAccount => switch (locale) {
    AppLocale.en => 'Create account',
    AppLocale.tr => 'Hesap olustur',
  };
  String get createYourAccount => switch (locale) {
    AppLocale.en => 'Create your account',
    AppLocale.tr => 'Hesabinizi olusturun',
  };
  String get setupBusinessAndTrack => switch (locale) {
    AppLocale.en => 'Set up your business and start tracking.',
    AppLocale.tr => 'Isletmenizi kurun ve takibe baslayin.',
  };
  String get businessName => switch (locale) {
    AppLocale.en => 'Business name',
    AppLocale.tr => 'Isletme adi',
  };
  String get shownOnDashboard => switch (locale) {
    AppLocale.en => 'Shown on your dashboard and in settings.',
    AppLocale.tr => 'Panelinizde ve ayarlarda gosterilir.',
  };
  String get enterBusinessName => switch (locale) {
    AppLocale.en => 'Enter your business name.',
    AppLocale.tr => 'Isletme adinizi girin.',
  };
  String get enterValidEmail => switch (locale) {
    AppLocale.en => 'Enter a valid email.',
    AppLocale.tr => 'Gecerli bir e-posta girin.',
  };
  String get passwordMinLength => switch (locale) {
    AppLocale.en => 'Password must be at least 6 characters.',
    AppLocale.tr => 'Sifre en az 6 karakter olmali.',
  };
  String get backToLogin => back;
  String get accountCreatedSignIn => switch (locale) {
    AppLocale.en => 'Account created. You can sign in now.',
    AppLocale.tr => 'Hesap olusturuldu. Simdi giris yapabilirsiniz.',
  };
  String get noInternetTryAgain => switch (locale) {
    AppLocale.en => 'No internet connection. Please try again.',
    AppLocale.tr => 'Internet baglantisi yok. Lutfen tekrar deneyin.',
  };
  String get genericErrorTryAgain => switch (locale) {
    AppLocale.en => 'Something went wrong. Please try again.',
    AppLocale.tr => 'Bir seyler ters gitti. Lutfen tekrar deneyin.',
  };

  String get setup => switch (locale) {
    AppLocale.en => 'Setup',
    AppLocale.tr => 'Kurulum',
  };
  String get finishBusinessSetup => switch (locale) {
    AppLocale.en => 'Finish your business setup',
    AppLocale.tr => 'Isletme kurulumunuzu tamamlayin',
  };
  String get ukDefaultsSetupCopy => switch (locale) {
    AppLocale.en =>
      'We lock the app to UK defaults. Add your business name once and continue.',
    AppLocale.tr =>
      'Uygulamayi BK varsayilanlarina sabitliyoruz. Isletme adinizi bir kez ekleyip devam edin.',
  };
  String get businessDefaults => switch (locale) {
    AppLocale.en => 'Business defaults',
    AppLocale.tr => 'Isletme varsayilanlari',
  };
  String get currency => switch (locale) {
    AppLocale.en => 'Currency',
    AppLocale.tr => 'Para birimi',
  };
  String get timezone => switch (locale) {
    AppLocale.en => 'Timezone',
    AppLocale.tr => 'Saat dilimi',
  };
  String get weekStarts => switch (locale) {
    AppLocale.en => 'Week starts',
    AppLocale.tr => 'Hafta baslangici',
  };
  String get monday => switch (locale) {
    AppLocale.en => 'Monday',
    AppLocale.tr => 'Pazartesi',
  };
  String get customWeekStart => switch (locale) {
    AppLocale.en => 'Custom',
    AppLocale.tr => 'Ozel',
  };
  String get continueToApp => continueLabel;
  String get onboardingLoadError => switch (locale) {
    AppLocale.en => 'We could not load your setup.',
    AppLocale.tr => 'Kurulumunuz yuklenemedi.',
  };

  String get preferencesAccount => switch (locale) {
    AppLocale.en => 'Preferences & account',
    AppLocale.tr => 'Tercihler ve hesap',
  };
  String get preferences => switch (locale) {
    AppLocale.en => 'Preferences',
    AppLocale.tr => 'Tercihler',
  };
  String get language => switch (locale) {
    AppLocale.en => 'Language',
    AppLocale.tr => 'Dil',
  };
  String get chooseLanguage => switch (locale) {
    AppLocale.en => 'Choose language',
    AppLocale.tr => 'Dil secin',
  };
  String get languageAppliesImmediately => switch (locale) {
    AppLocale.en => 'Changes apply instantly across the app.',
    AppLocale.tr => 'Degisiklikler uygulamanin tamamina aninda uygulanir.',
  };
  String get data => switch (locale) {
    AppLocale.en => 'Data',
    AppLocale.tr => 'Veri',
  };
  String get categories => switch (locale) {
    AppLocale.en => 'Categories',
    AppLocale.tr => 'Kategoriler',
  };
  String get recurringExpenses => switch (locale) {
    AppLocale.en => 'Recurring expenses',
    AppLocale.tr => 'Tekrarlayan giderler',
  };
  String get security => switch (locale) {
    AppLocale.en => 'Security',
    AppLocale.tr => 'Guvenlik',
  };
  String get signOut => switch (locale) {
    AppLocale.en => 'Sign out',
    AppLocale.tr => 'Cikis yap',
  };
  String get signOutDeviceQuestion => switch (locale) {
    AppLocale.en => 'Sign out of this device?',
    AppLocale.tr => 'Bu cihazda cikis yapilsin mi?',
  };
  String get signOutDeviceBody => switch (locale) {
    AppLocale.en =>
      'This closes the current session and returns to the auth flow.',
    AppLocale.tr =>
      'Bu islem mevcut oturumu kapatir ve giris akisina geri dondurur.',
  };
  String get profile => switch (locale) {
    AppLocale.en => 'Profile',
    AppLocale.tr => 'Profil',
  };
  String get updateBusinessName => switch (locale) {
    AppLocale.en => 'Update business name',
    AppLocale.tr => 'Isletme adini guncelle',
  };
  String get businessNameCannotBeEmpty => switch (locale) {
    AppLocale.en => 'Business name cannot be empty.',
    AppLocale.tr => 'Isletme adi bos olamaz.',
  };
  String get versionPrivate => 'gider · v1.0 · private';
  String get settingsLoadError => switch (locale) {
    AppLocale.en => 'We could not load your settings.',
    AppLocale.tr => 'Ayarlariniz yuklenemedi.',
  };

  String get whatDidYouJustDo => switch (locale) {
    AppLocale.en => 'What did you just do?',
    AppLocale.tr => 'Az once ne yaptiniz?',
  };
  String get addIncome => switch (locale) {
    AppLocale.en => 'Add income',
    AppLocale.tr => 'Gelir ekle',
  };
  String get addExpense => switch (locale) {
    AppLocale.en => 'Add expense',
    AppLocale.tr => 'Gider ekle',
  };
  String get addRecurringExpense => switch (locale) {
    AppLocale.en => 'Recurring expense',
    AppLocale.tr => 'Tekrarlayan gider',
  };
  String get addIncomeMeta => switch (locale) {
    AppLocale.en => 'Income · sale, payout, transfer',
    AppLocale.tr => 'Gelir · satis, odeme, transfer',
  };
  String get addExpenseMeta => switch (locale) {
    AppLocale.en => 'Expense · supplies, fuel, food',
    AppLocale.tr => 'Gider · malzeme, yakit, gida',
  };
  String get addRecurringMeta => switch (locale) {
    AppLocale.en => 'Recurring · rent, bills, insurance',
    AppLocale.tr => 'Tekrarlayan · kira, faturalar, sigorta',
  };
  String get reservePlanner => switch (locale) {
    AppLocale.en => 'Reserve planner',
    AppLocale.tr => 'Rezerv planlayici',
  };
  String get noRecurringBillsIncludedYet => switch (locale) {
    AppLocale.en => 'No recurring bills are included yet.',
    AppLocale.tr => 'Henuz dahil edilen tekrarlayan fatura yok.',
  };
  String get reservePlannerSuggestion => switch (locale) {
    AppLocale.en =>
      'Suggested amount to set aside this week for reserve-enabled recurring bills.',
    AppLocale.tr =>
      'Rezervi acik tekrarlayan faturalar icin bu hafta kenara ayrilmasi onerilen tutar.',
  };
  String get dueNow => switch (locale) {
    AppLocale.en => 'Due now',
    AppLocale.tr => 'Vadesi geldi',
  };
  String get dueThisWeek => switch (locale) {
    AppLocale.en => 'Due this week',
    AppLocale.tr => 'Bu hafta vadesi var',
  };
  String dueInWeeks(int weeks) => switch (locale) {
    AppLocale.en => 'Due in ${weeks}w',
    AppLocale.tr => '$weeks hf sonra',
  };

  String get thisWeekHeadline => switch (locale) {
    AppLocale.en => 'This week',
    AppLocale.tr => 'Bu hafta',
  };
  String get vsLastWeek => switch (locale) {
    AppLocale.en => 'vs last week',
    AppLocale.tr => 'gecen haftaya gore',
  };
  String get vsLastWeekDown => switch (locale) {
    AppLocale.en => 'vs last week ▼',
    AppLocale.tr => 'gecen haftaya gore ▼',
  };
  String get bankTransferIncluded => switch (locale) {
    AppLocale.en => 'Bank transfer income is included in total income',
    AppLocale.tr => 'Banka transferi geliri toplam gelire dahildir',
  };
  String get upcoming => switch (locale) {
    AppLocale.en => 'Upcoming',
    AppLocale.tr => 'Yaklasanlar',
  };
  String get seeAll => switch (locale) {
    AppLocale.en => 'See all',
    AppLocale.tr => 'Tumunu gor',
  };
  String get noUpcomingPayments => switch (locale) {
    AppLocale.en => 'No upcoming payments',
    AppLocale.tr => 'Yaklasan odeme yok',
  };
  String get recurringPreviewMessage => switch (locale) {
    AppLocale.en => 'Recurring bills and reminders will preview here.',
    AppLocale.tr => 'Tekrarlayan faturalar ve hatirlatmalar burada gorunur.',
  };
  String get recent => switch (locale) {
    AppLocale.en => 'Recent',
    AppLocale.tr => 'Son Islemler',
  };
  String get noRecentTransactions => switch (locale) {
    AppLocale.en => 'No recent transactions',
    AppLocale.tr => 'Son islem yok',
  };
  String get recentTransactionsPreview => switch (locale) {
    AppLocale.en => 'Your latest income and expenses will preview here.',
    AppLocale.tr => 'Son gelir ve giderleriniz burada gorunur.',
  };
  String get dashboardLoadError => switch (locale) {
    AppLocale.en => 'Couldn’t load dashboard',
    AppLocale.tr => 'Panel yuklenemedi',
  };

  String get allItems => switch (locale) {
    AppLocale.en => 'All items',
    AppLocale.tr => 'Tum kayitlar',
  };
  String get all => switch (locale) {
    AppLocale.en => 'All',
    AppLocale.tr => 'Tum',
  };
  String get card => switch (locale) {
    AppLocale.en => 'Card',
    AppLocale.tr => 'Kart',
  };
  String get cash => switch (locale) {
    AppLocale.en => 'Cash',
    AppLocale.tr => 'Nakit',
  };
  String get searchTransactionsHint => switch (locale) {
    AppLocale.en => 'Search category, note, platform or payment',
    AppLocale.tr => 'Kategori, not, platform veya odeme ara',
  };
  String searchFilterLabel(String value) => switch (locale) {
    AppLocale.en => 'Search: $value',
    AppLocale.tr => 'Arama: $value',
  };
  String get filters => switch (locale) {
    AppLocale.en => 'Filters',
    AppLocale.tr => 'Filtreler',
  };
  String get refineTransactions => switch (locale) {
    AppLocale.en => 'Refine transactions',
    AppLocale.tr => 'Islemleri daralt',
  };
  String get period => switch (locale) {
    AppLocale.en => 'Period',
    AppLocale.tr => 'Donem',
  };
  String get type => switch (locale) {
    AppLocale.en => 'Type',
    AppLocale.tr => 'Tur',
  };
  String get payment => switch (locale) {
    AppLocale.en => 'Payment',
    AppLocale.tr => 'Odeme',
  };
  String get platform => switch (locale) {
    AppLocale.en => 'Platform',
    AppLocale.tr => 'Platform',
  };
  String get noTransactionsYet => switch (locale) {
    AppLocale.en => 'No transactions yet',
    AppLocale.tr => 'Henuz islem yok',
  };
  String get transactionsAppearHere => switch (locale) {
    AppLocale.en => 'Transactions you add will appear here.',
    AppLocale.tr => 'Eklediginiz islemler burada gorunur.',
  };
  String get noMatchingTransactions => switch (locale) {
    AppLocale.en => 'No matching transactions',
    AppLocale.tr => 'Eslesen islem yok',
  };
  String get tryDifferentSearch => switch (locale) {
    AppLocale.en => 'Try a different search or clear your filters.',
    AppLocale.tr => 'Farkli bir arama deneyin veya filtreleri temizleyin.',
  };
  String get clearFilters => switch (locale) {
    AppLocale.en => 'Clear filters',
    AppLocale.tr => 'Filtreleri temizle',
  };
  String get transactionsLoadError => switch (locale) {
    AppLocale.en => 'Couldn’t load transactions',
    AppLocale.tr => 'Islemler yuklenemedi',
  };
  String entriesCount(int count) => switch (locale) {
    AppLocale.en => '$count entries',
    AppLocale.tr => '$count kayit',
  };
  String txCount(int count) => switch (locale) {
    AppLocale.en => '$count tx',
    AppLocale.tr => '$count islem',
  };
  String daysCount(int count) => switch (locale) {
    AppLocale.en => '$count days',
    AppLocale.tr => '$count gun',
  };
  String ofTotal(int percent) => switch (locale) {
    AppLocale.en => '$percent% of total',
    AppLocale.tr => 'Toplamin %$percent’i',
  };

  String get selectMonth => switch (locale) {
    AppLocale.en => 'Select month',
    AppLocale.tr => 'Ay sec',
  };
  String get monthlyOverview => switch (locale) {
    AppLocale.en => 'Monthly overview',
    AppLocale.tr => 'Aylik genel gorunum',
  };
  String get monthlyProfitLoss => switch (locale) {
    AppLocale.en => 'Monthly profit & loss',
    AppLocale.tr => 'Aylik kar ve zarar',
  };
  String get topInsights => switch (locale) {
    AppLocale.en => 'Top insights',
    AppLocale.tr => 'One cikan icgoruler',
  };
  String get categoryExpenses => switch (locale) {
    AppLocale.en => 'Category · expenses',
    AppLocale.tr => 'Kategori · giderler',
  };
  String get monthlyTrend => switch (locale) {
    AppLocale.en => 'Monthly trend',
    AppLocale.tr => 'Aylik egilim',
  };
  String get dailySummary => switch (locale) {
    AppLocale.en => 'Daily summary',
    AppLocale.tr => 'Gunluk ozet',
  };
  String get incomeUpper => switch (locale) {
    AppLocale.en => 'INCOME',
    AppLocale.tr => 'GELIR',
  };
  String get expensesUpper => switch (locale) {
    AppLocale.en => 'EXPENSES',
    AppLocale.tr => 'GIDERLER',
  };
  String get vsLastMonth => switch (locale) {
    AppLocale.en => 'VS LAST MONTH',
    AppLocale.tr => 'GECEN AYA GORE',
  };
  String get profitMargin => switch (locale) {
    AppLocale.en => 'Profit margin',
    AppLocale.tr => 'Kar marji',
  };
  String get expenseRatio => switch (locale) {
    AppLocale.en => 'Expense ratio',
    AppLocale.tr => 'Gider orani',
  };
  String get inShort => switch (locale) {
    AppLocale.en => 'In',
    AppLocale.tr => 'Gel',
  };
  String get outShort => switch (locale) {
    AppLocale.en => 'Out',
    AppLocale.tr => 'Cik',
  };
  String get bestDay => switch (locale) {
    AppLocale.en => 'Best day',
    AppLocale.tr => 'En iyi gun',
  };
  String get worstDay => switch (locale) {
    AppLocale.en => 'Worst day',
    AppLocale.tr => 'En kotu gun',
  };
  String get averageDailyNet => switch (locale) {
    AppLocale.en => 'Average daily net',
    AppLocale.tr => 'Ortalama gunluk net',
  };
  String get noExpenseCategoriesYet => switch (locale) {
    AppLocale.en => 'No expense categories yet this month',
    AppLocale.tr => 'Bu ay henuz gider kategorisi yok',
  };
  String get topExpense => switch (locale) {
    AppLocale.en => 'Top expense',
    AppLocale.tr => 'En buyuk gider',
  };
  String get noExpenseYet => switch (locale) {
    AppLocale.en => 'No expense yet',
    AppLocale.tr => 'Henuz gider yok',
  };
  String get noCategoriesThisMonth => switch (locale) {
    AppLocale.en => 'No categories this month',
    AppLocale.tr => 'Bu ay kategori yok',
  };
  String get topIncomeStream => switch (locale) {
    AppLocale.en => 'Top income stream',
    AppLocale.tr => 'En buyuk gelir kanali',
  };
  String get highestExpenseDay => switch (locale) {
    AppLocale.en => 'Highest expense day',
    AppLocale.tr => 'En yuksek gider gunu',
  };
  String get noExpenseDaysThisMonth => switch (locale) {
    AppLocale.en => 'No expense days this month',
    AppLocale.tr => 'Bu ay gider gunu yok',
  };
  String get netDayRange => switch (locale) {
    AppLocale.en => 'Net day range',
    AppLocale.tr => 'Net gun araligi',
  };
  String get noNetDayYet => switch (locale) {
    AppLocale.en => 'No net day yet',
    AppLocale.tr => 'Henuz net gun yok',
  };
  String get activeDaysAppearOnceEntriesAdded => switch (locale) {
    AppLocale.en => 'Active days appear once entries are added',
    AppLocale.tr => 'Kayitlar eklendikce aktif gunler gorunur',
  };
  String bestWorstRangePrimary(String day, String amount) => switch (locale) {
    AppLocale.en => 'Best $day $amount',
    AppLocale.tr => 'En iyi $day $amount',
  };
  String bestWorstRangeSecondary(String day, String amount) => switch (locale) {
    AppLocale.en => 'Worst $day $amount',
    AppLocale.tr => 'En kotu $day $amount',
  };
  String get addExpensesForPressure => switch (locale) {
    AppLocale.en => 'Add expenses to see where cost pressure is building.',
    AppLocale.tr =>
      'Maliyet baskisinin nerede arttigini gormek icin gider ekleyin.',
  };
  String get noMonthlyTrendYet => switch (locale) {
    AppLocale.en => 'No monthly trend yet',
    AppLocale.tr => 'Henuz aylik egilim yok',
  };
  String get recentMonthsAppear => switch (locale) {
    AppLocale.en => 'Recent months will appear here once entries are recorded.',
    AppLocale.tr => 'Kayitlar eklendikce son aylar burada gorunur.',
  };
  String get reportsLoadError => switch (locale) {
    AppLocale.en => 'Couldn’t load reports',
    AppLocale.tr => 'Raporlar yuklenemedi',
  };

  String get noCategoriesYet => switch (locale) {
    AppLocale.en => 'No categories yet',
    AppLocale.tr => 'Henuz kategori yok',
  };
  String createFirstCategory(String typeLabel) => switch (locale) {
    AppLocale.en =>
      'Create your first ${typeLabel.toLowerCase()} category for this business.',
    AppLocale.tr =>
      'Bu isletme icin ilk ${typeLabel.toLowerCase()} kategorinizi olusturun.',
  };
  String get createCategory => switch (locale) {
    AppLocale.en => 'Create category',
    AppLocale.tr => 'Kategori olustur',
  };
  String categoriesLoadError(String what) => switch (locale) {
    AppLocale.en => 'We could not load $what.',
    AppLocale.tr => '$what yuklenemedi.',
  };
  String get manageExpenseIncomeTags => switch (locale) {
    AppLocale.en => 'Manage expense and income tags',
    AppLocale.tr => 'Gelir ve gider etiketlerini yonetin',
  };
  String get editCategory => switch (locale) {
    AppLocale.en => 'Edit category',
    AppLocale.tr => 'Kategoriyi duzenle',
  };
  String get newCategory => switch (locale) {
    AppLocale.en => 'New category',
    AppLocale.tr => 'Yeni kategori',
  };
  String renameCategory(String typeLabel) => switch (locale) {
    AppLocale.en => 'Rename $typeLabel category',
    AppLocale.tr =>
      '${typeLabel[0].toUpperCase()}${typeLabel.substring(1)} kategorisini yeniden adlandir',
  };
  String createTypeCategory(String typeLabel) => switch (locale) {
    AppLocale.en => 'Create $typeLabel category',
    AppLocale.tr =>
      '${typeLabel[0].toUpperCase()}${typeLabel.substring(1)} kategorisi olustur',
  };
  String get name => switch (locale) {
    AppLocale.en => 'Name',
    AppLocale.tr => 'Ad',
  };
  String get packagingHint => switch (locale) {
    AppLocale.en => 'e.g. Packaging',
    AppLocale.tr => 'or. Ambalaj',
  };
  String get cardSalesHint => switch (locale) {
    AppLocale.en => 'e.g. Card Sales',
    AppLocale.tr => 'or. Kart Satislari',
  };
  String get newCategoryAppearsImmediately => switch (locale) {
    AppLocale.en => 'New categories appear immediately in the management list.',
    AppLocale.tr => 'Yeni kategoriler yonetim listesinde hemen gorunur.',
  };
  String get archiveCategory => switch (locale) {
    AppLocale.en => 'Archive category',
    AppLocale.tr => 'Kategoriyi arsivle',
  };
  String get saveCategory => switch (locale) {
    AppLocale.en => 'Save category',
    AppLocale.tr => 'Kategoriyi kaydet',
  };
  String get categoryNameCannotBeEmpty => switch (locale) {
    AppLocale.en => 'Category name cannot be empty.',
    AppLocale.tr => 'Kategori adi bos olamaz.',
  };

  String get monthly => switch (locale) {
    AppLocale.en => 'Monthly',
    AppLocale.tr => 'Aylik',
  };
  String get recurring => switch (locale) {
    AppLocale.en => 'Recurring',
    AppLocale.tr => 'Tekrarlayan',
  };
  String get noRecurringExpenses => switch (locale) {
    AppLocale.en => 'No recurring expenses',
    AppLocale.tr => 'Tekrarlayan gider yok',
  };
  String get tapPlusToAddFirstRecurring => switch (locale) {
    AppLocale.en => 'Tap + to add your first one.',
    AppLocale.tr => 'Ilkini eklemek icin + dugmesine dokunun.',
  };
  String get recurringLoadError => switch (locale) {
    AppLocale.en => 'Couldn’t load recurring expenses',
    AppLocale.tr => 'Tekrarlayan giderler yuklenemedi',
  };
  String paidAmountLabel(String amount) => switch (locale) {
    AppLocale.en => '$amount paid',
    AppLocale.tr => '$amount odendi',
  };
  String remainingAmountLabel(String amount) => switch (locale) {
    AppLocale.en => '$amount remaining',
    AppLocale.tr => '$amount kaldi',
  };
  String get confirmPayment => switch (locale) {
    AppLocale.en => 'Confirm payment',
    AppLocale.tr => 'Odemeyi onayla',
  };
  String markAsPaidQuestion(String title) => switch (locale) {
    AppLocale.en => 'Mark $title as paid?',
    AppLocale.tr => '$title odendi olarak isaretlensin mi?',
  };
  String get dueOn => switch (locale) {
    AppLocale.en => 'Due on',
    AppLocale.tr => 'Vade',
  };
  String get nextDue => switch (locale) {
    AppLocale.en => 'Next due',
    AppLocale.tr => 'Sonraki vade',
  };
  String get paidOn => switch (locale) {
    AppLocale.en => 'Paid on',
    AppLocale.tr => 'Odeme tarihi',
  };
  String get amount => switch (locale) {
    AppLocale.en => 'Amount',
    AppLocale.tr => 'Tutar',
  };
  String plannedAmountHelper(String amount) => switch (locale) {
    AppLocale.en => 'Planned amount: $amount',
    AppLocale.tr => 'Planlanan tutar: $amount',
  };
  String get paymentMethod => switch (locale) {
    AppLocale.en => 'Payment method',
    AppLocale.tr => 'Odeme yontemi',
  };
  String paymentContinueMessage(String date) => switch (locale) {
    AppLocale.en => 'This logs as an expense and sets next due to $date.',
    AppLocale.tr =>
      'Bu islem gider olarak kaydedilir ve sonraki vade $date olur.',
  };
  String get later => switch (locale) {
    AppLocale.en => 'Later',
    AppLocale.tr => 'Daha sonra',
  };
  String get saving => switch (locale) {
    AppLocale.en => 'Saving...',
    AppLocale.tr => 'Kaydediliyor...',
  };
  String get saved => switch (locale) {
    AppLocale.en => 'Saved ✓',
    AppLocale.tr => 'Kaydedildi ✓',
  };
  String get retrySave => switch (locale) {
    AppLocale.en => 'Retry save',
    AppLocale.tr => 'Tekrar kaydet',
  };
  String get markPaid => switch (locale) {
    AppLocale.en => 'Mark paid',
    AppLocale.tr => 'Odendi isaretle',
  };
  String get choosePaymentMethodToContinue => switch (locale) {
    AppLocale.en => 'Choose a payment method to continue.',
    AppLocale.tr => 'Devam etmek icin bir odeme yontemi secin.',
  };
  String recordedPaymentMessage(String amount) => switch (locale) {
    AppLocale.en => '$amount payment recorded',
    AppLocale.tr => '$amount odeme kaydedildi',
  };
  String get paymentRecordFailed => switch (locale) {
    AppLocale.en => 'Payment could not be recorded. Try again.',
    AppLocale.tr => 'Odeme kaydedilemedi. Tekrar deneyin.',
  };
  String get amountMustBeGreaterThanZero => switch (locale) {
    AppLocale.en => 'Amount must be greater than £0.00',
    AppLocale.tr => 'Tutar £0.00’dan buyuk olmali',
  };
  String get editRecurring => switch (locale) {
    AppLocale.en => 'Edit recurring',
    AppLocale.tr => 'Tekrarlayani duzenle',
  };
  String get newRecurringExpense => switch (locale) {
    AppLocale.en => 'New recurring expense',
    AppLocale.tr => 'Yeni tekrarlayan gider',
  };
  String get frequency => switch (locale) {
    AppLocale.en => 'Frequency',
    AppLocale.tr => 'Siklik',
  };
  String get nextDueLabel => switch (locale) {
    AppLocale.en => 'Next due',
    AppLocale.tr => 'Sonraki vade',
  };
  String get loadingCategories => switch (locale) {
    AppLocale.en => 'Loading categories...',
    AppLocale.tr => 'Kategoriler yukleniyor...',
  };
  String get includeInReservePlanner => switch (locale) {
    AppLocale.en => 'Include in reserve planner',
    AppLocale.tr => 'Rezerv planlayiciya dahil et',
  };
  String get reservePlannerHelper => switch (locale) {
    AppLocale.en => 'Show a weekly set-aside suggestion on the dashboard.',
    AppLocale.tr => 'Panelde haftalik kenara ayirma onerisi goster.',
  };
  String get addRecurring => switch (locale) {
    AppLocale.en => 'Add recurring',
    AppLocale.tr => 'Tekrarlayani ekle',
  };
  String get enterName => switch (locale) {
    AppLocale.en => 'Enter a name.',
    AppLocale.tr => 'Bir ad girin.',
  };
  String get enterAmountGreaterThanZero => switch (locale) {
    AppLocale.en => 'Enter an amount greater than £0.',
    AppLocale.tr => '£0’dan buyuk bir tutar girin.',
  };
  String get chooseCategory => switch (locale) {
    AppLocale.en => 'Choose a category.',
    AppLocale.tr => 'Bir kategori secin.',
  };
  String get couldNotSaveTryAgain => switch (locale) {
    AppLocale.en => 'Could not save. Try again.',
    AppLocale.tr => 'Kaydedilemedi. Tekrar deneyin.',
  };
  String get couldNotRemoveTryAgain => switch (locale) {
    AppLocale.en => 'Could not remove. Try again.',
    AppLocale.tr => 'Kaldirilamadi. Tekrar deneyin.',
  };
  String get recurringNameHint => switch (locale) {
    AppLocale.en => 'Rent, Gas bill...',
    AppLocale.tr => 'Kira, Dogalgaz faturasi...',
  };

  String get incomeDetail => switch (locale) {
    AppLocale.en => 'Income detail',
    AppLocale.tr => 'Gelir detayi',
  };
  String get highestDay => switch (locale) {
    AppLocale.en => 'Highest day',
    AppLocale.tr => 'En yuksek gun',
  };
  String get noIncomeYet => switch (locale) {
    AppLocale.en => 'No income yet',
    AppLocale.tr => 'Henuz gelir yok',
  };
  String get averagePerDay => switch (locale) {
    AppLocale.en => 'Average per day',
    AppLocale.tr => 'Gunluk ortalama',
  };
  String get bestMixCash => switch (locale) {
    AppLocale.en => 'Best mix (cash)',
    AppLocale.tr => 'En iyi dagilim (nakit)',
  };
  String get noPaymentMixYet => switch (locale) {
    AppLocale.en => 'No payment mix yet',
    AppLocale.tr => 'Henuz odeme dagilimi yok',
  };
  String get noIncomeDaysInRange => switch (locale) {
    AppLocale.en => 'No income days in range',
    AppLocale.tr => 'Aralikta gelir gunu yok',
  };
  String cashPercent(int percent) => switch (locale) {
    AppLocale.en => '$percent% cash',
    AppLocale.tr => '%$percent nakit',
  };
  String get incomeDetailInfo => switch (locale) {
    AppLocale.en =>
      'Shows cash and card income only for the selected range. Weeks always run Monday to Sunday.',
    AppLocale.tr =>
      'Secilen aralik icin yalnizca nakit ve kart gelirlerini gosterir. Haftalar her zaman Pazartesi ile Pazar arasindadir.',
  };
  String get selectIncomeRange => switch (locale) {
    AppLocale.en => 'Select income range',
    AppLocale.tr => 'Gelir araligini sec',
  };
  String get totalIncome => switch (locale) {
    AppLocale.en => 'Total income',
    AppLocale.tr => 'Toplam gelir',
  };
  String get cashShare => switch (locale) {
    AppLocale.en => 'Cash share',
    AppLocale.tr => 'Nakit payi',
  };
  String get cardShare => switch (locale) {
    AppLocale.en => 'Card share',
    AppLocale.tr => 'Kart payi',
  };
  String get incomeByDay => switch (locale) {
    AppLocale.en => 'Income by day',
    AppLocale.tr => 'Gune gore gelir',
  };
  String get noIncomeRecordsInRange => switch (locale) {
    AppLocale.en => 'No income records in this range',
    AppLocale.tr => 'Bu aralikta gelir kaydi yok',
  };
  String get incomeChartEmpty => switch (locale) {
    AppLocale.en =>
      'The chart will populate once cash or card income lands in the selected dates.',
    AppLocale.tr =>
      'Secilen tarihlerde nakit veya kart geliri oldugunda grafik dolar.',
  };
  String get breakdown => switch (locale) {
    AppLocale.en => 'Breakdown',
    AppLocale.tr => 'Dagilim',
  };
  String cashAmount(String amount) => switch (locale) {
    AppLocale.en => 'Cash $amount',
    AppLocale.tr => 'Nakit $amount',
  };
  String cardAmount(String amount) => switch (locale) {
    AppLocale.en => 'Card $amount',
    AppLocale.tr => 'Kart $amount',
  };
  String get incomeDetailLoadError => switch (locale) {
    AppLocale.en => 'Couldn’t load income detail',
    AppLocale.tr => 'Gelir detayi yuklenemedi',
  };

  String get expenseDetail => switch (locale) {
    AppLocale.en => 'Expense detail',
    AppLocale.tr => 'Gider detayi',
  };
  String get expenseDetailInfo => switch (locale) {
    AppLocale.en =>
      'Shows expense activity only for the selected range. Weeks always run Monday to Sunday.',
    AppLocale.tr =>
      'Secilen aralik icin yalnizca gider hareketlerini gosterir. Haftalar her zaman Pazartesi ile Pazar arasindadir.',
  };
  String get selectExpenseRange => switch (locale) {
    AppLocale.en => 'Select expense range',
    AppLocale.tr => 'Gider araligini sec',
  };
  String get totalExpenses => switch (locale) {
    AppLocale.en => 'Total expenses',
    AppLocale.tr => 'Toplam gider',
  };
  String get highestCategory => switch (locale) {
    AppLocale.en => 'Highest category',
    AppLocale.tr => 'En yuksek kategori',
  };
  String get largestDay => switch (locale) {
    AppLocale.en => 'Largest day',
    AppLocale.tr => 'En buyuk gun',
  };
  String get noCategoryYet => switch (locale) {
    AppLocale.en => 'No category yet',
    AppLocale.tr => 'Henuz kategori yok',
  };
  String get noSpendYet => switch (locale) {
    AppLocale.en => 'No spend yet',
    AppLocale.tr => 'Henuz harcama yok',
  };
  String get noSecondCategory => switch (locale) {
    AppLocale.en => 'No second category',
    AppLocale.tr => 'Ikinci kategori yok',
  };
  String get highestSpendDay => switch (locale) {
    AppLocale.en => 'Highest spend day',
    AppLocale.tr => 'En yuksek harcama gunu',
  };
  String get topCategory => switch (locale) {
    AppLocale.en => 'Top category',
    AppLocale.tr => 'One cikan kategori',
  };
  String get noExpensesInRange => switch (locale) {
    AppLocale.en => 'No expenses in range',
    AppLocale.tr => 'Aralikta gider yok',
  };
  String get mostSpendingOneCategory => switch (locale) {
    AppLocale.en => 'Most spending is concentrated in one category.',
    AppLocale.tr => 'Harcamalarin cogu tek bir kategoride toplaniyor.',
  };
  String get expensesByDay => switch (locale) {
    AppLocale.en => 'Expenses by day',
    AppLocale.tr => 'Gune gore giderler',
  };
  String get totalExpensesLegend => switch (locale) {
    AppLocale.en => 'Total expenses',
    AppLocale.tr => 'Toplam gider',
  };
  String get categoryBreakdown => switch (locale) {
    AppLocale.en => 'Category breakdown',
    AppLocale.tr => 'Kategori dagilimi',
  };
  String get noExpenseCategoriesRange => switch (locale) {
    AppLocale.en => 'No expense categories in this range',
    AppLocale.tr => 'Bu aralikta gider kategorisi yok',
  };
  String get categoriesAppearInRange => switch (locale) {
    AppLocale.en =>
      'Categories will appear here once expenses are recorded in the selected dates.',
    AppLocale.tr =>
      'Secilen tarihlerde gider kaydedildiginde kategoriler burada gorunur.',
  };
  String get dailyBreakdown => switch (locale) {
    AppLocale.en => 'Daily breakdown',
    AppLocale.tr => 'Gunluk dagilim',
  };
  String get noExpenses => switch (locale) {
    AppLocale.en => 'No expenses',
    AppLocale.tr => 'Gider yok',
  };
  String get spendingPressure => switch (locale) {
    AppLocale.en => 'Spending pressure',
    AppLocale.tr => 'Harcama baskisi',
  };
  String get noExpenseRecordsInRange => switch (locale) {
    AppLocale.en => 'No expense records in this range',
    AppLocale.tr => 'Bu aralikta gider kaydi yok',
  };
  String get expenseChartEmpty => switch (locale) {
    AppLocale.en =>
      'The chart will populate once expenses land in the selected dates.',
    AppLocale.tr => 'Secilen tarihlerde gider kaydi oldugunda grafik dolar.',
  };
  String get expenseDetailLoadError => switch (locale) {
    AppLocale.en => 'Couldn’t load expense detail',
    AppLocale.tr => 'Gider detayi yuklenemedi',
  };

  String get netProfitDetail => switch (locale) {
    AppLocale.en => 'Net profit detail',
    AppLocale.tr => 'Net kar detayi',
  };
  String get netProfitDetailInfo => switch (locale) {
    AppLocale.en =>
      'Net profit is derived from income minus expenses. This view explains where profit is strengthening or slipping across the selected range.',
    AppLocale.tr =>
      'Net kar gelir eksi gider olarak hesaplanir. Bu gorunum secilen aralikta karin nerede guclendigini veya zayifladigini aciklar.',
  };
  String get selectNetProfitRange => switch (locale) {
    AppLocale.en => 'Select net profit range',
    AppLocale.tr => 'Net kar araligini sec',
  };
  String get noMarginYet => switch (locale) {
    AppLocale.en => 'No margin yet',
    AppLocale.tr => 'Henuz marj yok',
  };
  String get marginAppearsWithIncome => switch (locale) {
    AppLocale.en => 'Profit margin appears once income is recorded.',
    AppLocale.tr => 'Kar marji gelir kaydedildiginde gorunur.',
  };
  String get weak => switch (locale) {
    AppLocale.en => 'Weak',
    AppLocale.tr => 'Zayif',
  };
  String get moderate => switch (locale) {
    AppLocale.en => 'Moderate',
    AppLocale.tr => 'Orta',
  };
  String get strong => switch (locale) {
    AppLocale.en => 'Strong',
    AppLocale.tr => 'Guclu',
  };
  String get weakMarginDescription => switch (locale) {
    AppLocale.en => 'Margin is below the comfortable range.',
    AppLocale.tr => 'Marj rahat araligin altinda.',
  };
  String get moderateMarginDescription => switch (locale) {
    AppLocale.en => 'Margin is positive but still under pressure.',
    AppLocale.tr => 'Marj pozitif ama hala baski altinda.',
  };
  String get strongMarginDescription => switch (locale) {
    AppLocale.en => 'Margin is comfortably ahead of costs.',
    AppLocale.tr => 'Marj maliyetlerin rahat sekilde ilerisinde.',
  };
  String get noActivitySelectedRange => switch (locale) {
    AppLocale.en => 'No activity in the selected range',
    AppLocale.tr => 'Secilen aralikta hareket yok',
  };
  String get expensesNotCoveredYet => switch (locale) {
    AppLocale.en => 'Expenses are not covered by income yet',
    AppLocale.tr => 'Giderler henuz gelirle karsilanmiyor',
  };
  String expensesEatingPercent(int percent) => switch (locale) {
    AppLocale.en => 'Expenses are eating $percent% of income',
    AppLocale.tr => 'Giderler gelirin %$percent’ini tuketiyor',
  };
  String get incomeMinusExpenses => switch (locale) {
    AppLocale.en => 'Income - Expenses',
    AppLocale.tr => 'Gelir - Giderler',
  };
  String get noProfitYet => switch (locale) {
    AppLocale.en => 'No profit yet',
    AppLocale.tr => 'Henuz kar yok',
  };
  String get noLossYet => switch (locale) {
    AppLocale.en => 'No loss yet',
    AppLocale.tr => 'Henuz zarar yok',
  };
  String get averageDailyProfit => switch (locale) {
    AppLocale.en => 'Average daily profit',
    AppLocale.tr => 'Ortalama gunluk kar',
  };
  String get expensePressureMessage => switch (locale) {
    AppLocale.en => 'Expenses are consuming most of your income',
    AppLocale.tr => 'Giderler gelirinizin cogunu tuketiyor',
  };
  String get profitHealth => switch (locale) {
    AppLocale.en => 'Profit health',
    AppLocale.tr => 'Kar sagligi',
  };
  String marginPercentLabel(int percent) => switch (locale) {
    AppLocale.en => 'Margin $percent%',
    AppLocale.tr => 'Marj %$percent',
  };
  String get incomeVsExpenses => switch (locale) {
    AppLocale.en => 'Income vs expenses',
    AppLocale.tr => 'Gelir ve giderler',
  };
  String get expensePressure => switch (locale) {
    AppLocale.en => 'Expense pressure',
    AppLocale.tr => 'Gider baskisi',
  };
  String get profitByDay => switch (locale) {
    AppLocale.en => 'Profit by day',
    AppLocale.tr => 'Gune gore kar',
  };
  String get profit => switch (locale) {
    AppLocale.en => 'Profit',
    AppLocale.tr => 'Kar',
  };
  String get loss => switch (locale) {
    AppLocale.en => 'Loss',
    AppLocale.tr => 'Zarar',
  };
  String get noProfitRecordsInRange => switch (locale) {
    AppLocale.en => 'No profit records in this range',
    AppLocale.tr => 'Bu aralikta net kar kaydi yok',
  };
  String get profitChartEmpty => switch (locale) {
    AppLocale.en =>
      'The chart will populate once income or expenses appear in the selected dates.',
    AppLocale.tr =>
      'Secilen tarihlerde gelir veya gider gorundugunde grafik dolar.',
  };
  String get netProfitDetailLoadError => switch (locale) {
    AppLocale.en => 'Couldn’t load net profit detail',
    AppLocale.tr => 'Net kar detayi yuklenemedi',
  };

  String get addIncomeTitle => addIncome;
  String get addExpenseTitle => addExpense;
  String get editIncomeTitle => switch (locale) {
    AppLocale.en => 'Edit income',
    AppLocale.tr => 'Geliri duzenle',
  };
  String get editExpenseTitle => switch (locale) {
    AppLocale.en => 'Edit expense',
    AppLocale.tr => 'Gideri duzenle',
  };
  String get saveIncome => switch (locale) {
    AppLocale.en => 'Save income',
    AppLocale.tr => 'Geliri kaydet',
  };
  String get saveExpense => switch (locale) {
    AppLocale.en => 'Save expense',
    AppLocale.tr => 'Gideri kaydet',
  };
  String editingHeaderSubtitle(String dateLabel) => switch (locale) {
    AppLocale.en => '$dateLabel · editing',
    AppLocale.tr => '$dateLabel · duzenleniyor',
  };
  String newEntryHeaderSubtitle(String dateLabel) => switch (locale) {
    AppLocale.en => '$dateLabel · new entry',
    AppLocale.tr => '$dateLabel · yeni kayit',
  };
  String get category => switch (locale) {
    AppLocale.en => 'Category',
    AppLocale.tr => 'Kategori',
  };
  String get vendor => switch (locale) {
    AppLocale.en => 'Vendor',
    AppLocale.tr => 'Satici',
  };
  String get note => switch (locale) {
    AppLocale.en => 'Note',
    AppLocale.tr => 'Not',
  };
  String get occurredOn => switch (locale) {
    AppLocale.en => 'Occurred on',
    AppLocale.tr => 'Islem tarihi',
  };
  String get sourcePlatform => switch (locale) {
    AppLocale.en => 'Source platform',
    AppLocale.tr => 'Kaynak platform',
  };
  String get attachment => switch (locale) {
    AppLocale.en => 'Attachment',
    AppLocale.tr => 'Ek',
  };
  String get chooseCategoryLabel => switch (locale) {
    AppLocale.en => 'Choose category',
    AppLocale.tr => 'Kategori sec',
  };
  String get optionalSupplierHelper => switch (locale) {
    AppLocale.en => 'Optional · supplier or quick receipt context',
    AppLocale.tr => 'Istege bagli · tedarikci veya kisa fis bilgisi',
  };
  String get vendorHint => switch (locale) {
    AppLocale.en => 'Shell - Mile End',
    AppLocale.tr => 'Shell - Mile End',
  };
  String get optionalNoteExpenseHelper => switch (locale) {
    AppLocale.en => 'Optional · add the detail you need later',
    AppLocale.tr => 'Istege bagli · sonra ihtiyaciniz olacak ayrintiyi ekleyin',
  };
  String get expenseNoteHint => switch (locale) {
    AppLocale.en => 'Fuel top-up before evening run',
    AppLocale.tr => 'Aksam turu oncesi yakit takviyesi',
  };
  String get addReceiptPhoto => switch (locale) {
    AppLocale.en => 'Add receipt photo',
    AppLocale.tr => 'Fis fotografi ekle',
  };
  String get incomeSourceHelper => switch (locale) {
    AppLocale.en => 'Optional · direct sale or delivery settlement',
    AppLocale.tr => 'Istege bagli · dogrudan satis veya teslimat mutabakati',
  };
  String get settlementWeekHelper => switch (locale) {
    AppLocale.en =>
      'Weekly settlement · enter the Monday-Sunday total for this week',
    AppLocale.tr =>
      'Haftalik mutabakat · bu hafta icin Pazartesi-Pazar toplamini girin',
  };
  String get optionalNoteIncomeHelper => switch (locale) {
    AppLocale.en => 'Optional · context for the settlement or sale',
    AppLocale.tr => 'Istege bagli · mutabakat veya satis baglami',
  };
  String get incomeNoteHint => switch (locale) {
    AppLocale.en => 'Lunch rush payout',
    AppLocale.tr => 'Ogle yogunlugu odemesi',
  };
  String get addPayoutSlip => switch (locale) {
    AppLocale.en => 'Add payout slip',
    AppLocale.tr => 'Odeme belgesi ekle',
  };
  String get loadingCategoriesPullToRetry => switch (locale) {
    AppLocale.en => 'Could not load categories. Pull to retry.',
    AppLocale.tr => 'Kategoriler yuklenemedi. Tekrar denemek icin yenileyin.',
  };
  String get noCategoriesCreateInSettings => switch (locale) {
    AppLocale.en => 'No categories yet. Create one in Settings.',
    AppLocale.tr => 'Henuz kategori yok. Ayarlar’dan olusturun.',
  };
  String get recurringHandoffVisualOnly => switch (locale) {
    AppLocale.en =>
      'Recurring handoff stays visual in this batch. Persistence comes later.',
    AppLocale.tr =>
      'Tekrarlayan aktarimi bu partide gorsel kalir. Kalicilik daha sonra gelir.',
  };
  String get enterAmountGreaterThanZeroPence => switch (locale) {
    AppLocale.en => 'Enter an amount greater than £0.00.',
    AppLocale.tr => '£0.00’dan buyuk bir tutar girin.',
  };
  String get choosePaymentMethod => switch (locale) {
    AppLocale.en => 'Choose a payment method.',
    AppLocale.tr => 'Bir odeme yontemi secin.',
  };
  String couldNotDeleteEntry(String error) => switch (locale) {
    AppLocale.en => 'Could not delete entry: $error',
    AppLocale.tr => 'Kayit silinemedi: $error',
  };
  String couldNotSaveEntry(String error) => switch (locale) {
    AppLocale.en => 'Could not save entry: $error',
    AppLocale.tr => 'Kayit kaydedilemedi: $error',
  };
  String get couldNotLoadEntry => switch (locale) {
    AppLocale.en => 'Could not load entry',
    AppLocale.tr => 'Kayit yuklenemedi',
  };
  String get chooseCategorySheetTitle => category.toUpperCase();

  String get summaryThisMonth => switch (locale) {
    AppLocale.en => 'THIS MONTH',
    AppLocale.tr => 'BU AY',
  };

  String categoryTypeLabel(CategoryType value) => switch (value) {
    CategoryType.income => income,
    CategoryType.expense => expense,
  };

  String transactionTypeLabel(TransactionType value) => switch (value) {
    TransactionType.income => income,
    TransactionType.expense => expense,
  };

  String paymentMethodLabel(PaymentMethodType value) => switch (value) {
    PaymentMethodType.cash => cash,
    PaymentMethodType.card => card,
    PaymentMethodType.bankTransfer => switch (locale) {
      AppLocale.en => 'Bank transfer',
      AppLocale.tr => 'Banka transferi',
    },
    PaymentMethodType.other => switch (locale) {
      AppLocale.en => 'Other',
      AppLocale.tr => 'Diger',
    },
  };

  String sourcePlatformLabel(SourcePlatformType value) => switch (value) {
    SourcePlatformType.direct => switch (locale) {
      AppLocale.en => 'Direct',
      AppLocale.tr => 'Dogrudan',
    },
    SourcePlatformType.uber => 'Uber',
    SourcePlatformType.justEat => 'Just Eat',
    SourcePlatformType.other => switch (locale) {
      AppLocale.en => 'Other',
      AppLocale.tr => 'Diger',
    },
  };

  String recurringFrequencyLabel(RecurringFrequencyType value) =>
      switch (value) {
        RecurringFrequencyType.weekly => switch (locale) {
          AppLocale.en => 'Weekly',
          AppLocale.tr => 'Haftalik',
        },
        RecurringFrequencyType.monthly => switch (locale) {
          AppLocale.en => 'Monthly',
          AppLocale.tr => 'Aylik',
        },
        RecurringFrequencyType.quarterly => switch (locale) {
          AppLocale.en => 'Quarterly',
          AppLocale.tr => 'Uc aylik',
        },
        RecurringFrequencyType.yearly => switch (locale) {
          AppLocale.en => 'Yearly',
          AppLocale.tr => 'Yillik',
        },
      };

  String recurringStatusLabel(RecurringUiStatus status, int diffDays) {
    switch (status) {
      case RecurringUiStatus.late:
        return switch (locale) {
          AppLocale.en => 'Late · ${diffDays.abs()}d',
          AppLocale.tr => 'Gecikti · ${diffDays.abs()}g',
        };
      case RecurringUiStatus.soon:
        if (diffDays == 0) {
          return today;
        }
        return inDays(diffDays);
      case RecurringUiStatus.later:
        return switch (locale) {
          AppLocale.en => 'Later',
          AppLocale.tr => 'Daha sonra',
        };
    }
  }

  String recurringFrequencyMeta(
    RecurringUiStatus status,
    RecurringFrequencyType frequency,
    DateTime dueDate,
    int diffDays,
  ) {
    final String everyLabel = switch (locale) {
      AppLocale.en =>
        'Every ${recurringFrequencyLabel(frequency).toLowerCase().replaceFirst('ly', '')}',
      AppLocale.tr => switch (frequency) {
        RecurringFrequencyType.weekly => 'Her hafta',
        RecurringFrequencyType.monthly => 'Her ay',
        RecurringFrequencyType.quarterly => 'Her uc ay',
        RecurringFrequencyType.yearly => 'Her yil',
      },
    };
    return switch (status) {
      RecurringUiStatus.late =>
        '$everyLabel · ${switch (locale) {
          AppLocale.en => 'was due',
          AppLocale.tr => 'vadesi',
        }} ${dayMonthShortWeekday(dueDate)}',
      RecurringUiStatus.soon =>
        '$everyLabel · ${diffDays == 0 ? today : inDays(diffDays)}',
      RecurringUiStatus.later =>
        '$everyLabel · ${dayMonthShortWeekday(dueDate)}',
    };
  }

  String _timePeriodLabel(_RangePreset value) => switch (value) {
    _RangePreset.thisWeek => thisWeek,
    _RangePreset.lastWeek => lastWeek,
    _RangePreset.thisMonth => thisMonth,
    _RangePreset.lastMonth => lastMonth,
    _RangePreset.custom => custom,
  };

  String incomeRangePresetLabel(IncomeDetailRangePreset value) =>
      _timePeriodLabel(_RangePreset.fromIncome(value));
  String expenseRangePresetLabel(ExpenseDetailRangePreset value) =>
      _timePeriodLabel(_RangePreset.fromExpense(value));
  String netProfitRangePresetLabel(NetProfitDetailRangePreset value) =>
      _timePeriodLabel(_RangePreset.fromNetProfit(value));

  String systemCategoryName(String raw) {
    final String normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'cash sales' => switch (locale) {
        AppLocale.en => 'Cash Sales',
        AppLocale.tr => 'Nakit Satislari',
      },
      'card sales' => switch (locale) {
        AppLocale.en => 'Card Sales',
        AppLocale.tr => 'Kart Satislari',
      },
      'uber settlement' => switch (locale) {
        AppLocale.en => 'Uber Settlement',
        AppLocale.tr => 'Uber Mutabakati',
      },
      'just eat settlement' => switch (locale) {
        AppLocale.en => 'Just Eat Settlement',
        AppLocale.tr => 'Just Eat Mutabakati',
      },
      'other income' => switch (locale) {
        AppLocale.en => 'Other Income',
        AppLocale.tr => 'Diger Gelir',
      },
      'rent' => switch (locale) {
        AppLocale.en => 'Rent',
        AppLocale.tr => 'Kira',
      },
      'utilities' => switch (locale) {
        AppLocale.en => 'Utilities',
        AppLocale.tr => 'Faturalar',
      },
      'internet' => 'Internet',
      'stock purchase' => switch (locale) {
        AppLocale.en => 'Stock Purchase',
        AppLocale.tr => 'Stok Alimi',
      },
      'supplies' => switch (locale) {
        AppLocale.en => 'Supplies',
        AppLocale.tr => 'Malzemeler',
      },
      'maintenance' => switch (locale) {
        AppLocale.en => 'Maintenance',
        AppLocale.tr => 'Bakim',
      },
      'delivery/transport' => switch (locale) {
        AppLocale.en => 'Delivery/Transport',
        AppLocale.tr => 'Teslimat/Ulasim',
      },
      'other expense' => switch (locale) {
        AppLocale.en => 'Other Expense',
        AppLocale.tr => 'Diger Gider',
      },
      _ => raw,
    };
  }

  String formatPercent(double? value) {
    if (value == null || !value.isFinite) {
      return '—';
    }
    final double rounded = (value * 10).round() / 10;
    final bool useDecimal =
        rounded.abs() < 10 && rounded != rounded.roundToDouble();
    final String label = useDecimal
        ? rounded.toStringAsFixed(1)
        : rounded.round().toString();
    return '$label%';
  }

  String currencyMinor(int amountMinor, {int decimalDigits = 2}) {
    return NumberFormat.currency(
      locale: 'en_GB',
      symbol: '£',
      decimalDigits: decimalDigits,
    ).format(amountMinor / 100);
  }

  String compactCurrencyMinor(int amountMinor) {
    return NumberFormat.compactCurrency(
      locale: 'en_GB',
      symbol: '£',
      decimalDigits: 1,
    ).format(amountMinor / 100);
  }

  String signedCurrencyMinor(int amountMinor) {
    final String prefix = amountMinor > 0 ? '+' : '';
    return '$prefix${currencyMinor(amountMinor)}';
  }

  String weekdayShort(DateTime date) =>
      DateFormat('E', locale.intlTag).format(date);

  String weekdayShortDate(DateTime date) =>
      DateFormat('EEE d MMM', locale.intlTag).format(date);

  String dayMonth(DateTime date) =>
      DateFormat('d MMM', locale.intlTag).format(date);

  String dayMonthYear(DateTime date) =>
      DateFormat('d MMM yyyy', locale.intlTag).format(date);

  String monthLong(DateTime date) =>
      DateFormat('MMMM', locale.intlTag).format(date);

  String monthShort(DateTime date) =>
      DateFormat('MMM', locale.intlTag).format(date);

  String monthYear(DateTime date) => '${monthLong(date)} ${date.year}';

  String rangeLabel(DateTime start, DateTime end) =>
      '${weekdayShortDate(start)} – ${weekdayShortDate(end)}';

  String dashboardWeekLabel(DateTime start, DateTime end) =>
      '${weekdayShort(start)} ${start.day} → ${weekdayShortDate(end)}';

  String dayMonthShortWeekday(DateTime date) =>
      '${weekdayShort(date)} ${date.day} ${monthShort(date)}';

  String inDays(int days) => switch (locale) {
    AppLocale.en => 'In $days days',
    AppLocale.tr => '$days gun sonra',
  };
}

extension AppLocalizationsContextX on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (Locale supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(AppLocale.fromLanguageCode(locale.languageCode));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

enum _RangePreset {
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom;

  static _RangePreset fromIncome(IncomeDetailRangePreset value) =>
      switch (value) {
        IncomeDetailRangePreset.thisWeek => _RangePreset.thisWeek,
        IncomeDetailRangePreset.lastWeek => _RangePreset.lastWeek,
        IncomeDetailRangePreset.thisMonth => _RangePreset.thisMonth,
        IncomeDetailRangePreset.lastMonth => _RangePreset.lastMonth,
        IncomeDetailRangePreset.custom => _RangePreset.custom,
      };

  static _RangePreset fromExpense(ExpenseDetailRangePreset value) =>
      switch (value) {
        ExpenseDetailRangePreset.thisWeek => _RangePreset.thisWeek,
        ExpenseDetailRangePreset.lastWeek => _RangePreset.lastWeek,
        ExpenseDetailRangePreset.thisMonth => _RangePreset.thisMonth,
        ExpenseDetailRangePreset.lastMonth => _RangePreset.lastMonth,
        ExpenseDetailRangePreset.custom => _RangePreset.custom,
      };

  static _RangePreset fromNetProfit(NetProfitDetailRangePreset value) =>
      switch (value) {
        NetProfitDetailRangePreset.thisWeek => _RangePreset.thisWeek,
        NetProfitDetailRangePreset.lastWeek => _RangePreset.lastWeek,
        NetProfitDetailRangePreset.thisMonth => _RangePreset.thisMonth,
        NetProfitDetailRangePreset.lastMonth => _RangePreset.lastMonth,
        NetProfitDetailRangePreset.custom => _RangePreset.custom,
      };
}
