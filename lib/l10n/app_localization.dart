import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('sw')];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'SERIK App',
      'home': 'Home',
      'videos': 'Videos',
      'map': 'Map',
      'account': 'Account',
      'welcomeSerik': 'Welcome to Serik',
      'guestSubtitle': 'Preview first, log in to view details',
      'userSubtitle': 'Find safe housing with confidence',
      'heroBadge': 'Your room, in your hand',
      'heroTitle': 'Find housing near campus without guessing.',
      'heroSubtitle':
          'Filter by distance, price, safety and house videos before deciding.',
      'nearbyHouses': 'nearby homes',
      'universities': 'universities',
      'liveData': 'live data',
      'searchHint': 'Search university, area or region...',
      'all': 'All',
      'nearby': 'Nearby',
      'affordable': 'Affordable',
      'modern': 'Modern',
      'safe': 'Safe',
      'popularUniversities': 'Popular Universities',
      'countingHomes': 'Counting homes...',
      'noResults': 'No results',
      'tryAnotherFilter': 'Try another filter or keyword',
      'openVideos': 'Videos',
      'openMap': 'Map',
      'openAccount': 'Account',
      'signIn': 'Sign in',
      'register': 'Register',
      'signOut': 'Sign out',
      'unlockServices': 'Sign in to unlock all services',
      'hiddenDetailsNotice':
          'Location, price, contacts, comments and house details are hidden until the user signs in.',
      'continueSearching': 'Continue searching homes',
      'continueSearchingSubtitle': 'Return to home and map',
      'landlordDashboard': 'Landlord dashboard',
      'landlordDashboardSubtitle': 'Manage houses, map and payments',
      'signOutSubtitle': 'End your session on this device',
      'loginRequired': 'Sign in first',
      'loginRequiredDetails':
          'Please sign in to view house price, location and full details.',
      'later': 'Later',
      'hiddenPrice': 'Price hidden',
      'hiddenDistance': 'Hidden',
      'hiddenLocation': 'Sign in to view exact location',
      'houseNearCampus': 'House near campus',
      'loginStatus': 'Login',
      'videoFeedTitle': 'House Videos',
      'videoFeedEmpty': 'No uploaded videos yet',
      'videoFeedError': 'Could not load videos. Try again.',
      'retry': 'Try again',
      'loginForHouseInfo': 'Sign in to view house information',
      'viewDetails': 'View details',
      'loginForMore': 'Sign in to see more',
      'commentsReady': 'Comments UI is ready.',
      'writeComment': 'Write a comment...',
      'videoLinkCopied': 'Video link copied',
      'share': 'Share',
      'sound': 'Sound',
      'mute': 'Mute',
      'theme': 'Theme',
      'switchTheme': 'Switch theme',
      'darkMode': 'Dark mode',
      'lightMode': 'Light mode',
      'systemMode': 'System default',
      'language': 'Language',
      'english': 'English',
      'swahili': 'Swahili',
      'offline': 'Offline - App works offline',
      'offlineSync': 'Sync',
    },
    'sw': {
      'appTitle': 'SERIK App',
      'home': 'Nyumbani',
      'videos': 'Video',
      'map': 'Ramani',
      'account': 'Akaunti',
      'welcomeSerik': 'Karibu Serik',
      'guestSubtitle': 'Preview kwanza, login kuona details',
      'userSubtitle': 'Tafuta nyumba salama kwa utulivu',
      'heroBadge': 'Geto lako, kiganjani pako',
      'heroTitle': 'Pata nyumba karibu na chuo bila kubahatisha.',
      'heroSubtitle':
          'Chuja kwa umbali, bei, usalama na video za nyumba kabla ya kuamua.',
      'nearbyHouses': 'nyumba karibu',
      'universities': 'vyuo',
      'liveData': 'data hai',
      'searchHint': 'Tafuta chuo, eneo au mkoa...',
      'all': 'Zote',
      'nearby': 'Karibu',
      'affordable': 'Nafuu',
      'modern': 'Kisasa',
      'safe': 'Salama',
      'popularUniversities': 'Vyuo Vikuu Maarufu',
      'countingHomes': 'Inahesabu nyumba...',
      'noResults': 'Hakuna matokeo',
      'tryAnotherFilter': 'Jaribu filter au neno lingine',
      'openVideos': 'Video',
      'openMap': 'Ramani',
      'openAccount': 'Akaunti',
      'signIn': 'Ingia',
      'register': 'Jisajili',
      'signOut': 'Toka',
      'unlockServices': 'Ingia ili kufungua huduma zote',
      'hiddenDetailsNotice':
          'Location, bei, mawasiliano, comments na house details hufichwa mpaka user aingie.',
      'continueSearching': 'Endelea kutafuta nyumba',
      'continueSearchingSubtitle': 'Rudi kwenye homepage na ramani',
      'landlordDashboard': 'Dashboard ya mpangishaji',
      'landlordDashboardSubtitle': 'Simamia nyumba, ramani na malipo',
      'signOutSubtitle': 'Funga session yako kwenye kifaa hiki',
      'loginRequired': 'Ingia kwanza',
      'loginRequiredDetails':
          'Tafadhali ingia ili kuona bei, location na maelezo kamili ya nyumba.',
      'later': 'Baadaye',
      'hiddenPrice': 'Bei imefichwa',
      'hiddenDistance': 'Imefichwa',
      'hiddenLocation': 'Ingia kuona eneo halisi',
      'houseNearCampus': 'Nyumba karibu na chuo',
      'loginStatus': 'Login',
      'videoFeedTitle': 'Video za Nyumba',
      'videoFeedEmpty': 'Hakuna video zilizopakiwa bado',
      'videoFeedError': 'Imeshindwa kupakia video. Jaribu tena.',
      'retry': 'Jaribu tena',
      'loginForHouseInfo': 'Ingia kuona taarifa za nyumba',
      'viewDetails': 'Angalia details',
      'loginForMore': 'Ingia kuona zaidi',
      'commentsReady': 'Sehemu ya comments iko tayari kwa UI.',
      'writeComment': 'Andika comment...',
      'videoLinkCopied': 'Link ya video imenakiliwa',
      'share': 'Share',
      'sound': 'Sauti',
      'mute': 'Mute',
      'theme': 'Theme',
      'switchTheme': 'Badili theme',
      'darkMode': 'Muonekano wa giza',
      'lightMode': 'Muonekano wa mwanga',
      'systemMode': 'Chaguo la mfumo',
      'language': 'Lugha',
      'english': 'Kiingereza',
      'swahili': 'Kiswahili',
      'offline': 'Hakuna intaneti - App inafanya kazi offline',
      'offlineSync': 'Sync',
    },
  };

  String _text(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['sw']?[key] ??
      key;

  String tr(String swText, {String? en}) =>
      locale.languageCode == 'en' ? (en ?? swText) : swText;

  String get appTitle => _text('appTitle');
  String get home => _text('home');
  String get videos => _text('videos');
  String get map => _text('map');
  String get account => _text('account');
  String get welcomeSerik => _text('welcomeSerik');
  String welcomeUser(String name) =>
      locale.languageCode == 'en' ? 'Welcome, $name' : 'Karibu, $name';
  String get guestSubtitle => _text('guestSubtitle');
  String get userSubtitle => _text('userSubtitle');
  String get heroBadge => _text('heroBadge');
  String get heroTitle => _text('heroTitle');
  String get heroSubtitle => _text('heroSubtitle');
  String get nearbyHouses => _text('nearbyHouses');
  String get universities => _text('universities');
  String get liveData => _text('liveData');
  String get searchHint => _text('searchHint');
  String get all => _text('all');
  String get nearby => _text('nearby');
  String get affordable => _text('affordable');
  String get modern => _text('modern');
  String get safe => _text('safe');
  String get popularUniversities => _text('popularUniversities');
  String get countingHomes => _text('countingHomes');
  String results(int count) =>
      locale.languageCode == 'en' ? '$count results' : '$count matokeo';
  String get noResults => _text('noResults');
  String get tryAnotherFilter => _text('tryAnotherFilter');
  String get openVideos => _text('openVideos');
  String get openMap => _text('openMap');
  String get openAccount => _text('openAccount');
  String get signIn => _text('signIn');
  String get register => _text('register');
  String get signOut => _text('signOut');
  String get unlockServices => _text('unlockServices');
  String get hiddenDetailsNotice => _text('hiddenDetailsNotice');
  String get continueSearching => _text('continueSearching');
  String get continueSearchingSubtitle => _text('continueSearchingSubtitle');
  String get landlordDashboard => _text('landlordDashboard');
  String get landlordDashboardSubtitle => _text('landlordDashboardSubtitle');
  String get signOutSubtitle => _text('signOutSubtitle');
  String get loginRequired => _text('loginRequired');
  String get loginRequiredDetails => _text('loginRequiredDetails');
  String get later => _text('later');
  String get hiddenPrice => _text('hiddenPrice');
  String get hiddenDistance => _text('hiddenDistance');
  String get hiddenLocation => _text('hiddenLocation');
  String get houseNearCampus => _text('houseNearCampus');
  String get loginStatus => _text('loginStatus');
  String get videoFeedTitle => _text('videoFeedTitle');
  String get videoFeedEmpty => _text('videoFeedEmpty');
  String get videoFeedError => _text('videoFeedError');
  String get retry => _text('retry');
  String get loginForHouseInfo => _text('loginForHouseInfo');
  String get viewDetails => _text('viewDetails');
  String get loginForMore => _text('loginForMore');
  String comments(int count) =>
      locale.languageCode == 'en' ? 'Comments $count' : 'Maoni $count';
  String get commentsReady => _text('commentsReady');
  String get writeComment => _text('writeComment');
  String get videoLinkCopied => _text('videoLinkCopied');
  String get share => _text('share');
  String get sound => _text('sound');
  String get mute => _text('mute');
  String get theme => _text('theme');
  String get switchTheme => _text('switchTheme');
  String get darkMode => _text('darkMode');
  String get lightMode => _text('lightMode');
  String get language => _text('language');
  String get english => _text('english');
  String get swahili => _text('swahili');
  String get offline => _text('offline');
  String get offlineSync => _text('offlineSync');
  String get systemMode => _text('systemMode');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) {
    final selectedLocale = isSupported(locale) ? locale : const Locale('sw');
    return SynchronousFuture(AppLocalizations(selectedLocale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String swText, {String? en}) =>
      AppLocalizations.of(this).tr(swText, en: en);
}
