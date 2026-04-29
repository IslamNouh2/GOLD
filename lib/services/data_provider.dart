import 'dart:async';
import 'database_service.dart';
import 'scraper_service.dart';
import 'twelve_data_service.dart';
import 'logger_service.dart';

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
  bool _isSyncing = false;
  bool get isInitialLoading => _isInitialLoading;
  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;

  void init() {
    // 1. Emit cached data immediately to avoid black screen on launch
    refreshRates();

    // 2. Initial sync with a small delay to let UI settle
    Future.delayed(const Duration(milliseconds: 500), () => sync());
    
    // 3. Periodic full sync every 5 minutes (reduced from 2 to save battery/bandwidth)
    Timer.periodic(const Duration(minutes: 5), (timer) {
      sync();
    });

    // 4. Frequent refresh from DB (every 5 seconds)
    Timer.periodic(const Duration(seconds: 5), (timer) {
      refreshRates();
    });
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    final logger = LoggerService();
    logger.log('>>> TRIGGERING FULL SYNC <<<');
    try {
      // Add a 30s timeout to the entire sync process
      await _scraper.scrapeAll().timeout(const Duration(seconds: 30));
      _lastSync = DateTime.now();
      _isInitialLoading = false;
      _isOffline = false;
      logger.log('Sync Successful');
    } catch (e) {
      logger.log('Sync Error: $e');
      _isOffline = true;
    } finally {
      _isSyncing = false;
      await refreshRates();
    }
  }

  Future<void> refreshRates() async {
    final rates = List<Map<String, dynamic>>.from(await _db.getLatestRates());
    
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

    if (rates.isEmpty) {
      // Fallback data to prevent black screen on first launch if sync is slow
      final now = DateTime.now().toIso8601String();
      rates.addAll([
        {'symbol': 'XAU/USD', 'purchase_price': 2350.0, 'sale_price': 2350.0, 'change': 0.0, 'timestamp': now},
        {'symbol': 'USD/DZD', 'purchase_price': 238.0, 'sale_price': 240.0, 'change': 0.0, 'timestamp': now},
        {'symbol': 'EUR/DZD', 'purchase_price': 255.0, 'sale_price': 258.0, 'change': 0.0, 'timestamp': now},
      ]);
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
