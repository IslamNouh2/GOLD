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

    final isLarge = MediaQuery.of(context).size.width > 900;

    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: isLarge ? 32 : 16, vertical: isLarge ? 20 : 14),
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
                child: Row(
                  children: [
                    Text(
                      widget.assetName,
                      style: DahabiTheme.dataMono.copyWith(
                        fontSize: isLarge ? 32 : 18, 
                        fontWeight: FontWeight.bold,
                        color: DahabiTheme.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.weight,
                      style: DahabiTheme.labelCaps.copyWith(
                        fontSize: isLarge ? 18 : 10,
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
                    fontSize: isLarge ? 32 : 18,
                    fontWeight: FontWeight.bold,
                    color: DahabiTheme.gold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              // 3. Sell Price
              Expanded(
                child: Text(
                  _formatPrice(widget.sellPrice),
                  style: DahabiTheme.dataMono.copyWith(
                    fontSize: isLarge ? 32 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA89060),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              // 4. Change Badge (Only on Large Screens)
              if (isLarge)
                SizedBox(
                  width: 140,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$changeSign${widget.change.toStringAsFixed(2)}%',
                        style: DahabiTheme.dataMono.copyWith(
                          color: changeColor,
                          fontSize: 20,
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
