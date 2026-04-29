import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/dahabi_theme.dart';
import '../services/data_provider.dart';
import '../services/database_service.dart';

class GoldCandle {
  final double open;
  final double high;
  final double low;
  final double close;
  final double x;

  GoldCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.x,
  });

  GoldCandle copyWith({double? close, double? high, double? low}) {
    return GoldCandle(
      open: open,
      high: max(high ?? this.high, close ?? this.close),
      low: min(low ?? this.low, close ?? this.close),
      close: close ?? this.close,
      x: x,
    );
  }
}

class MiniGoldChart extends StatefulWidget {
  final bool isTV;
  final String timeframe; // '1min', '30min', '1h', '4h'

  const MiniGoldChart({
    super.key, 
    required this.isTV, 
    this.timeframe = '1h'
  });

  @override
  State<MiniGoldChart> createState() => _MiniGoldChartState();
}

class _MiniGoldChartState extends State<MiniGoldChart> {
  List<GoldCandle> candles = [];
  double? lastPrice;
  double lastX = 0;
  Timer? _candleTimer;
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startCandleCycle();
  }

  @override
  void dispose() {
    _candleTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MiniGoldChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeframe != widget.timeframe) {
      _loadInitialData();
      _startCandleCycle();
    }
  }

  void _startCandleCycle() {
    _candleTimer?.cancel();
    // For 1min timeframe, new candle every 5 seconds for visual density
    // For others, slower
    Duration interval = const Duration(seconds: 10);
    if (widget.timeframe == '1min') interval = const Duration(seconds: 5);
    if (widget.timeframe == '30min') interval = const Duration(seconds: 30);
    
    _candleTimer = Timer.periodic(interval, (timer) {
      if (lastPrice != null) {
        _addNewCandle(lastPrice!);
      }
    });
  }

  Future<void> _loadInitialData() async {
    int limit = 40;
    if (widget.timeframe == '1min') limit = 60;
    if (widget.timeframe == '30min') limit = 30;
    if (widget.timeframe == '4h') limit = 24;

    final history = await _db.getRateHistory('XAU/USD', limit);
    
    List<GoldCandle> newCandles = [];
    if (history.isNotEmpty) {
      final sorted = history.reversed.toList();
      double prevClose = (sorted.first['purchase_price'] as num).toDouble();
      
      for (int i = 0; i < sorted.length; i++) {
        final priceOunce = (sorted[i]['purchase_price'] as num).toDouble();
        // Simulate OHLC for history
        double high = max(prevClose, priceOunce) + (Random().nextDouble() * 0.5);
        double low = min(prevClose, priceOunce) - (Random().nextDouble() * 0.5);
        
        newCandles.add(GoldCandle(
          open: prevClose,
          high: high,
          low: low,
          close: priceOunce,
          x: i.toDouble(),
        ));
        prevClose = priceOunce;
      }
    }

    if (newCandles.length < 15) {
      double current = newCandles.isNotEmpty ? newCandles.first.open : 2330.0;
      final seeded = <GoldCandle>[];
      final r = Random();
      
      for (int i = 0; i < (limit - newCandles.length); i++) {
        double next = current + (r.nextDouble() - 0.5) * 2.0;
        double high = max(current, next) + r.nextDouble();
        double low = min(current, next) - r.nextDouble();
        
        seeded.insert(0, GoldCandle(
          open: current,
          high: high,
          low: low,
          close: next,
          x: -(i + 1).toDouble(),
        ));
        current = next;
      }
      newCandles.insertAll(0, seeded);
    }

    double firstX = newCandles.first.x;
    newCandles = newCandles.map((e) => GoldCandle(
      open: e.open, high: e.high, low: e.low, close: e.close, x: e.x - firstX
    )).toList();

    if (mounted) {
      setState(() {
        candles = newCandles;
        lastX = candles.last.x;
        if (newCandles.isNotEmpty) lastPrice = newCandles.last.close;
      });
    }
  }

  void _addNewCandle(double price) {
    if (candles.isEmpty) return;
    if (!mounted) return;
    setState(() {
      lastX += 1;
      double open = candles.last.close;
      candles.add(GoldCandle(
        open: open,
        high: max(open, price),
        low: min(open, price),
        close: price,
        x: lastX,
      ));
      if (candles.length > 80) candles.removeAt(0);
    });
  }

  void _updateLastCandle(double price) {
    if (candles.isEmpty) return;
    setState(() {
      candles[candles.length - 1] = candles.last.copyWith(close: price);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: DataProvider().ratesStream,
      builder: (context, snapshot) {
        final rates = (snapshot.data?['rates'] as List?) ?? [];

        try {
          final gold = rates.firstWhere((e) => e['symbol'] == 'XAU/USD');
          final priceOunce = (gold['purchase_price'] as num).toDouble();
          if (lastPrice != priceOunce) {
            lastPrice = priceOunce;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _updateLastCandle(priceOunce);
            });
          }
        } catch (_) {}

        if (candles.length < 2) {
          return const Center(child: CircularProgressIndicator(color: DahabiTheme.gold));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: CandleStickPainter(
                candles: candles,
                themeColor: DahabiTheme.gold,
              ),
            );
          },
        );
      },
    );
  }
}

class CandleStickPainter extends CustomPainter {
  final List<GoldCandle> candles;
  final Color themeColor;

  CandleStickPainter({required this.candles, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final double minY = candles.map((e) => e.low).reduce(min) * 0.9998;
    final double maxY = candles.map((e) => e.high).reduce(max) * 1.0002;
    final double rangeY = maxY - minY;

    final double candleWidth = (size.width / (candles.length)) * 0.8;
    final double spacing = size.width / (candles.length);

    final Paint upPaint = Paint()
      ..color = const Color(0xFF22C97A)
      ..style = PaintingStyle.fill;
    final Paint downPaint = Paint()
      ..color = const Color(0xFFE24B4A)
      ..style = PaintingStyle.fill;
    final Paint wickPaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final double x = i * spacing + (spacing / 2);
      
      final double top = size.height - ((candle.open - minY) / rangeY * size.height);
      final double bottom = size.height - ((candle.close - minY) / rangeY * size.height);
      final double high = size.height - ((candle.high - minY) / rangeY * size.height);
      final double low = size.height - ((candle.low - minY) / rangeY * size.height);

      final isUp = candle.close >= candle.open;
      final currentPaint = isUp ? upPaint : downPaint;
      wickPaint.color = currentPaint.color;

      // Draw wick
      canvas.drawLine(Offset(x, high), Offset(x, low), wickPaint);

      // Draw body
      final double bodyTop = min(top, bottom);
      final double bodyBottom = max(top, bottom);
      
      // Ensure body has at least 1px height
      final rectHeight = max(1.0, (bodyBottom - bodyTop).abs());
      canvas.drawRect(
        Rect.fromLTWH(x - (candleWidth / 2), bodyTop, candleWidth, rectHeight),
        currentPaint,
      );
    }

    // Draw price line (TradingView style)
    if (candles.isNotEmpty) {
      final lastCandle = candles.last;
      final double lastY = size.height - ((lastCandle.close - minY) / rangeY * size.height);
      final Paint linePaint = Paint()
        ..color = themeColor.withOpacity(0.3)
        ..strokeWidth = 0.5;
      
      // Dashed line would be better but solid for now
      canvas.drawLine(Offset(0, lastY), Offset(size.width, lastY), linePaint);
      
      // Price tag
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: lastCandle.close.toStringAsFixed(2),
          style: DahabiTheme.dataMono.copyWith(color: themeColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 4, lastY - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant CandleStickPainter oldDelegate) => true;
}