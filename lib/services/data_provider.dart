import 'dart:async';
import 'database_service.dart';
import 'scraper_service.dart';
import 'twelve_data_service.dart';

class DataProvider {
  static final DataProvider _instance = DataProvider._internal();
  factory DataProvider() => _instance;
  DataProvider._internal();

  final DatabaseService _db = DatabaseService();
  final ScraperService _scraper = ScraperService();

  final _ratesController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get ratesStream => _ratesController.stream;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  bool _isInitialLoading = true;
  bool _isOffline = false;
  bool get isInitialLoading => _isInitialLoading;
  bool get isOffline => _isOffline;

  void init() {
    // Initial sync immediately
    sync();
    
    // Perform a full sync (scrape + refresh) every 2 minutes
    Timer.periodic(const Duration(minutes: 2), (timer) {
      sync();
    });

    // Frequent refresh from DB to ensure UI is snappy (every 5 seconds)
    Timer.periodic(const Duration(seconds: 5), (timer) {
      refreshRates();
    });
  }

  Future<void> sync() async {
    print('>>> TRIGGERING FULL SYNC <<<');
    try {
      await _scraper.scrapeAll();
      _lastSync = DateTime.now();
      _isInitialLoading = false;
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
    }
    await refreshRates();
  }

  Future<void> refreshRates() async {
    final rates = await _db.getLatestRates();
    
    // Inject latest Twelve Data price if available to keep everything in sync
    final td = TwelveDataService();
    if (td.lastPrice != null) {
      final xauIndex = rates.indexWhere((e) => e['symbol'] == 'XAU/USD');
      final tdRate = {
        'symbol': 'XAU/USD',
        'purchase_price': td.lastPrice!, 
        'sale_price': td.lastPrice!,      // Keep as Ounce ($4600+)
        'change': td.lastChange ?? 0.0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (xauIndex != -1) {
        rates[xauIndex] = tdRate;
      } else {
        rates.add(tdRate);
      }
    }

    if (rates.isNotEmpty) {
      _isInitialLoading = false;
    }
    
    _ratesController.add({
      'rates': rates,
      'timestamp': _lastSync ?? DateTime.now(),
      'isInitial': _isInitialLoading,
      'isOffline': _isOffline,
    });
  }

  void dispose() {
    _ratesController.close();
  }
}
