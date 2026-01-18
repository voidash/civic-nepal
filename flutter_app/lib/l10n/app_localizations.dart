import 'package:flutter/material.dart';

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

  /// Get localized string by key
  String get(String key) {
    final strings = _localizedStrings[locale] ?? _localizedStrings[AppLocale.nepali]!;
    return strings[key] ?? _localizedStrings[AppLocale.english]![key] ?? key;
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
  String provinceNumber(int number) => getWithParams('province', {'number': number.toString()});
  String districtsCount(int count) => getWithParams('districts_count', {'count': count.toString()});

  // ============= Leader Detail =============
  String get biography => get('biography');
  String get noBiography => get('no_biography');
  String get viewAllLeaders => get('view_all_leaders');

  // ============= Map =============
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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocale.values.any((l) => l.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(AppLocale.fromCode(locale.languageCode));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// All localized strings
const Map<AppLocale, Map<String, String>> _localizedStrings = {
  AppLocale.english: _englishStrings,
  AppLocale.nepali: _nepaliStrings,
  AppLocale.newari: _newariStrings,
  AppLocale.maithili: _maithiliStrings,
};

const _englishStrings = {
  // App General
  'app_name': 'Nepal Civic',

  // Navigation
  'nav_calendar': 'Calendar',
  'nav_home': 'Home',
  'nav_ipo': 'IPO',
  'nav_rights': 'Rights',
  'explore': 'Explore',
  'utilities': 'Utilities',
  'govt': 'Govt',
  'map': 'Map',
  'rights': 'Rights',

  // Utility Cards
  'citizenship_merger': 'Citizenship Merger',
  'image_compressor': 'Image < 300KB',
  'calendar': 'Calendar',
  'date_convert': 'Date Convert',
  'forex': 'Forex',
  'gold_silver': 'Gold/Silver',

  // Settings
  'settings': 'Settings',
  'language_display': 'Language & Display',
  'data_updates': 'Data & Updates',
  'notifications': 'Notifications',
  'about': 'About',
  'language': 'Language',
  'theme': 'Theme',
  'auto_check_updates': 'Auto-check for updates',
  'auto_check_updates_desc': 'Check for new data on app launch',
  'check_updates_now': 'Check for updates now',
  'check_updates_now_desc': 'Download latest leader data',
  'clear_cache': 'Clear cache',
  'clear_cache_desc': 'Free up storage space',
  'sticky_date_notification': 'Sticky Date Notification',
  'sticky_date_notification_desc': 'Show today\'s Nepali date in notification bar',
  'ipo_alerts': 'IPO Alerts',
  'ipo_alerts_desc': 'Get notified when IPOs are opening or closing',
  'checking_updates': 'Checking for updates...',
  'cache_cleared': 'Cache cleared',
  'app_version': 'Nepal Civic App v1.0.0',

  // Theme Options
  'theme_system': 'System',
  'theme_light': 'Light',
  'theme_dark': 'Dark',
  'theme_system_desc': 'Follow device settings',
  'theme_light_desc': 'Always light theme',
  'theme_dark_desc': 'Always dark theme',
  'choose_theme': 'Choose Theme',

  // Language Options
  'choose_language': 'Choose Language',
  'both_languages': 'Both Languages',
  'nepali_language': 'नेपाली (Nepali)',
  'english_language': 'English',
  'newari_language': 'नेपाल भाषा (Newari)',
  'maithili_language': 'मैथिली (Maithili)',

  // Constitution
  'know_your_rights': 'Know Your Rights',
  'preamble': 'Preamble',
  'part_number': 'Part {number}',
  'article_number': 'Article {number}',
  'search_articles': 'Search for articles...',
  'no_results': 'No results for "{query}"',
  'file_complaint': 'File Complaint',
  'articles': 'Articles',

  // View Mode
  'both': 'Both',
  'nepali': 'नेपाली',
  'english': 'English',
  'paragraph': 'Paragraph',
  'sentence': 'Sentence',

  // Leaders
  'leaders': 'Leaders',
  'sort': 'Sort',
  'filter': 'Filter',
  'sort_by': 'Sort by',
  'name': 'Name',
  'district': 'District',
  'party': 'Party',
  'search_leaders': 'Search leaders...',
  'no_leaders_match': 'No leaders match your filters',
  'no_leaders_found': 'No leaders found',
  'filters': 'Filters',
  'clear_all': 'Clear All',
  'leaders_count': '{count} leaders',
  'filter_by_district': 'Filter by District',
  'select_district': 'Select District',
  'clear': 'Clear',
  'province': 'Province {number}',
  'districts_count': '{count} districts',

  // Leader Detail
  'biography': 'Biography',
  'no_biography': 'No biography available.',
  'view_all_leaders': 'View All Leaders',

  // Map
  'nepal_districts': 'Nepal Districts',
  'filter_by_province': 'Filter by Province',
  'reset_zoom': 'Reset Zoom',
  'no_leaders_district': 'No leaders found for {district}',

  // Calendar
  'nepali_calendar': 'Nepali Calendar',
  'today': 'Today',
  'previous_month': 'Previous month',
  'next_month': 'Next month',
  'holiday': 'Holiday',
  'event': 'Event',
  'auspicious': 'Auspicious',
  'no_events': 'No events',

  // IPO
  'ipo_shares': 'IPO & Shares',
  'ipo_list': 'IPO List',
  'todays_price': 'Today\'s Price',
  'source_cdsc': 'Source: CDSC Nepal',
  'updated_ago': 'Updated {time} ago',
  'open_cdsc': 'Open CDSC Website',
  'no_active_ipos': 'No active IPOs',
  'check_later': 'Check back later for new listings',
  'refresh': 'Refresh',
  'retry': 'Retry',
  'open_for_application': 'Open for Application',
  'closes_today': 'Closes Today!',
  'closes_tomorrow': 'Closes Tomorrow',
  'opens_tomorrow': 'Opens Tomorrow',
  'opens_in_days': 'Opens in {days} days',
  'closed': 'Closed',
  'issued_units': 'Issued Units',
  'applications': 'Applications',
  'applied_units': 'Applied Units',
  'total_amount': 'Total Amount',
  'opens': 'Opens',
  'closes': 'Closes',
  'last_updated': 'Last updated: {time}',
  'issue_manager': 'Issue Manager: {name}',
  'search_symbol': 'Search symbol or company...',
  'top_volume': 'Top Volume',
  'top_gainers': 'Top Gainers',
  'top_losers': 'Top Losers',
  'source_merolagani': 'Source: Merolagani',
  'market_unavailable': 'Market data unavailable',
  'market_closed': 'Market may be closed or data is loading',
  'vol': 'Vol',

  // Date Converter
  'date_converter': 'Date Converter',
  'bs_to_ad': 'BS → AD',
  'ad_to_bs': 'AD → BS',
  'bs_to_gregorian': 'Bikram Sambat → Gregorian',
  'gregorian_to_bs': 'Gregorian → Bikram Sambat',
  'year': 'Year',
  'month': 'Month',
  'day': 'Day',
  'gregorian_date': 'Gregorian Date (AD)',
  'bikram_sambat': 'Bikram Sambat (BS)',
  'invalid_bs_date': 'Invalid BS date',
  'select_date': 'Select a date',

  // Citizenship Merger
  'citizenship_photo_merger': 'Citizenship Photo Merger',
  'reset': 'Reset',
  'merger_instructions': 'Add front and back photos of your citizenship card to merge them into a single image.',
  'front_side': 'Front Side',
  'back_side': 'Back Side',
  'merge_photos': 'Merge Photos',
  'processing': 'Processing...',
  'file_size': 'Size: {size}',
  'save': 'Save',
  'share': 'Share',
  'gallery': 'Gallery',
  'camera': 'Camera',
  'tap_to_select': 'Tap to select',
  'add_title': 'Add {title}',
  'saved_to_photos': 'Saved to Photos',
  'failed_to_save': 'Failed to save',

  // Image Compressor
  'image_compressor_title': 'Image Compressor',
  'compress_images': 'Compress Images',
  'compress_desc': 'Reduce image file size while maintaining quality',
  'select_image': 'Select Image',
  'original': 'Original',
  'compressed': 'Compressed',
  'target_size': 'Target Size',
  'compress': 'Compress',
  'compressing': 'Compressing...',
  'compress_again': 'Compress Again',
  'compressed_under': 'Compressed to under {size}',
  'could_not_reach': 'Could not reach target size',
  'saved_smaller': 'Saved {size} ({percent}% smaller)',

  // Forex
  'forex_rates': 'Forex Rates',
  'nrb_rates': 'Nepal Rastra Bank Rates',
  'currency': 'Currency',
  'buy': 'Buy',
  'sell': 'Sell',
  'per_units': 'Per {units} units',
  'failed_load_rates': 'Failed to load rates',
  'network_error': 'Network error: {error}',
  'no_data': 'No data available',

  // Bullion
  'gold_silver_title': 'Gold & Silver',
  'source': 'Source: {source}',
  'today_date': 'Today ({date})',
  'gold_hallmark': 'Gold (Hallmark)',
  'gold_tejabi': 'Gold (Tejabi)',
  'silver': 'Silver',
  'per_tola': 'per tola',
  'this_week': 'This Week',
  'date': 'Date',
  'hallmark': 'Hallmark',
  'tejabi': 'Tejabi',
  'failed_load_data': 'Failed to load data',

  // Government Services
  'gov_services': 'Government Services',
  'search_services': 'Search services...',
  'no_services': 'No services found',
  'try_different': 'Try a different search term',
  'could_not_open': 'Could not open: {url}',

  // How Nepal Works
  'how_nepal_works': 'How Nepal Works',
  'structure': 'Structure',
  'law_making': 'Law Making',
  'cabinet': 'Cabinet',
  'federal_parliament': 'Federal Parliament (Bicameral)',
  'seats': '{count} seats',
  'special_bills': 'Special Types of Bills',
  'last_updated_date': 'Last updated: {date}',
  'source_opmcm': 'Source: opmcm.gov.np',

  // Common Actions
  'cancel': 'Cancel',
  'ok': 'OK',
  'done': 'Done',
  'close': 'Close',
  'yes': 'Yes',
  'no': 'No',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'warning': 'Warning',

  // Error Messages
  'something_went_wrong': 'Something went wrong',
  'no_internet': 'No internet connection',
  'try_again': 'Please try again',
};

const _nepaliStrings = {
  // App General
  'app_name': 'नेपाल नागरिक',

  // Navigation
  'nav_calendar': 'पात्रो',
  'nav_home': 'गृह',
  'nav_ipo': 'आईपीओ',
  'nav_rights': 'अधिकार',
  'explore': 'अन्वेषण',
  'utilities': 'उपकरणहरू',
  'govt': 'सरकार',
  'map': 'नक्सा',
  'rights': 'अधिकार',

  // Utility Cards
  'citizenship_merger': 'नागरिकता मर्जर',
  'image_compressor': 'फोटो कम्प्रेस',
  'calendar': 'पात्रो',
  'date_convert': 'मिति परिवर्तक',
  'forex': 'विदेशी मुद्रा',
  'gold_silver': 'सुन/चाँदी',

  // Settings
  'settings': 'सेटिङ',
  'language_display': 'भाषा र प्रदर्शन',
  'data_updates': 'डाटा र अपडेट',
  'notifications': 'सूचनाहरू',
  'about': 'बारेमा',
  'language': 'भाषा',
  'theme': 'थिम',
  'auto_check_updates': 'स्वचालित अपडेट जाँच',
  'auto_check_updates_desc': 'एप खोल्दा नयाँ डाटा जाँच गर्नुहोस्',
  'check_updates_now': 'अहिले अपडेट जाँच गर्नुहोस्',
  'check_updates_now_desc': 'नवीनतम नेता डाटा डाउनलोड गर्नुहोस्',
  'clear_cache': 'क्यास खाली गर्नुहोस्',
  'clear_cache_desc': 'भण्डारण ठाउँ खाली गर्नुहोस्',
  'sticky_date_notification': 'स्थायी मिति सूचना',
  'sticky_date_notification_desc': 'आजको नेपाली मिति सूचना पट्टीमा देखाउनुहोस्',
  'ipo_alerts': 'आईपीओ सूचना',
  'ipo_alerts_desc': 'आईपीओ खुल्दा वा बन्द हुँदा सूचना पाउनुहोस्',
  'checking_updates': 'अपडेट जाँच गर्दै...',
  'cache_cleared': 'क्यास खाली भयो',
  'app_version': 'नेपाल नागरिक एप v1.0.0',

  // Theme Options
  'theme_system': 'सिस्टम',
  'theme_light': 'उज्यालो',
  'theme_dark': 'अँध्यारो',
  'theme_system_desc': 'उपकरण सेटिङ अनुसरण गर्नुहोस्',
  'theme_light_desc': 'सधैं उज्यालो थिम',
  'theme_dark_desc': 'सधैं अँध्यारो थिम',
  'choose_theme': 'थिम छान्नुहोस्',

  // Language Options
  'choose_language': 'भाषा छान्नुहोस्',
  'both_languages': 'दुवै भाषा',
  'nepali_language': 'नेपाली',
  'english_language': 'अंग्रेजी',
  'newari_language': 'नेपाल भाषा',
  'maithili_language': 'मैथिली',

  // Constitution
  'know_your_rights': 'आफ्नो हक जान्नुहोस्',
  'preamble': 'प्रस्तावना',
  'part_number': 'भाग {number}',
  'article_number': 'धारा {number}',
  'search_articles': 'धाराहरू खोज्नुहोस्...',
  'no_results': '"{query}" को लागि कुनै परिणाम छैन',
  'file_complaint': 'उजुरी दिनुहोस्',
  'articles': 'धाराहरू',

  // View Mode
  'both': 'दुवै',
  'nepali': 'नेपाली',
  'english': 'अंग्रेजी',
  'paragraph': 'अनुच्छेद',
  'sentence': 'वाक्य',

  // Leaders
  'leaders': 'नेताहरू',
  'sort': 'क्रमबद्ध',
  'filter': 'फिल्टर',
  'sort_by': 'क्रमबद्ध गर्नुहोस्',
  'name': 'नाम',
  'district': 'जिल्ला',
  'party': 'पार्टी',
  'search_leaders': 'नेताहरू खोज्नुहोस्...',
  'no_leaders_match': 'तपाईंको फिल्टरसँग कुनै नेता मिलेन',
  'no_leaders_found': 'कुनै नेता भेटिएन',
  'filters': 'फिल्टरहरू',
  'clear_all': 'सबै हटाउनुहोस्',
  'leaders_count': '{count} नेताहरू',
  'filter_by_district': 'जिल्ला अनुसार फिल्टर',
  'select_district': 'जिल्ला छान्नुहोस्',
  'clear': 'हटाउनुहोस्',
  'province': 'प्रदेश {number}',
  'districts_count': '{count} जिल्लाहरू',

  // Leader Detail
  'biography': 'जीवनी',
  'no_biography': 'जीवनी उपलब्ध छैन।',
  'view_all_leaders': 'सबै नेताहरू हेर्नुहोस्',

  // Map
  'nepal_districts': 'नेपाल जिल्लाहरू',
  'filter_by_province': 'प्रदेश अनुसार फिल्टर',
  'reset_zoom': 'जुम रिसेट',
  'no_leaders_district': '"{district}" मा कुनै नेता भेटिएन',

  // Calendar
  'nepali_calendar': 'नेपाली पात्रो',
  'today': 'आज',
  'previous_month': 'अघिल्लो महिना',
  'next_month': 'अर्को महिना',
  'holiday': 'बिदा',
  'event': 'कार्यक्रम',
  'auspicious': 'शुभ',
  'no_events': 'कुनै कार्यक्रम छैन',

  // IPO
  'ipo_shares': 'आईपीओ र सेयर',
  'ipo_list': 'आईपीओ सूची',
  'todays_price': 'आजको मूल्य',
  'source_cdsc': 'स्रोत: सीडीएससी नेपाल',
  'updated_ago': '{time} अघि अपडेट भयो',
  'open_cdsc': 'सीडीएससी वेबसाइट खोल्नुहोस्',
  'no_active_ipos': 'कुनै सक्रिय आईपीओ छैन',
  'check_later': 'नयाँ सूचीको लागि पछि जाँच गर्नुहोस्',
  'refresh': 'ताजा गर्नुहोस्',
  'retry': 'पुन: प्रयास',
  'open_for_application': 'आवेदनको लागि खुला',
  'closes_today': 'आज बन्द हुन्छ!',
  'closes_tomorrow': 'भोलि बन्द हुन्छ',
  'opens_tomorrow': 'भोलि खुल्छ',
  'opens_in_days': '{days} दिनमा खुल्छ',
  'closed': 'बन्द',
  'issued_units': 'जारी इकाइहरू',
  'applications': 'आवेदनहरू',
  'applied_units': 'आवेदित इकाइहरू',
  'total_amount': 'कुल रकम',
  'opens': 'खुल्छ',
  'closes': 'बन्द हुन्छ',
  'last_updated': 'अन्तिम अपडेट: {time}',
  'issue_manager': 'इश्यू म्यानेजर: {name}',
  'search_symbol': 'सिम्बल वा कम्पनी खोज्नुहोस्...',
  'top_volume': 'उच्च भोल्युम',
  'top_gainers': 'उच्च लाभ',
  'top_losers': 'उच्च घाटा',
  'source_merolagani': 'स्रोत: मेरोलगानी',
  'market_unavailable': 'बजार डाटा उपलब्ध छैन',
  'market_closed': 'बजार बन्द हुन सक्छ वा डाटा लोड हुँदैछ',
  'vol': 'भोल्युम',

  // Date Converter
  'date_converter': 'मिति परिवर्तक',
  'bs_to_ad': 'बि.सं. → ई.सं.',
  'ad_to_bs': 'ई.सं. → बि.सं.',
  'bs_to_gregorian': 'बिक्रम सम्बत → ग्रेगोरियन',
  'gregorian_to_bs': 'ग्रेगोरियन → बिक्रम सम्बत',
  'year': 'वर्ष',
  'month': 'महिना',
  'day': 'दिन',
  'gregorian_date': 'ग्रेगोरियन मिति (ई.सं.)',
  'bikram_sambat': 'बिक्रम सम्बत (बि.सं.)',
  'invalid_bs_date': 'अवैध बि.सं. मिति',
  'select_date': 'मिति छान्नुहोस्',

  // Citizenship Merger
  'citizenship_photo_merger': 'नागरिकता फोटो मर्जर',
  'reset': 'रिसेट',
  'merger_instructions': 'नागरिकताको अगाडि र पछाडिको फोटो थपेर एउटै तस्बिरमा मर्ज गर्नुहोस्।',
  'front_side': 'अगाडिको भाग',
  'back_side': 'पछाडिको भाग',
  'merge_photos': 'फोटो मर्ज गर्नुहोस्',
  'processing': 'प्रशोधन हुँदैछ...',
  'file_size': 'साइज: {size}',
  'save': 'सुरक्षित गर्नुहोस्',
  'share': 'साझा गर्नुहोस्',
  'gallery': 'ग्यालेरी',
  'camera': 'क्यामेरा',
  'tap_to_select': 'छनोट गर्न ट्याप गर्नुहोस्',
  'add_title': '{title} थप्नुहोस्',
  'saved_to_photos': 'फोटोमा सुरक्षित भयो',
  'failed_to_save': 'सुरक्षित गर्न असफल',

  // Image Compressor
  'image_compressor_title': 'तस्बिर कम्प्रेसर',
  'compress_images': 'तस्बिर कम्प्रेस गर्नुहोस्',
  'compress_desc': 'गुणस्तर कायम राख्दै तस्बिर फाइल साइज घटाउनुहोस्',
  'select_image': 'तस्बिर छान्नुहोस्',
  'original': 'मूल',
  'compressed': 'कम्प्रेस भएको',
  'target_size': 'लक्षित साइज',
  'compress': 'कम्प्रेस गर्नुहोस्',
  'compressing': 'कम्प्रेस हुँदैछ...',
  'compress_again': 'फेरि कम्प्रेस गर्नुहोस्',
  'compressed_under': '"{size}" भन्दा कममा कम्प्रेस भयो',
  'could_not_reach': 'लक्षित साइज पुग्न सकेन',
  'saved_smaller': '{size} सुरक्षित ({percent}% सानो)',

  // Forex
  'forex_rates': 'विदेशी मुद्रा दर',
  'nrb_rates': 'नेपाल राष्ट्र बैंक दर',
  'currency': 'मुद्रा',
  'buy': 'किन्नु',
  'sell': 'बेच्नु',
  'per_units': '{units} इकाइमा',
  'failed_load_rates': 'दरहरू लोड गर्न असफल',
  'network_error': 'नेटवर्क त्रुटि: {error}',
  'no_data': 'डाटा उपलब्ध छैन',

  // Bullion
  'gold_silver_title': 'सुन र चाँदी',
  'source': 'स्रोत: {source}',
  'today_date': 'आज ({date})',
  'gold_hallmark': 'सुन (हलमार्क)',
  'gold_tejabi': 'सुन (तेजाबी)',
  'silver': 'चाँदी',
  'per_tola': 'प्रति तोला',
  'this_week': 'यो हप्ता',
  'date': 'मिति',
  'hallmark': 'हलमार्क',
  'tejabi': 'तेजाबी',
  'failed_load_data': 'डाटा लोड गर्न असफल',

  // Government Services
  'gov_services': 'सरकारी सेवाहरू',
  'search_services': 'सेवाहरू खोज्नुहोस्...',
  'no_services': 'कुनै सेवा भेटिएन',
  'try_different': 'फरक खोज शब्द प्रयोग गर्नुहोस्',
  'could_not_open': '{url} खोल्न सकिएन',

  // How Nepal Works
  'how_nepal_works': 'नेपाल कसरी चल्छ',
  'structure': 'संरचना',
  'law_making': 'कानून निर्माण',
  'cabinet': 'मन्त्रिपरिषद्',
  'federal_parliament': 'संघीय संसद (द्विसदनात्मक)',
  'seats': '{count} सिटहरू',
  'special_bills': 'विशेष प्रकारका विधेयकहरू',
  'last_updated_date': 'अन्तिम अपडेट: {date}',
  'source_opmcm': 'स्रोत: opmcm.gov.np',

  // Common Actions
  'cancel': 'रद्द गर्नुहोस्',
  'ok': 'ठीक छ',
  'done': 'भयो',
  'close': 'बन्द गर्नुहोस्',
  'yes': 'हो',
  'no': 'होइन',
  'loading': 'लोड हुँदैछ...',
  'error': 'त्रुटि',
  'success': 'सफल',
  'warning': 'चेतावनी',

  // Error Messages
  'something_went_wrong': 'केही गडबड भयो',
  'no_internet': 'इन्टरनेट जडान छैन',
  'try_again': 'कृपया फेरि प्रयास गर्नुहोस्',
};

const _newariStrings = {
  // App General
  'app_name': 'नेपाल नागरिक',

  // Navigation
  'nav_calendar': 'पात्रो',
  'nav_home': 'छेँ',
  'nav_ipo': 'आईपीओ',
  'nav_rights': 'अधिकार',
  'explore': 'अन्वेषण',
  'utilities': 'उपकरणथें',
  'govt': 'सरकार',
  'map': 'नक्सा',
  'rights': 'अधिकार',

  // Utility Cards
  'citizenship_merger': 'नागरिकता मर्जर',
  'image_compressor': 'फोटो कम्प्रेस',
  'calendar': 'पात्रो',
  'date_convert': 'मिति परिवर्तक',
  'forex': 'विदेशी मुद्रा',
  'gold_silver': 'लुँ/चाँदी',

  // Settings
  'settings': 'सेटिङ',
  'language_display': 'भाषा व प्रदर्शन',
  'data_updates': 'डाटा व अपडेट',
  'notifications': 'सूचनाथें',
  'about': 'बारेया',
  'language': 'भाषा',
  'theme': 'थिम',
  'auto_check_updates': 'स्वचालित अपडेट जाँच',
  'auto_check_updates_desc': 'एप खोलय् नयाँ डाटा जाँच याय्',
  'check_updates_now': 'अले अपडेट जाँच याय्',
  'check_updates_now_desc': 'नयाँ नेता डाटा डाउनलोड याय्',
  'clear_cache': 'क्यास खाली याय्',
  'clear_cache_desc': 'भण्डारण ठाउँ खाली याय्',
  'sticky_date_notification': 'स्थायी मिति सूचना',
  'sticky_date_notification_desc': 'थौं नेपाली मिति सूचना पट्टीया क्यनेगु',
  'ipo_alerts': 'आईपीओ सूचना',
  'ipo_alerts_desc': 'आईपीओ खुलय् वा बन्द जुलय् सूचना काय्',
  'checking_updates': 'अपडेट जाँच यानाच्वँ...',
  'cache_cleared': 'क्यास खाली जुल',
  'app_version': 'नेपाल नागरिक एप v1.0.0',

  // Theme Options
  'theme_system': 'सिस्टम',
  'theme_light': 'ज्वः',
  'theme_dark': 'मिखा',
  'theme_system_desc': 'उपकरण सेटिङ अनुसरण याय्',
  'theme_light_desc': 'सदां ज्वःगु थिम',
  'theme_dark_desc': 'सदां मिखागु थिम',
  'choose_theme': 'थिम ल्ययादिसँ',

  // Language Options
  'choose_language': 'भाषा ल्ययादिसँ',
  'both_languages': 'निसें भाषा',
  'nepali_language': 'नेपाली',
  'english_language': 'अंग्रेजी',
  'newari_language': 'नेपाल भाषा',
  'maithili_language': 'मैथिली',

  // Constitution
  'know_your_rights': 'छिगु हक सय्कादिसँ',
  'preamble': 'प्रस्तावना',
  'part_number': 'भाग {number}',
  'article_number': 'धारा {number}',
  'search_articles': 'धाराथें मालादिसँ...',
  'no_results': '"{query}" या लागि खँ मदु',
  'file_complaint': 'उजुरी बियादिसँ',
  'articles': 'धाराथें',

  // View Mode
  'both': 'निसें',
  'nepali': 'नेपाली',
  'english': 'अंग्रेजी',
  'paragraph': 'अनुच्छेद',
  'sentence': 'वाक्य',

  // Leaders
  'leaders': 'नेताथें',
  'sort': 'क्रमबद्ध',
  'filter': 'फिल्टर',
  'sort_by': 'क्रमबद्ध यायेमा',
  'name': 'नां',
  'district': 'जिल्ला',
  'party': 'पार्टी',
  'search_leaders': 'नेताथें मालादिसँ...',
  'no_leaders_match': 'छिगु फिल्टरं खँग्व नेता मिलल मखु',
  'no_leaders_found': 'खँग्व नेता मदु',
  'filters': 'फिल्टरथें',
  'clear_all': 'जक्व थायेकादिसँ',
  'leaders_count': '{count} नेताथें',
  'filter_by_district': 'जिल्ला कथं फिल्टर',
  'select_district': 'जिल्ला ल्ययादिसँ',
  'clear': 'थायेकादिसँ',
  'province': 'प्रदेश {number}',
  'districts_count': '{count} जिल्लाथें',

  // Leader Detail
  'biography': 'जीवनी',
  'no_biography': 'जीवनी मदु।',
  'view_all_leaders': 'जक्व नेताथें स्वयादिसँ',

  // Map
  'nepal_districts': 'नेपाल जिल्लाथें',
  'filter_by_province': 'प्रदेश कथं फिल्टर',
  'reset_zoom': 'जुम रिसेट',
  'no_leaders_district': '{district} या खँग्व नेता मदु',

  // Calendar
  'nepali_calendar': 'नेपाली पात्रो',
  'today': 'थौं',
  'previous_month': 'न्हापाया लः',
  'next_month': 'अप्वया लः',
  'holiday': 'बिदा',
  'event': 'कार्यक्रम',
  'auspicious': 'शुभ',
  'no_events': 'खँग्व कार्यक्रम मदु',

  // IPO
  'ipo_shares': 'आईपीओ व सेयर',
  'ipo_list': 'आईपीओ सूची',
  'todays_price': 'थौंया मोल',
  'source_cdsc': 'स्रोत: सीडीएससी नेपाल',
  'updated_ago': '{time} न्ह्यःने अपडेट जुल',
  'open_cdsc': 'सीडीएससी वेबसाइट हायेकादिसँ',
  'no_active_ipos': 'खँग्व सक्रिय आईपीओ मदु',
  'check_later': 'नयाँ सूचीया लागि लिपा जाँच यायेमा',
  'refresh': 'ताजा याय्',
  'retry': 'दोबारा यायेमा',
  'open_for_application': 'आवेदनया लागि खुला',
  'closes_today': 'थौं बन्द जुइ!',
  'closes_tomorrow': 'गबले बन्द जुइ',
  'opens_tomorrow': 'गबले खुलइ',
  'opens_in_days': '{days} न्हिइ खुलइ',
  'closed': 'बन्द',
  'issued_units': 'जारी इकाइथें',
  'applications': 'आवेदनथें',
  'applied_units': 'आवेदित इकाइथें',
  'total_amount': 'जक्व रकम',
  'opens': 'खुलइ',
  'closes': 'बन्द जुइ',
  'last_updated': 'लिपाया अपडेट: {time}',
  'issue_manager': 'इश्यू म्यानेजर: {name}',
  'search_symbol': 'सिम्बल वा कम्पनी मालादिसँ...',
  'top_volume': 'उच्च भोल्युम',
  'top_gainers': 'उच्च लाभ',
  'top_losers': 'उच्च घाटा',
  'source_merolagani': 'स्रोत: मेरोलगानी',
  'market_unavailable': 'बजार डाटा मदु',
  'market_closed': 'बजार बन्द जुइफु वा डाटा लोड जुयाच्वँ',
  'vol': 'भोल्युम',

  // Date Converter
  'date_converter': 'मिति परिवर्तक',
  'bs_to_ad': 'बि.सं. → ई.सं.',
  'ad_to_bs': 'ई.सं. → बि.सं.',
  'bs_to_gregorian': 'बिक्रम सम्बत → ग्रेगोरियन',
  'gregorian_to_bs': 'ग्रेगोरियन → बिक्रम सम्बत',
  'year': 'दँ',
  'month': 'लः',
  'day': 'न्हि',
  'gregorian_date': 'ग्रेगोरियन मिति (ई.सं.)',
  'bikram_sambat': 'बिक्रम सम्बत (बि.सं.)',
  'invalid_bs_date': 'अवैध बि.सं. मिति',
  'select_date': 'मिति ल्ययादिसँ',

  // Citizenship Merger
  'citizenship_photo_merger': 'नागरिकता फोटो मर्जर',
  'reset': 'रिसेट',
  'merger_instructions': 'नागरिकताया न्ह्यः व लिपाया फोटो तयार च्वनेगु।',
  'front_side': 'न्ह्यःया भाग',
  'back_side': 'लिपाया भाग',
  'merge_photos': 'फोटो मर्ज याय्',
  'processing': 'प्रशोधन जुयाच्वँ...',
  'file_size': 'साइज: {size}',
  'save': 'सुरक्षित याय्',
  'share': 'ब्वनेगु',
  'gallery': 'ग्यालेरी',
  'camera': 'क्यामेरा',
  'tap_to_select': 'ल्ययेत ट्याप यायेमा',
  'add_title': '{title} तयेमा',
  'saved_to_photos': 'फोटोय् सुरक्षित जुल',
  'failed_to_save': 'सुरक्षित याये मजिउ',

  // Image Compressor
  'image_compressor_title': 'तस्बिर कम्प्रेसर',
  'compress_images': 'तस्बिर कम्प्रेस याय्',
  'compress_desc': 'गुणस्तर कायम यानाच्वँ तस्बिर फाइल साइज थाकेमा',
  'select_image': 'तस्बिर ल्ययादिसँ',
  'original': 'मूल',
  'compressed': 'कम्प्रेस जूगु',
  'target_size': 'लक्षित साइज',
  'compress': 'कम्प्रेस याय्',
  'compressing': 'कम्प्रेस जुयाच्वँ...',
  'compress_again': 'दोबारा कम्प्रेस याय्',
  'compressed_under': '{size} भन्दा ल्याय् कम्प्रेस जुल',
  'could_not_reach': 'लक्षित साइज वने मजिउ',
  'saved_smaller': '{size} सुरक्षित ({percent}% ल्याय्)',

  // Forex
  'forex_rates': 'विदेशी मुद्रा दर',
  'nrb_rates': 'नेपाल राष्ट्र बैंक दर',
  'currency': 'मुद्रा',
  'buy': 'ज्वय्',
  'sell': 'हनेगु',
  'per_units': '{units} इकाइय',
  'failed_load_rates': 'दरथें लोड याये मजिउ',
  'network_error': 'नेटवर्क त्रुटि: {error}',
  'no_data': 'डाटा मदु',

  // Bullion
  'gold_silver_title': 'लुँ व चाँदी',
  'source': 'स्रोत: {source}',
  'today_date': 'थौं ({date})',
  'gold_hallmark': 'लुँ (हलमार्क)',
  'gold_tejabi': 'लुँ (तेजाबी)',
  'silver': 'चाँदी',
  'per_tola': 'प्रति तोला',
  'this_week': 'थौंया हप्ता',
  'date': 'मिति',
  'hallmark': 'हलमार्क',
  'tejabi': 'तेजाबी',
  'failed_load_data': 'डाटा लोड याये मजिउ',

  // Government Services
  'gov_services': 'सरकारी सेवाथें',
  'search_services': 'सेवाथें मालादिसँ...',
  'no_services': 'खँग्व सेवा मदु',
  'try_different': 'अलग माला शब्द प्रयोग यायेमा',
  'could_not_open': '{url} हाकाये मजिउ',

  // How Nepal Works
  'how_nepal_works': 'नेपाल गुकथं वनी',
  'structure': 'संरचना',
  'law_making': 'कानून निर्माण',
  'cabinet': 'मन्त्रिपरिषद्',
  'federal_parliament': 'संघीय संसद (द्विसदनात्मक)',
  'seats': '{count} सिटथें',
  'special_bills': 'विशेष प्रकारया विधेयकथें',
  'last_updated_date': 'लिपाया अपडेट: {date}',
  'source_opmcm': 'स्रोत: opmcm.gov.np',

  // Common Actions
  'cancel': 'रद्द याय्',
  'ok': 'ज्यू',
  'done': 'जुल',
  'close': 'बन्द याय्',
  'yes': 'खः',
  'no': 'मखु',
  'loading': 'लोड जुयाच्वँ...',
  'error': 'त्रुटि',
  'success': 'सफल',
  'warning': 'चेतावनी',

  // Error Messages
  'something_went_wrong': 'छुं गडबड जुल',
  'no_internet': 'इन्टरनेट जडान मदु',
  'try_again': 'कृपया दोबारा यायेमा',
};

/// Maithili strings - to be translated by community
/// Falls back to Nepali when translation is not available
const _maithiliStrings = <String, String>{
  // App General
  'app_name': 'नेपाल नागरिक',

  // Navigation
  'nav_calendar': 'पंजी',
  'nav_home': 'घर',
  'nav_ipo': 'आईपीओ',
  'nav_rights': 'अधिकार',

  // Language Options
  'maithili_language': 'मैथिली',

  // Add more Maithili translations here...
  // Contributors can add translations from the CSV file
};
