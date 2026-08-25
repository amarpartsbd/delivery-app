import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class DeliveryProfileScreen extends StatelessWidget {
  const DeliveryProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user ?? {};
    final company = state.company ?? {};
    final brand = state.brandColor;
    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: CircleAvatar(radius: 40, backgroundColor: brand, child: Text((user['name']?.toString() ?? '?').substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.w800)))),
        const SizedBox(height: 12),
        Center(child: Text(user['name']?.toString() ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk))),
        Center(child: Text(user['phone']?.toString() ?? '', style: const TextStyle(color: kMuted))),
        const SizedBox(height: 8),
        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text('ডেলিভারিম্যান', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: brand)))),
        const SizedBox(height: 24),
        Container(
          decoration: softCard(radius: 16),
          child: Column(children: [
            _row('কোম্পানি', company['name']?.toString() ?? '—', Icons.business_rounded),
            const Divider(height: 1),
            _row('মোবাইল', user['phone']?.toString() ?? '—', Icons.phone_rounded),
          ]),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kDanger),
          onPressed: () => context.read<AppState>().logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('লগ আউট'),
        ),
      ]),
    );
  }

  Widget _row(String label, String value, IconData icon) => ListTile(
        leading: Icon(icon, color: kFaint),
        title: Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, color: kInk, fontWeight: FontWeight.w600)),
      );
}
