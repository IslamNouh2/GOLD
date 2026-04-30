import 'package:flutter/material.dart';
import '../components/ticker_bar.dart';
import '../components/asset_list_item.dart';
import '../theme/dahabi_theme.dart';
import '../services/data_provider.dart';
import '../services/gold_engine.dart';
import '../services/logger_service.dart';
import '../l10n/app_localizations.dart';
import '../components/gold_trading_terminal.dart';
import 'gold_trading_screen.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: DahabiTheme.background,
      body: SafeArea(
        child: Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: StreamBuilder<Map<String, dynamic>>(
            stream: DataProvider().ratesStream,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final rates = (data?['rates'] as List?) ?? [];

              if (rates.isEmpty) {
                return _buildLanding(context);
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isLargeScreen = constraints.maxWidth > 900;
                  
                  final totalH = constraints.maxHeight;
                  final navH = isLargeScreen ? totalH * 0.06 : totalH * 0.04;
                  final tickerH = isLargeScreen ? totalH * 0.05 : totalH * 0.03;

                  // Data logic
                  double usdDzd = 0;
                  double xauUsd = 0;
                  double spotOunceUSD = 0;

                  try {
                    usdDzd = rates.firstWhere((e) => e['symbol'] == 'USD/DZD')['sale_price'];
                    final goldRate = rates.firstWhere((e) => e['symbol'] == 'XAU/USD');
                    xauUsd = goldRate['sale_price'];
                    spotOunceUSD = goldRate['purchase_price'];
                  } catch (_) {}

                  final gram24kUSD = xauUsd / 31.1035;
                  final gram18kDZD = gram24kUSD * usdDzd * 0.75;
                  double goldChange = 0.0;
                  try {
                    goldChange = rates.firstWhere((e) => e['symbol'] == 'XAU/USD')['change'] ?? 0.0;
                  } catch (_) {}

                  final enginePrices = GoldPricingEngine.calculateAllPrices(
                    priceGram24kUSD: gram24kUSD,
                    usdDzdRate: usdDzd,
                  );

                  return Column(
                    children: [
                      // 1. TOP SECTION: Navbar
                      SizedBox(
                        height: navH,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 32 : 16),
                          decoration: const BoxDecoration(
                            color: DahabiTheme.surface,
                            border: Border(bottom: BorderSide(color: DahabiTheme.border)),
                          ),
                          child: Row(
                            children: [
                              Text(context.l10n('app_title'), 
                                style: DahabiTheme.arabicTitle.copyWith(fontSize: isLargeScreen ? 24 : 16)),
                              const Spacer(),
                              IconButton(
                                onPressed: () => DataProvider().sync(),
                                onLongPress: () async {
                                  final logs = await LoggerService().getLogs();
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('App Logs'),
                                        content: SingleChildScrollView(
                                          child: SelectableText(logs, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(Icons.sync, color: DahabiTheme.gold, size: isLargeScreen ? 32 : 20),
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const GoldTradingScreen()),
                                ),
                                icon: Icon(Icons.candlestick_chart, color: DahabiTheme.gold, size: isLargeScreen ? 32 : 20),
                              ),
                              const SizedBox(width: 8),
                              _buildLanguageSwitcher(isLargeScreen),
                              const SizedBox(width: 12),
                              _buildLastUpdate(data?['timestamp'], isLargeScreen),
                            ],
                          ),
                        ),
                      ),

                      // 2. TOP SECTION: Tickerbar
                      SizedBox(
                        height: tickerH,
                        child: _buildTicker(rates, isLargeScreen),
                      ),

                      // 3. MAIN CONTENT: Priorities flipped for Table visibility
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(isLargeScreen ? 24 : 0),
                          child: Column(
                            children: [
                              // Chart (Small Flex 3 to save space)
                              Expanded(
                                flex: isLargeScreen ? 3 : 2,
                                child: _buildChartSection(context, spotOunceUSD, gram18kDZD, goldChange, isLargeScreen),
                              ),
                              if (isLargeScreen) const SizedBox(height: 16),
                              // Table (Flex 2 on wide screens to prevent squashing chart)
                              Expanded(
                                flex: isLargeScreen ? 2 : 4,
                                child: _buildTableSection(context, enginePrices, goldChange, isLargeScreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, double spot, double gramDZD, double change, bool isLarge) {
    return Container(
      margin: isLarge ? EdgeInsets.zero : const EdgeInsets.fromLTRB(10, 4, 10, 4),
      padding: EdgeInsets.all(isLarge ? 18 : 2),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartHeader(context, spot, gramDZD, change, isLarge),
          const SizedBox(height: 14),
          const Expanded(
            child: GoldTradingTerminal(showInfo: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection(BuildContext context, Map<String, dynamic> prices, double change, bool isLarge) {
    return Container(
      margin: isLarge ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(context, isLarge),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: prices.length,
              itemBuilder: (context, index) {
                final keys = prices.keys.toList();
                final key = keys[index];
                final itemData = prices[key];
                return AssetListItem(
                  assetName: key,
                  weight: context.l10n('one_gram'),
                  buyPrice: itemData['achat'],
                  sellPrice: itemData['vente'],
                  change: change,
                  isEven: index % 2 == 0,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdate(DateTime? timestamp, bool isLarge) {
    final time = timestamp ?? DateTime.now();
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
    return Text(
      '${context.l10n('last_updated')}: $timeStr',
      style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 14 : 9, color: DahabiTheme.muted),
    );
  }

  Widget _buildLanguageSwitcher(bool isLarge) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: localeProvider.locale.languageCode,
        icon: Icon(Icons.language, color: DahabiTheme.gold, size: isLarge ? 24 : 16),
        dropdownColor: DahabiTheme.surface,
        style: DahabiTheme.dataMono.copyWith(color: DahabiTheme.gold, fontSize: isLarge ? 14 : 10),
        onChanged: (String? newValue) {
          if (newValue != null) {
            localeProvider.setLocale(Locale(newValue, ''));
          }
        },
        items: const [
          DropdownMenuItem(value: 'ar', child: Text('AR')),
          DropdownMenuItem(value: 'en', child: Text('EN')),
          DropdownMenuItem(value: 'fr', child: Text('FR')),
        ],
      ),
    );
  }

  Widget _buildTicker(List rates, bool isLarge) {
    // Duplicate rates to make it more dense like the photo
    final rawItems = rates.map((e) {
      return TickerItem(
        symbol: e['symbol'],
        price: e['sale_price'],
        change: e['change'] ?? 0.0,
      );
    }).toList();

    rawItems.sort((a, b) {
      if (a.symbol == 'XAU/USD') return -1;
      if (b.symbol == 'XAU/USD') return 1;
      return a.symbol.compareTo(b.symbol);
    });

    final List<TickerItem> tickerItems = [...rawItems, ...rawItems, ...rawItems, ...rawItems, ...rawItems];

    return TickerBar(items: tickerItems);
  }

  Widget _buildChartHeader(BuildContext context, double spot, double gramDZD, double change, bool isLarge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // RIGHT SECTION (in RTL): USD Spot Ounce Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(context.l10n('gold_spot_label'), 
              style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 24 : 12, color: DahabiTheme.muted, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text('\$${_formatPrice(spot, dec: 2)}', 
              style: DahabiTheme.dataMono.copyWith(
                fontSize: isLarge ? 38 : 18, 
                fontWeight: FontWeight.w600, 
                color: DahabiTheme.gold,
              )),
            Text(context.l10n('per_ounce'), 
              style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 12 : 9, color: DahabiTheme.muted)),
          ],
        ),
        // LEFT SECTION (in RTL): DZD Gram Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n('gram_18k_label'), 
              style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 24 : 9, color: DahabiTheme.muted, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text(_formatPrice(gramDZD), 
              style: DahabiTheme.themeData.textTheme.displayLarge?.copyWith(
                fontSize: isLarge ? 38 : 18, 
                height: 1.0, 
                fontWeight: FontWeight.w600, 
                letterSpacing: -0.5,
              )),
            Text(context.l10n('dzd_currency'), 
              style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 12 : 10, color: DahabiTheme.muted)),
            const SizedBox(height: 8),
            _buildChangeBadge(change, isLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildChangeBadge(double change, bool isLarge) {
    final color = change >= 0 ? DahabiTheme.green : DahabiTheme.red;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 14 : 10, vertical: isLarge ? 6 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            change >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: color,
            size: isLarge ? 18 : 12,
          ),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', 
            style: DahabiTheme.dataMono.copyWith(
              color: color, 
              fontSize: isLarge ? 12 : 8,
              fontWeight: FontWeight.w900,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, bool isLarge) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLarge ? 20 : 14),
      color: DahabiTheme.surfaceVariant,
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(context.l10n('col_type'), 
            style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 16 : 12, fontWeight: FontWeight.bold))),
          Expanded(child: Center(child: Text(context.l10n('col_buy'), 
            style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 16 : 12, fontWeight: FontWeight.bold)))),
          Expanded(child: Center(child: Text(context.l10n('col_sell'), 
            style: DahabiTheme.labelCaps.copyWith(fontSize: isLarge ? 16 : 12, fontWeight: FontWeight.bold)))),
          if (isLarge) const SizedBox(width: 120),
        ],
      ),
    );
  }

  Widget _buildLanding(BuildContext context) {
    return Container(
      width: double.infinity,
      color: DahabiTheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: DahabiTheme.gold, size: 64),
          const SizedBox(height: 24),
          Text(context.l10n('app_title'), style: DahabiTheme.arabicTitle.copyWith(fontSize: 32)),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: DahabiTheme.gold),
          const SizedBox(height: 24),
          Text('جاري جلب البيانات...', style: DahabiTheme.labelCaps.copyWith(color: DahabiTheme.gold)),
        ],
      ),
    );
  }

  String _formatPrice(double price, {int dec = 0}) {
    return price.toStringAsFixed(dec).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}