import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AppState>().api.get('/delivery/account').then((d) => Map<String, dynamic>.from(d));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cur = state.currency;
    final brand = state.brandColor;
    return Scaffold(
      appBar: AppBar(title: const Text('আমার অ্যাকাউন্ট')),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final d = snap.data ?? {};
            return ListView(padding: const EdgeInsets.all(16), children: [
              // Cash hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: brandGradient(brand), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('মোট কালেক্ট করা ক্যাশ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(money(cur, (d['cash_collected'] ?? 0) as num), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Icon(Icons.today_rounded, color: Colors.white70, size: 15),
                    const SizedBox(width: 5),
                    Text('আজ: ${money(cur, (d['today_collected'] ?? 0) as num)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 15),
                    const SizedBox(width: 5),
                    Text('হাতে: ${money(cur, (d['in_hand'] ?? 0) as num)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _stat('জমা দেওয়া', money(cur, (d['settled'] ?? 0) as num), Icons.price_check_rounded, const Color(0xFF7C3AED))),
                const SizedBox(width: 12),
                Expanded(child: _stat('হাতে আছে', money(cur, (d['in_hand'] ?? 0) as num), Icons.account_balance_wallet_rounded, const Color(0xFFD97706))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _stat('সক্রিয়', '${d['active'] ?? 0}', Icons.local_shipping_rounded, const Color(0xFF2563EB))),
                const SizedBox(width: 12),
                Expanded(child: _stat('ডেলিভারড', '${d['delivered'] ?? 0}', Icons.check_circle_rounded, const Color(0xFF0EA96E))),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: softCard(radius: 16),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: kFaint, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('আপনার কালেক্ট করা ক্যাশ এখানে জমা হয়। "হাতে আছে" = অফিসকে যা এখনো দিতে বাকি — অফিস settlement রেকর্ড করলে কমে যাবে।', style: TextStyle(fontSize: 12.5, color: kMuted))),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(radius: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      );
}
