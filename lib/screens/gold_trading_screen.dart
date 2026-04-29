import 'package:flutter/material.dart';
import '../components/gold_trading_terminal.dart';

class GoldTradingScreen extends StatelessWidget {
  const GoldTradingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'LIVE TRADING TERMINAL',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Gold-API.com', style: TextStyle(color: Color(0xFFD4AF37))),
                  content: const Text(
                    'This terminal uses real-time data from Gold-API.com and historical tracking via the local database. '
                    'Prices are updated automatically every 60 seconds.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK', style: TextStyle(color: Color(0xFFD4AF37))),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stats / Market Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1A1A1A),
              child: Row(
                children: [
                  _buildStatItem('Market', 'XAU/USD'),
                  _buildDivider(),
                  _buildStatItem('Status', 'OPEN', color: Colors.green),
                  _buildDivider(),
                  _buildStatItem('Vol', '12.4K'),
                ],
              ),
            ),
            
            // The Trading Terminal Widget
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: GoldTradingTerminal(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
