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

  DateTime? _lastQuoteFetch;
  Map<String, dynamic>? _cachedQuote;

  Future<Map<String, dynamic>> fetchQuote(String symbol) async {
    // Cache for 60 seconds to prevent 429
    if (_lastQuoteFetch != null && 
        _cachedQuote != null &&
        DateTime.now().difference(_lastQuoteFetch!).inSeconds < 60) {
      return _cachedQuote!;
    }

    try {
      final url = Uri.parse('$_baseUrl/quote?symbol=$symbol&apikey=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'error') return {};
        
        _lastChange = double.tryParse(data['percent_change']?.toString() ?? '0.0') ?? 0.0;
        _lastPrice = double.tryParse(data['price']?.toString() ?? '0.0') ?? 0.0;
        
        _cachedQuote = data;
        _lastQuoteFetch = DateTime.now();
        return data;
      } else if (response.statusCode == 429) {
        print('TwelveData Quote: 429 Rate Limit');
        return _cachedQuote ?? {};
      }
    } catch (e) {
      print('fetchQuote Error: $e');
    }
    return _cachedQuote ?? {};
  }

  Future<List<Candle>> fetchGoldCandles({String interval = '4h', int outputSize = 100}) async {
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
      return _cachedCandles;
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
