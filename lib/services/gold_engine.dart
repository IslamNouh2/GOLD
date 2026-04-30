import 'dart:math';

/// A professional pricing engine for Gold assets.
/// Handles purity conversions, currency exchange, and buy/sell spread calculations.
class GoldPricingEngine {
  static const double spreadFactor = 0.985; // 1.5% spread for Achat

  /// Calculates gold prices for various purities in DZD.
  /// [priceGram24kUSD]: Base price from the gold API in USD per gram.
  /// [usdDzdRate]: The dynamic black market (square) rate.
  static Map<String, dynamic> calculateAllPrices({
    required double priceGram24kUSD,
    required double usdDzdRate,
  }) {
    if (priceGram24kUSD <= 0 || usdDzdRate <= 0) {
      return {};
    }

    // Purities mapping based on user requirements
    final purities = {
      '18K': 0.75,
      '21K': 0.875,
      '24K': 1.0,
    };

    final Map<String, dynamic> results = {};

    purities.forEach((key, factor) {
      // 1. Calculate Sell Price (Vente)
      // Formula: (USD/g) * (USD/DZD Rate) * PurityFactor
      final double vente = priceGram24kUSD * usdDzdRate * factor;

      // 2. Calculate Buy Price (Achat) with 1.5% spread
      // Formula: Vente * 0.985
      final double achat = vente * spreadFactor;

      results[key] = {
        'vente': _roundToTwo(vente),
        'achat': _roundToTwo(achat),
      };
    });

    return results;
  }

  /// Specialized function for a single asset calculation
  static Map<String, double> calculateSingle(double priceGram24kUSD, double usdDzdRate, double purity) {
    final vente = priceGram24kUSD * usdDzdRate * purity;
    return {
      'vente': _roundToTwo(vente),
      'achat': _roundToTwo(vente * spreadFactor),
    };
  }

  static double _roundToTwo(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
