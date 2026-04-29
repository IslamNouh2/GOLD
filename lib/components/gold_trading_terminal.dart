import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../services/twelve_data_service.dart';
import '../models/candle_model.dart';

class GoldTradingTerminal extends StatefulWidget {
  final bool showInfo;
  const GoldTradingTerminal({super.key, this.showInfo = true});

  @override
  State<GoldTradingTerminal> createState() => _GoldTradingTerminalState();
}

class _GoldTradingTerminalState extends State<GoldTradingTerminal> {
  final TwelveDataService _api = TwelveDataService();
  List<Candle> _candles = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedInterval = '5min';
  bool _isCandleView = true;
  Timer? _refreshTimer;
  
  late TrackballBehavior _trackballBehavior;
  late ZoomPanBehavior _zoomPanBehavior;

  final List<Map<String, String>> _timeframes = [
    {'label': '1m', 'value': '1min'},
    {'label': '5m', 'value': '5min'},
    {'label': '15m', 'value': '15min'},
    {'label': '1h', 'value': '1h'},
    {'label': '1D', 'value': '1day'},
  ];

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: Color(0xFF1E1E1E),
        textStyle: TextStyle(color: Colors.white),
      ),
      lineType: TrackballLineType.vertical,
      lineWidth: 1,
      lineColor: const Color(0xFFD4AF37).withOpacity(0.5),
    );
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.x,
    );
    
    _fetchData();
    
    // Refresh logic: every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchData(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool isRefresh = false}) async {
    if (!isRefresh && mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final candles = await _api.fetchGoldCandles(
        interval: _selectedInterval,
        outputSize: 150,
      );
      
      if (mounted) {
        setState(() {
          _candles = candles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildTimeframeSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _error.isNotEmpty
                ? _buildErrorWidget()
                : _buildChart(),
          ),
          const SizedBox(height: 8),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    double currentPrice = 0;
    double change = 0;
    
    if (_candles.isNotEmpty) {
      currentPrice = _candles.last.close;
      final firstPrice = _candles.first.close;
      change = ((currentPrice - firstPrice) / firstPrice) * 100;
    }

    final isPositive = change >= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GOLD (XAU/USD)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Twelve Data Live Terminal',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${currentPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: _timeframes.map((tf) {
            final isSelected = _selectedInterval == tf['value'];
            return GestureDetector(
              onTap: () {
                if (!isSelected) {
                  setState(() {
                    _selectedInterval = tf['value']!;
                  });
                  _fetchData();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  tf['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Chart Type Toggle
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              _buildChartTypeButton(Icons.candlestick_chart, true),
              _buildChartTypeButton(Icons.show_chart, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeButton(IconData icon, bool isCandle) {
    final isSelected = _isCandleView == isCandle;
    return GestureDetector(
      onTap: () => setState(() => _isCandleView = isCandle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? const Color(0xFFD4AF37) : Colors.white38,
        ),
      ),
    );
  }

  Widget _buildChart() {
    return SfCartesianChart(
      key: ValueKey('gold_chart_${_isCandleView ? 'candle' : 'area'}'),
      backgroundColor: Colors.black,
      plotAreaBorderWidth: 0,
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0.1, color: Colors.white24),
        axisLine: const AxisLine(width: 0),
        dateFormat: _selectedInterval == '1day' ? DateFormat('MM/dd') : DateFormat.Hm(),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        majorGridLines: const MajorGridLines(width: 0.1, color: Colors.white24),
        axisLine: const AxisLine(width: 0),
        numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
      series: <CartesianSeries>[
        if (_isCandleView)
          CandleSeries<Candle, DateTime>(
            dataSource: _candles,
            xValueMapper: (Candle candle, _) => candle.time,
            lowValueMapper: (Candle candle, _) => candle.low,
            highValueMapper: (Candle candle, _) => candle.high,
            openValueMapper: (Candle candle, _) => candle.open,
            closeValueMapper: (Candle candle, _) => candle.close,
            bearColor: Colors.redAccent,
            bullColor: Colors.greenAccent,
            enableSolidCandles: true,
            name: 'XAU/USD',
            animationDuration: 1000,
          )
        else
          AreaSeries<Candle, DateTime>(
            dataSource: _candles,
            xValueMapper: (Candle candle, _) => candle.time,
            yValueMapper: (Candle candle, _) => candle.close,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.3),
                const Color(0xFFD4AF37).withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: const Color(0xFFD4AF37),
            borderWidth: 2,
            name: 'XAU/USD',
            animationDuration: 1000,
          ),
        // SMA Indicator (Bonus)
        LineSeries<Candle, DateTime>(
          dataSource: _candles,
          xValueMapper: (Candle candle, _) => candle.time,
          yValueMapper: (Candle candle, int index) {
            if (index < 14 || _candles.length < 14) return null;
            double sum = 0;
            try {
              for (int i = 0; i < 14; i++) {
                sum += _candles[index - i].close;
              }
              return sum / 14;
            } catch (_) {
              return null;
            }
          },
          color: const Color(0xFFD4AF37).withOpacity(0.5),
          width: 1,
          name: 'SMA(14)',
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    String displayError = _error;
    if (_error.contains('SocketException') || _error.contains('Failed host lookup')) {
      displayError = 'No Internet Connection. Please check your network and try again.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Terminal Offline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              displayError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _fetchData(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
              foregroundColor: const Color(0xFFD4AF37),
              side: const BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final bool isOffline = _error.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Last terminal sync: ${DateFormat.Hms().format(DateTime.now())}',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9),
        ),
        Row(
          children: [
            Icon(Icons.circle, size: 6, color: isOffline ? Colors.grey : Colors.greenAccent),
            const SizedBox(width: 4),
            Text(
              isOffline ? 'OFFLINE' : 'DATA LIVE',
              style: TextStyle(
                color: (isOffline ? Colors.grey : Colors.greenAccent).withOpacity(0.7), 
                fontSize: 9, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
