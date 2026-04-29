import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Dahabi Premium',
      'welcome_msg': 'Real-time monitoring of gold and currency prices in the Algerian parallel market.',
      'gold_spot': 'GOLD SPOT',
      'unit_oz': 'USD/OZ',
      'live_market': 'LIVE MARKET • SQUARE DZ',
      'asset_type': 'Asset / Type',
      'buy': 'Buy',
      'sell': 'Sell',
      'change': 'Change',
      'gold_24k': 'Gold 24K (Karats)',
      'gold_21k': 'Gold 21K (Karats)',
      'gold_18k': 'Gold 18K (Karats)',
      'gold_12k': 'Gold 12K (Karats)',
      'no_connection': 'No Connection to Server',
      'check_internet': 'Please check your internet connection and try again',
      'retry': 'Retry',
      'last_updated': 'Last Updated',
      'offline_data': 'Offline Data',
      'today': 'today',
      'gold_spot_label': 'Global Gold Price',
      'gram_24k_label': 'Gram Price · 24K',
      'per_ounce': 'per ounce',
      'dzd_currency': 'Algerian Dinar',
      'col_type': 'Type',
      'col_buy': 'Buy (1g)',
      'col_sell': 'Sell (1g)',
      'one_gram': '1 gram',
    },
    'ar': {
      'app_title': 'ذهبي بريميوم',
      'welcome_msg': 'مراقبة لحظية لأسعار الذهب والعملات في السوق الموازي الجزائري',
      'gold_spot': 'سعر الذهب العالمي',
      'unit_oz': 'دولار/أونصة',
      'live_market': 'السوق المباشر • السكوار',
      'asset_type': 'الأصل / النوع',
      'buy': 'شراء',
      'sell': 'بيع',
      'change': 'تغير',
      'gold_24k': 'ذهب عيار 24 (قراط)',
      'gold_21k': 'ذهب عيار 21 (قراط)',
      'gold_18k': 'ذهب عيار 18 (قراط)',
      'gold_12k': 'ذهب عيار 12 (قراط)',
      'no_connection': 'لا يوجد اتصال بالخادم',
      'check_internet': 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
      'retry': 'إعادة المحاولة',
      'last_updated': 'آخر تحديث',
      'offline_data': 'بيانات غير متصلة',
      'today': 'اليوم',
      'gold_spot_label': 'سعر الذهب العالمي',
      'gram_24k_label': 'سعر الجرام · 24K',
      'per_ounce': 'للأونصة',
      'dzd_currency': 'دينار جزائري',
      'col_type': 'النوع',
      'col_buy': 'شراء (1غ)',
      'col_sell': 'بيع (1غ)',
      'one_gram': '1 جرام',
    },
    'fr': {
      'app_title': 'Dahabi Premium',
      'welcome_msg': 'Suivi en temps réel des prix de l\'or et des devises sur le marché parallèle algérien.',
      'gold_spot': 'SPOT OR',
      'unit_oz': 'USD/OZ',
      'live_market': 'MARCHÉ LIVE • SQUARE DZ',
      'asset_type': 'Actif / Type',
      'buy': 'Achat',
      'sell': 'Vente',
      'change': 'Changement',
      'gold_24k': 'Or 24K (Carats)',
      'gold_21k': 'Or 21K (Carats)',
      'gold_18k': 'Or 18K (Carats)',
      'gold_12k': 'Or 12K (Carats)',
      'no_connection': 'Pas de connexion au serveur',
      'check_internet': 'Veuillez vérifier votre connexion internet et réessayer',
      'retry': 'Réessayer',
      'last_updated': 'Dernière mise à jour',
      'offline_data': 'Données hors ligne',
      'today': 'aujourd\'hui',
      'gold_spot_label': 'Prix de l\'or mondial',
      'gram_24k_label': 'Prix du gramme · 24K',
      'per_ounce': 'par once',
      'dzd_currency': 'Dinar Algérien',
      'col_type': 'Type',
      'col_buy': 'Achat (1g)',
      'col_sell': 'Vente (1g)',
      'one_gram': '1 gramme',
    },
  };


  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String l10n(String key) => AppLocalizations.of(this)?.translate(key) ?? key;
}
