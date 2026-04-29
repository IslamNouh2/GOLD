import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'database_service.dart';
import 'logger_service.dart';

class ScraperService {
  final DatabaseService _db = DatabaseService();
  static const String goldApiKey = '544786918e979e7739e8d3059dd38285c4020709f158a2df2b171d7515987c98';

  // Proxy for Web to bypass CORS
  String _proxyUrl(String url) {
    if (kIsWeb) {
      // Using corsproxy.io with cache busting
      final ts = DateTime.now().millisecondsSinceEpoch;
      final separator = url.contains('?') ? '&' : '?';
      final cleanUrl = url.contains('gold-api.com') ? url : '$url${separator}cb=$ts';
      return 'https://corsproxy.io/?${Uri.encodeComponent(cleanUrl)}';
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
      // Primary: Gold-API.com (Free & Reliable)
      final response = await http.get(
        Uri.parse(_proxyUrl('https://api.gold-api.com/price/XAU')),
        headers: {'x-api-key': goldApiKey},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final spotPriceOunce = (data['price'] as num).toDouble();
        
        print('--- GOLD-API.COM DEBUG ---');
        print('API Raw Ounce: \$$spotPriceOunce');
        
        await _updateGoldRate('XAU/USD', spotPriceOunce, 0.0, rawPrice: spotPriceOunce);
        return;
      } else {
        LoggerService().log('Gold-API.com Error: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService().log('Gold-API.com Primary Error: $e');
    }

    // Secondary: Twelve Data (Fallback)
    try {
      final response = await http.get(
        Uri.parse(_proxyUrl('https://api.twelvedata.com/price?symbol=XAU/USD&apikey=a4b6863a6655425e82ede6e651c2738d')),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['price'] != null) {
          final spotPriceOunce = double.parse(data['price']);
          LoggerService().log('Twelve Data Fallback: Spot Ounce: \$$spotPriceOunce');
          await _updateGoldRate('XAU/USD', spotPriceOunce, 0.0, rawPrice: spotPriceOunce);
          return;
        }
      }
    } catch (e) {
      LoggerService().log('Twelve Data Fallback Error: $e');
    }

    // Last Resort: Web Scraping Fallback
    await _fallbackGoldScraper();
  }

  Future<void> _fallbackGoldScraper() async {
    try {
      // Scraping goldprice.org as a robust fallback
      final response = await http.get(Uri.parse(_proxyUrl('https://goldprice.org/'))).timeout(const Duration(seconds: 20));
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
    final latestRates = await _db.getLatestRates();
    double change = 0.0;
    
    try {
      final prev = latestRates.firstWhere((e) => e['symbol'] == symbol);
      final prevPrice = prev['sale_price'] as double;
      if (prevPrice > 0) {
        change = ((price - prevPrice) / prevPrice) * 100;
        print('Calculated Change: ${change.toStringAsFixed(4)}%');
      }
    } catch (_) {
      // No previous rate found
    }

    await _db.insertRate({
      'symbol': symbol,
      'purchase_price': rawPrice ?? price,
      'sale_price': price,
      'change': change,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> scrapeEuroDZ() async {
    try {
      final response = await http.get(Uri.parse(_proxyUrl('https://eurodz.com/'))).timeout(const Duration(seconds: 20));
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


