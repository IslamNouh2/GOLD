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

    // 2. Initial sync with a small delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isSyncing) sync();
    });
    
    // 3. Periodic full sync every 15 minutes (increased from 5 to avoid 429)
    Timer.periodic(const Duration(minutes: 15), (timer) {
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
      final success = await _scraper.scrapeAll().timeout(const Duration(seconds: 30));
      
      if (success) {
        _lastSync = DateTime.now();
        _isInitialLoading = false;
        _isOffline = false;
        logger.log('Sync Successful');
      } else {
        _isOffline = true;
        logger.log('Sync Failed: Scraper returned false');
      }
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
    
    // Twelve Data is now ONLY used for the chart, not for dashboard rates.
    
    if (rates.isEmpty) {
      // We no longer provide hardcoded fallback data.
      // Returning empty will trigger the Landing Screen (Loading).
      _isInitialLoading = true;
    } else {
      _isInitialLoading = false;
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
