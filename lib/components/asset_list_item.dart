import 'package:flutter/material.dart';
import '../theme/dahabi_theme.dart';

class AssetListItem extends StatefulWidget {
  final String assetName;
  final String weight;
  final double buyPrice;
  final double sellPrice;
  final double change;
  final bool isEven;
  final VoidCallback? onTap;

  const AssetListItem({
    super.key,
    required this.assetName,
    required this.weight,
    required this.buyPrice,
    required this.sellPrice,
    required this.change,
    required this.isEven,
    this.onTap,
  });

  @override
  State<AssetListItem> createState() => _AssetListItemState();
}

class _AssetListItemState extends State<AssetListItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final changeColor = widget.change >= 0 ? DahabiTheme.green : DahabiTheme.red;
    final changeSign = widget.change >= 0 ? '+' : '';
    final baseColor = widget.isEven ? Colors.white.withOpacity(0.01) : Colors.transparent;
    final color = _isFocused ? DahabiTheme.gold.withOpacity(0.1) : baseColor;

    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            border: Border(
              bottom: BorderSide(
                color: _isFocused ? DahabiTheme.gold : DahabiTheme.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 1. Asset Name (Karat + Weight)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assetName,
                      style: DahabiTheme.dataMono.copyWith(
                        fontSize: 24, // Increased from 15
                        fontWeight: FontWeight.bold,
                        color: DahabiTheme.text,
                      ),
                    ),
                    Text(
                      widget.weight,
                      style: DahabiTheme.labelCaps.copyWith(
                        fontSize: 14, // Increased from 10
                        color: DahabiTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              // 2. Buy Price
              Expanded(
                child: Text(
                  _formatPrice(widget.buyPrice),
                  style: DahabiTheme.dataMono.copyWith(
                    fontSize: 24, // Increased from 14
                    fontWeight: FontWeight.bold,
                    color: DahabiTheme.gold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // 3. Sell Price
              Expanded(
                child: Text(
                  _formatPrice(widget.sellPrice),
                  style: DahabiTheme.dataMono.copyWith(
                    fontSize: 24, // Increased from 14
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA89060),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // 4. Change Badge
              SizedBox(
                width: 100, // Increased width
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$changeSign${widget.change.toStringAsFixed(2)}%',
                      style: DahabiTheme.dataMono.copyWith(
                        color: changeColor,
                        fontSize: 14, // Increased from 10
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
