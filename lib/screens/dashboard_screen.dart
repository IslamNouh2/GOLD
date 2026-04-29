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
                  final totalH = constraints.maxHeight;
                  final navH = totalH * 0.05;
                  final tickerH = totalH * 0.05;
                  final chartH = totalH * 0.50;
                  final tableH = totalH * 0.40;

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
                  final gram24kDZD = gram24kUSD * usdDzd;
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
                      // 1. TOP SECTION: Navbar (10%)
                      SizedBox(
                        height: navH,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: DahabiTheme.surface,
                            border: Border(bottom: BorderSide(color: DahabiTheme.border)),
                          ),
                          child: Row(
                            children: [
                              Text(context.l10n('app_title'), style: DahabiTheme.arabicTitle),
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
                                icon: const Icon(Icons.sync, color: DahabiTheme.gold, size: 20),
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const GoldTradingScreen()),
                                ),
                                icon: const Icon(Icons.candlestick_chart, color: DahabiTheme.gold, size: 20),
                              ),
                              const SizedBox(width: 8),
                              _buildLastUpdate(data?['timestamp']),
                            ],
                          ),
                        ),
                      ),

                      // 2. TOP SECTION: Tickerbar (10%)
                      SizedBox(
                        height: tickerH,
                        child: _buildTicker(rates),
                      ),

                      // 3. TOP SECTION: Chart Area (40%)
                      SizedBox(
                        height: chartH,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Column(
                            children: [
                              _buildChartHeader(context, spotOunceUSD, gram24kDZD, goldChange),
                              const Expanded(
                                child: GoldTradingTerminal(showInfo: false),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. BOTTOM SECTION: Table Area (40%)
                      SizedBox(
                        height: tableH,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(
                            color: DahabiTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _buildTableHeader(context),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: enginePrices.length,
                                  itemBuilder: (context, index) {
                                    final keys = enginePrices.keys.toList();
                                    final key = keys[index];
                                    final itemData = enginePrices[key];
                                    return AssetListItem(
                                      assetName: key,
                                      weight: context.l10n('one_gram'),
                                      buyPrice: itemData['achat'],
                                      sellPrice: itemData['vente'],
                                      change: goldChange,
                                      isEven: index % 2 == 0,
                                    );
                                  },
                                ),
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

  Widget _buildLastUpdate(DateTime? timestamp) {
    final time = timestamp ?? DateTime.now();
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
    return Text(
      '${context.l10n('last_updated')}: $timeStr',
      style: DahabiTheme.labelCaps.copyWith(fontSize: 10),
    );
  }

  Widget _buildTicker(List rates) {
    final tickerItems = rates.map((e) {
      return TickerItem(
        symbol: e['symbol'],
        price: e['sale_price'],
        change: e['change'] ?? 0.0,
      );
    }).toList();

    tickerItems.sort((a, b) {
      if (a.symbol == 'XAU/USD') return -1;
      if (b.symbol == 'XAU/USD') return 1;
      return a.symbol.compareTo(b.symbol);
    });

    return TickerBar(items: tickerItems);
  }

  Widget _buildChartHeader(BuildContext context, double spot, double gramDZD, double change) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIRST CHILD (RIGHT in RTL): USD Spot Ounce
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n('gold_spot_label'), style: DahabiTheme.labelCaps.copyWith(fontSize: 10, color: DahabiTheme.muted)),
            const SizedBox(height: 4),
            Text('\$${_formatPrice(spot, dec: 2)}', 
              style: DahabiTheme.dataMono.copyWith(fontSize: 26, fontWeight: FontWeight.bold, color: DahabiTheme.gold)),
            Text(context.l10n('per_ounce'), style: DahabiTheme.labelCaps.copyWith(fontSize: 10, color: DahabiTheme.muted)),
          ],
        ),
        // SECOND CHILD (LEFT in RTL): DZD Gram Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(context.l10n('gram_24k_label'), style: DahabiTheme.labelCaps.copyWith(fontSize: 10, color: DahabiTheme.muted)),
            const SizedBox(height: 4),
            Text(_formatPrice(gramDZD), 
              style: DahabiTheme.themeData.textTheme.displayLarge?.copyWith(fontSize: 42, height: 1.1)),
            Text(context.l10n('dzd_currency'), style: DahabiTheme.labelCaps.copyWith(fontSize: 12, color: DahabiTheme.muted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (change >= 0 ? DahabiTheme.green : DahabiTheme.red).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    change >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: change >= 0 ? DahabiTheme.green : DahabiTheme.red,
                    size: 16,
                  ),
                  Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', 
                    style: DahabiTheme.dataMono.copyWith(
                      color: change >= 0 ? DahabiTheme.green : DahabiTheme.red, 
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: DahabiTheme.surfaceVariant,
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(context.l10n('col_type'), style: DahabiTheme.labelCaps.copyWith(fontSize: 16, fontWeight: FontWeight.bold))),
          Expanded(child: Center(child: Text(context.l10n('col_buy'), style: DahabiTheme.labelCaps.copyWith(fontSize: 16, fontWeight: FontWeight.bold)))),
          Expanded(child: Center(child: Text(context.l10n('col_sell'), style: DahabiTheme.labelCaps.copyWith(fontSize: 16, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 100),
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