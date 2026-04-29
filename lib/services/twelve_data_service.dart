import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/candle_model.dart';

class TwelveDataService {
  static final TwelveDataService _instance = TwelveDataService._internal();
  factory TwelveDataService() => _instance;
  TwelveDataService._internal();

  static const String _apiKey = 'a4b6863a6655425e82ede6e651c2738d';
  static const String _baseUrl = 'https://api.twelvedata.com';

  List<Candle> _cachedCandles = [];
  DateTime? _lastFetchTime;
  
  double? _lastPrice;
  double? _lastChange;

  List<Candle> get cachedCandles => _cachedCandles;
  double? get lastPrice => _lastPrice;
  double? get lastChange => _lastChange;

  Future<List<Candle>> fetchGoldCandles({String interval = '5min', int outputSize = 100}) async {
    // Optimization: Don't fetch if last fetch was less than 55 seconds ago
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!).inSeconds < 55 && 
        _cachedCandles.isNotEmpty) {
      return _cachedCandles;
    }

    try {
      final url = Uri.parse('$_baseUrl/time_series?symbol=XAU/USD&interval=$interval&outputsize=$outputSize&apikey=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'error') {
          throw Exception(data['message'] ?? 'API Error');
        }

        if (data['values'] != null) {
          final List<dynamic> values = data['values'];
          final List<Candle> candles = values.map((v) => Candle.fromTwelveData(v)).toList();
          
          _cachedCandles = candles.reversed.toList();
          
          if (_cachedCandles.isNotEmpty) {
            _lastPrice = _cachedCandles.last.close;
            final firstPrice = _cachedCandles.first.close;
            _lastChange = ((_lastPrice! - firstPrice) / firstPrice) * 100;
          }

          _lastFetchTime = DateTime.now();
          return _cachedCandles;
        }
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded (429). Please wait.');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('TwelveDataService Error: $e');
      rethrow;
    }
    
    return _cachedCandles;
  }

  /// Silent fetch for background updates (respects same cache)
  Future<void> silentFetch() async {
    try {
      await fetchGoldCandles();
    } catch (_) {}
  }
}
