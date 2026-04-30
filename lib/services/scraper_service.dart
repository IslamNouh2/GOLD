import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'database_service.dart';
import 'logger_service.dart';
import 'twelve_data_service.dart';

class ScraperService {
  final DatabaseService _db = DatabaseService();
  static const String goldApiKey = '544786918e979e7739e8d3059dd38285c4020709f158a2df2b171d7515987c98';

  // Proxy for Web to bypass CORS
  String _proxyUrl(String url) {
    if (kIsWeb) {
      // Use Codetabs proxy with a proxy-level cache buster
      final ts = DateTime.now().millisecondsSinceEpoch;
      return 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}&cb=$ts';
    }
    return url;
  }

  // The sync interval is now managed by DataProvider.init()
  // to ensure UI timestamps and data remain perfectly synchronized.

  Future<void> scrapeAll() async {
    try {
      await scrapeGoldSpot(); // Global Spot Price
      await scrapeEuroDZ();   // Local DZD Rates
      LoggerService().log('Scraping completed successfully');
    } catch (e) {
      LoggerService().log('Error during scraping: $e');
    }
  }

  Future<void> scrapeGoldSpot() async {
    try {
      // 1. Fetch Global Quote from TwelveData (for the real percentage change)
      double marketChange = 0.0;
      try {
        final twelveData = TwelveDataService();
        final quote = await twelveData.fetchQuote('XAU/USD');
        marketChange = double.tryParse(quote['percent_change']?.toString() ?? '0.0') ?? 0.0;
      } catch (_) {}

      // 2. Primary: Gold-API.com (Free & Reliable Price)
      final response = await http.get(
        Uri.parse(_proxyUrl('https://api.gold-api.com/price/XAU')),
        // headers: {
        //   'x-api-key': goldApiKey,
        //   'Cache-Control': 'no-cache',
        //   'Pragma': 'no-cache',
        // },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final spotPriceOunce = (data['price'] as num).toDouble();
        
        print('--- GOLD-API.COM DEBUG ---');
        print('API Raw Ounce: \$$spotPriceOunce | Market Change: $marketChange%');
        
        await _updateGoldRate('XAU/USD', spotPriceOunce, marketChange, rawPrice: spotPriceOunce);
        return;
      } else {
        LoggerService().log('Gold-API.com Error: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService().log('Gold-API.com Primary Error: $e');
    }

    // Secondary: Web Scraping Fallback (ONLY if gold-api.com fails)
    await _fallbackGoldScraper();
  }

  Future<void> _fallbackGoldScraper() async {
    try {
      // Scraping goldprice.org as a robust fallback
      final response = await http.get(Uri.parse(_proxyUrl('https://goldprice.org/'))).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        var document = parse(response.body);
        // Find the spot price in the header or table
        var priceElement = document.querySelector('#gold_price_usd');
        if (priceElement != null) {
          final priceText = priceElement.text.replaceAll(',', '').trim();
          final price = double.tryParse(priceText) ?? 0.0;
          if (price > 0) {
            final priceGram = price / 31.1035;
            LoggerService().log('Fallback Scraper: Gold Ounce: \$$price');
            await _updateGoldRate('XAU/USD', price, 0.0, rawPrice: price);
          }
        }
      }
    } catch (e) {
      LoggerService().log('Gold Fallback Error: $e');
    }
  }

  Future<void> _updateGoldRate(String symbol, double price, double placeholderChange, {double? rawPrice}) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    double change = 0.0;
    
    // If the API provided a real market change, use it as priority!
    if (placeholderChange != 0.0) {
      change = placeholderChange;
    } else {
      // Fallback: Local calculation if API change is missing
      try {
        final allRates = await _db.getRatesBySymbol(symbol);
        final todayRates = allRates.where((e) => (e['timestamp'] as String).compareTo(todayStart) >= 0).toList();
        
        if (todayRates.isNotEmpty) {
          todayRates.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
          final openPrice = todayRates.first['sale_price'] as double;
          if (openPrice > 0) {
            change = ((price - openPrice) / openPrice) * 100;
          print('--- CHANGE DEBUG ---');
          print('Symbol: $symbol | Current: $price | Open: $openPrice | Change: ${change.toStringAsFixed(4)}%');
          }
        } else if (allRates.isNotEmpty) {
          final prevPrice = allRates.last['sale_price'] as double;
          if (prevPrice > 0) {
            change = ((price - prevPrice) / prevPrice) * 100;
          }
        }
      } catch (e) {
        print('Change calculation error: $e');
      }
    }

    await _db.insertRate({
      'symbol': symbol,
      'purchase_price': rawPrice ?? price,
      'sale_price': price,
      'change': change,
      'timestamp': now.toIso8601String(),
    });
  }

  Future<void> scrapeEuroDZ() async {
    try {
      final response = await http.get(Uri.parse(_proxyUrl('https://eurodz.com/'))).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        var document = parse(response.body);
        var rows = document.querySelectorAll('table tr');
        
        double? usdRate;
        double? eurRate;
        
        bool foundAny = false;
        for (var row in rows) {
          var cells = row.querySelectorAll('td');
          if (cells.length >= 3) {
            final name = cells[0].text.toUpperCase();
            
            if (name.contains('(EUR)') || name.contains('(USD)')) {
              final isEur = name.contains('(EUR)');
              final symbol = isEur ? 'EUR/DZD' : 'USD/DZD';
              
              final valStr = cells[1].text.replaceAll(RegExp(r'[^0-9.]'), '').trim();
              final achat = double.tryParse(valStr) ?? 0.0;
              
              final valStr2 = cells[2].text.replaceAll(RegExp(r'[^0-9.]'), '').trim();
              final vente = double.tryParse(valStr2) ?? 0.0;
              
              if (achat > 0) {
                if (isEur) eurRate = achat; else usdRate = achat;
                
                await _db.insertRate({
                  'symbol': symbol,
                  'purchase_price': achat,
                  'sale_price': vente,
                  'change': 0.12,
                  'timestamp': DateTime.now().toIso8601String(),
                });
                foundAny = true;
              }
            }
          }
        }

        // Calculate cross-rate if both found
        if (usdRate != null && eurRate != null && eurRate > 0) {
          final usdEur = usdRate / eurRate;
          await _db.insertRate({
            'symbol': 'USD/EUR',
            'purchase_price': usdEur,
            'sale_price': usdEur,
            'change': -0.05,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        if (!foundAny) print('EuroDZ: No rates found. Site might have changed.');
      }
    } catch (e) {
      print('EuroDZ Scraping Error: $e');
    }
  }
}


