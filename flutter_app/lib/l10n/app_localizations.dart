import 'package:flutter/material.dart';
import '../services/translation_service.dart';

/// Supported locales for the app
enum AppLocale {
  english('en', 'English', 'अंग्रेजी'),
  nepali('ne', 'नेपाली', 'नेपाली'),
  newari('new', 'नेपाल भाषा', 'नेपाल भाषा'),
  maithili('mai', 'मैथिली', 'मैथिली');

  const AppLocale(this.code, this.displayName, this.nativeName);

  final String code;
  final String displayName;
  final String nativeName;

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (locale) => locale.code == code,
      orElse: () => AppLocale.nepali, // Default to Nepali
    );
  }

  Locale get locale => Locale(code);
}

/// Localizations class for the app
/// Translations are loaded from assets/translations/ui_strings.csv
class AppLocalizations {
  final AppLocale locale;

  AppLocalizations(this.locale);

  /// Default fallback instance for when localizations haven't loaded yet
  static final _fallback = AppLocalizations(AppLocale.nepali);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? _fallback;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Get translation service instance
  TranslationService get _service => TranslationService.instance;

  /// Get localized string by key
  String get(String key) {
    final strings = _service.getTranslations(locale.code);
    final fallback = _service.getTranslations('en');
    return strings[key] ?? fallback[key] ?? key;
  }

  /// Get localized string with parameters
  String getWithParams(String key, Map<String, String> params) {
    var text = get(key);
    params.forEach((paramKey, value) {
      text = text.replaceAll('{$paramKey}', value);
    });
    return text;
  }

  // ============= App General =============
  String get appName => get('app_name');

  // ============= Navigation =============
  String get navCalendar => get('nav_calendar');
  String get navHome => get('nav_home');
  String get navIpo => get('nav_ipo');
  String get navRights => get('nav_rights');
  String get explore => get('explore');
  String get utilities => get('utilities');
  String get govt => get('govt');
  String get government => get('government');
  String get map => get('map');
  String get rights => get('rights');

  // ============= Utility Cards =============
  String get citizenshipMerger => get('citizenship_merger');
  String get imageCompressor => get('image_compressor');
  String get calendar => get('calendar');
  String get dateConvert => get('date_convert');
  String get forex => get('forex');
  String get goldSilver => get('gold_silver');

  // ============= Settings =============
  String get settings => get('settings');
  String get languageDisplay => get('language_display');
  String get dataUpdates => get('data_updates');
  String get notifications => get('notifications');
  String get about => get('about');
  String get language => get('language');
  String get theme => get('theme');
  String get autoCheckUpdates => get('auto_check_updates');
  String get autoCheckUpdatesDesc => get('auto_check_updates_desc');
  String get checkUpdatesNow => get('check_updates_now');
  String get checkUpdatesNowDesc => get('check_updates_now_desc');
  String get clearCache => get('clear_cache');
  String get clearCacheDesc => get('clear_cache_desc');
  String get stickyDateNotification => get('sticky_date_notification');
  String get stickyDateNotificationDesc => get('sticky_date_notification_desc');
  String get ipoAlerts => get('ipo_alerts');
  String get ipoAlertsDesc => get('ipo_alerts_desc');
  String get checkingUpdates => get('checking_updates');
  String get cacheCleared => get('cache_cleared');
  String get appVersion => get('app_version');

  // ============= Theme Options =============
  String get themeSystem => get('theme_system');
  String get themeLight => get('theme_light');
  String get themeDark => get('theme_dark');
  String get themeSystemDesc => get('theme_system_desc');
  String get themeLightDesc => get('theme_light_desc');
  String get themeDarkDesc => get('theme_dark_desc');
  String get chooseTheme => get('choose_theme');

  // ============= Language Options =============
  String get chooseLanguage => get('choose_language');
  String get bothLanguages => get('both_languages');
  String get nepaliLanguage => get('nepali_language');
  String get englishLanguage => get('english_language');
  String get newariLanguage => get('newari_language');
  String get maithiliLanguage => get('maithili_language');

  // ============= Constitution =============
  String get constitution => get('constitution');
  String get knowYourRights => get('know_your_rights');
  String get preamble => get('preamble');
  String partNumber(int number) => getWithParams('part_number', {'number': number.toString()});
  String articleNumber(int number) => getWithParams('article_number', {'number': number.toString()});
  String get searchArticles => get('search_articles');
  String noResults(String query) => getWithParams('no_results', {'query': query});
  String get fileComplaint => get('file_complaint');
  String get articles => get('articles');

  // ============= View Mode =============
  String get both => get('both');
  String get nepali => get('nepali');
  String get english => get('english');
  String get paragraph => get('paragraph');
  String get sentence => get('sentence');

  // ============= Leaders =============
  String get leaders => get('leaders');
  String get sort => get('sort');
  String get filter => get('filter');
  String get sortBy => get('sort_by');
  String get name => get('name');
  String get district => get('district');
  String get party => get('party');
  String get searchLeaders => get('search_leaders');
  String get noLeadersMatch => get('no_leaders_match');
  String get noLeadersFound => get('no_leaders_found');
  String get filters => get('filters');
  String get clearAll => get('clear_all');
  String leadersCount(int count) => getWithParams('leaders_count', {'count': count.toString()});
  String get filterByDistrict => get('filter_by_district');
  String get selectDistrict => get('select_district');
  String get clear => get('clear');
  String province(int number) => getWithParams('province', {'number': number.toString()});
  String provinceNumber(int number) => province(number); // Alias for backwards compatibility
  String districtsCount(int count) => getWithParams('districts_count', {'count': count.toString()});

  // ============= Leader Detail =============
  String get biography => get('biography');
  String get noBiography => get('no_biography');
  String get viewAllLeaders => get('view_all_leaders');

  // ============= District Map =============
  String get nepalDistricts => get('nepal_districts');
  String get filterByProvince => get('filter_by_province');
  String get resetZoom => get('reset_zoom');
  String noLeadersDistrict(String district) => getWithParams('no_leaders_district', {'district': district});

  // ============= Calendar =============
  String get nepaliCalendar => get('nepali_calendar');
  String get today => get('today');
  String get previousMonth => get('previous_month');
  String get nextMonth => get('next_month');
  String get holiday => get('holiday');
  String get event => get('event');
  String get auspicious => get('auspicious');
  String get noEvents => get('no_events');

  // ============= IPO =============
  String get ipoShares => get('ipo_shares');
  String get ipoList => get('ipo_list');
  String get todaysPrice => get('todays_price');
  String get sourceCdsc => get('source_cdsc');
  String updatedAgo(String time) => getWithParams('updated_ago', {'time': time});
  String get openCdsc => get('open_cdsc');
  String get noActiveIpos => get('no_active_ipos');
  String get checkLater => get('check_later');
  String get refresh => get('refresh');
  String get retry => get('retry');
  String get openForApplication => get('open_for_application');
  String get closesToday => get('closes_today');
  String get closesTomorrow => get('closes_tomorrow');
  String get opensTomorrow => get('opens_tomorrow');
  String opensInDays(int days) => getWithParams('opens_in_days', {'days': days.toString()});
  String get closed => get('closed');
  String get issuedUnits => get('issued_units');
  String get applications => get('applications');
  String get appliedUnits => get('applied_units');
  String get totalAmount => get('total_amount');
  String get opens => get('opens');
  String get closes => get('closes');
  String lastUpdated(String time) => getWithParams('last_updated', {'time': time});
  String issueManager(String name) => getWithParams('issue_manager', {'name': name});
  String get searchSymbol => get('search_symbol');
  String get topVolume => get('top_volume');
  String get topGainers => get('top_gainers');
  String get topLosers => get('top_losers');
  String get sourceMerolagani => get('source_merolagani');
  String get marketUnavailable => get('market_unavailable');
  String get marketClosed => get('market_closed');
  String get vol => get('vol');

  // ============= Date Converter =============
  String get dateConverter => get('date_converter');
  String get bsToAd => get('bs_to_ad');
  String get adToBs => get('ad_to_bs');
  String get bsToGregorian => get('bs_to_gregorian');
  String get gregorianToBs => get('gregorian_to_bs');
  String get year => get('year');
  String get month => get('month');
  String get day => get('day');
  String get gregorianDate => get('gregorian_date');
  String get bikramSambat => get('bikram_sambat');
  String get invalidBsDate => get('invalid_bs_date');
  String get selectDate => get('select_date');

  // ============= Citizenship Merger =============
  String get citizenshipPhotoMerger => get('citizenship_photo_merger');
  String get reset => get('reset');
  String get mergerInstructions => get('merger_instructions');
  String get frontSide => get('front_side');
  String get backSide => get('back_side');
  String get mergePhotos => get('merge_photos');
  String get processing => get('processing');
  String fileSize(String size) => getWithParams('file_size', {'size': size});
  String get save => get('save');
  String get share => get('share');
  String get gallery => get('gallery');
  String get camera => get('camera');
  String get tapToSelect => get('tap_to_select');
  String addTitle(String title) => getWithParams('add_title', {'title': title});
  String get savedToPhotos => get('saved_to_photos');
  String get failedToSave => get('failed_to_save');

  // ============= Image Compressor =============
  String get imageCompressorTitle => get('image_compressor_title');
  String get compressImages => get('compress_images');
  String get compressDesc => get('compress_desc');
  String get selectImage => get('select_image');
  String get original => get('original');
  String get compressed => get('compressed');
  String get targetSize => get('target_size');
  String get compress => get('compress');
  String get compressing => get('compressing');
  String get compressAgain => get('compress_again');
  String compressedUnder(String size) => getWithParams('compressed_under', {'size': size});
  String get couldNotReach => get('could_not_reach');
  String savedSmaller(String size, String percent) => getWithParams('saved_smaller', {'size': size, 'percent': percent});

  // ============= Forex =============
  String get forexRates => get('forex_rates');
  String get nrbRates => get('nrb_rates');
  String get currency => get('currency');
  String get buy => get('buy');
  String get sell => get('sell');
  String perUnits(int units) => getWithParams('per_units', {'units': units.toString()});
  String get failedLoadRates => get('failed_load_rates');
  String networkError(String error) => getWithParams('network_error', {'error': error});
  String get noData => get('no_data');

  // ============= Bullion =============
  String get goldSilverTitle => get('gold_silver_title');
  String source(String src) => getWithParams('source', {'source': src});
  String todayDate(String date) => getWithParams('today_date', {'date': date});
  String get goldHallmark => get('gold_hallmark');
  String get goldTejabi => get('gold_tejabi');
  String get silver => get('silver');
  String get perTola => get('per_tola');
  String get thisWeek => get('this_week');
  String get date => get('date');
  String get hallmark => get('hallmark');
  String get tejabi => get('tejabi');
  String get failedLoadData => get('failed_load_data');

  // ============= Government Services =============
  String get govServices => get('gov_services');
  String get searchServices => get('search_services');
  String get noServices => get('no_services');
  String get tryDifferent => get('try_different');
  String couldNotOpen(String url) => getWithParams('could_not_open', {'url': url});

  // ============= Government Procedures =============
  String get govProcedures => get('gov_procedures');
  String get quickLinks => get('quick_links');
  String get governmentInfo => get('government_info');
  String get getDocuments => get('get_documents');
  String get getGovDocuments => get('get_gov_documents');
  String get getGovDocumentsDesc => get('get_gov_documents_desc');
  String get constitutionDesc => get('constitution_desc');
  String get leadersDesc => get('leaders_desc');
  String get structureDesc => get('structure_desc');
  String get lawMakingDesc => get('law_making_desc');
  String get cabinetDesc => get('cabinet_desc');
  String get govServicesDesc => get('gov_services_desc');

  // ============= How Nepal Works =============
  String get howNepalWorks => get('how_nepal_works');
  String get structure => get('structure');
  String get lawMaking => get('law_making');
  String get cabinet => get('cabinet');
  String get federalParliament => get('federal_parliament');
  String seats(int count) => getWithParams('seats', {'count': count.toString()});
  String get specialBills => get('special_bills');
  String lastUpdatedDate(String date) => getWithParams('last_updated_date', {'date': date});
  String get sourceOpmcm => get('source_opmcm');

  // ============= Common Actions =============
  String get cancel => get('cancel');
  String get ok => get('ok');
  String get done => get('done');
  String get close => get('close');
  String get yes => get('yes');
  String get no => get('no');
  String get loading => get('loading');
  String get error => get('error');
  String get success => get('success');
  String get warning => get('warning');

  // ============= Error Messages =============
  String get somethingWentWrong => get('something_went_wrong');
  String get noInternet => get('no_internet');
  String get tryAgain => get('try_again');

  // ============= Weekdays =============
  String get sunday => get('sunday');
  String get monday => get('monday');
  String get tuesday => get('tuesday');
  String get wednesday => get('wednesday');
  String get thursday => get('thursday');
  String get friday => get('friday');
  String get saturday => get('saturday');

  // ============= Nepali Months =============
  String get baisakh => get('baisakh');
  String get jestha => get('jestha');
  String get ashadh => get('ashadh');
  String get shrawan => get('shrawan');
  String get bhadra => get('bhadra');
  String get ashwin => get('ashwin');
  String get kartik => get('kartik');
  String get mangsir => get('mangsir');
  String get poush => get('poush');
  String get magh => get('magh');
  String get falgun => get('falgun');
  String get chaitra => get('chaitra');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocale.values.any((l) => l.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Ensure translations are loaded before creating localizations
    await TranslationService.instance.loadTranslations();
    return AppLocalizations(AppLocale.fromCode(locale.languageCode));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
