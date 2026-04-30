import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/dahabi_theme.dart';

class TickerBar extends StatefulWidget {
  final List<TickerItem> items;

  const TickerBar({super.key, required this.items});

  @override
  State<TickerBar> createState() => _TickerBarState();
}

class _TickerBarState extends State<TickerBar> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final double _velocity = 30.0; // pixels per second

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_scrollController.hasClients) {
        final double dt = (elapsed.inMilliseconds - _lastElapsed.inMilliseconds) / 1000.0;
        _scrollController.jumpTo(_scrollController.offset + (_velocity * dt));
      }
      _lastElapsed = elapsed;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ticker.start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: DahabiTheme.border, width: 1),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = widget.items[index % widget.items.length];
          final isPositive = item.change >= 0;
          final color = isPositive ? DahabiTheme.green : DahabiTheme.red;
          final sign = isPositive ? '+' : '';

          return Padding(
            padding: const EdgeInsets.only(right: 50.0), // blankSpace: 50.0
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item.symbol,
                  style: DahabiTheme.dataMono.copyWith(fontSize: 11, color: DahabiTheme.text),
                ),
                const SizedBox(width: 8),
                Text(
                  item.price.toStringAsFixed(2),
                  style: DahabiTheme.dataMono.copyWith(fontSize: 11, color: DahabiTheme.text),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sign${item.change.toStringAsFixed(2)}%',
                  style: DahabiTheme.dataMono.copyWith(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TickerItem {
  final String symbol;
  final double price;
  final double change;

  const TickerItem({required this.symbol, required this.price, required this.change});
}


