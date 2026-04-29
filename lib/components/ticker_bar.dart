import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../theme/dahabi_theme.dart';

class TickerBar extends StatelessWidget {
  final List<TickerItem> items;

  const TickerBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: DahabiTheme.border, width: 1),
        ),
      ),
      child: Marquee(
        text: items.map((e) => e.toString()).join('      '),
        style: DahabiTheme.dataMono.copyWith(
          fontSize: 11,
          color: DahabiTheme.text,
        ),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        blankSpace: 50.0,
        velocity: 30.0,
        pauseAfterRound: const Duration(seconds: 0),
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}

class TickerItem {
  final String symbol;
  final double price;
  final double change;

  const TickerItem({required this.symbol, required this.price, required this.change});

  @override
  String toString() {
    final sign = change >= 0 ? '+' : '';
    return '$symbol  ${price.toStringAsFixed(2)}  $sign${change.toStringAsFixed(2)}%';
  }
}

