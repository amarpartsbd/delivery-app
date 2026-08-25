import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'delivery_detail_screen.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});
  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  String _filter = 'active'; // active | done
  Future<List<Map<String, dynamic>>>? _future;
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadSummary();
  }

  void _load() {
    _future = context.read<AppState>().api.get('/delivery/assignments', query: {'filter': _filter})
        .then((r) => (r['data'] as List).cast<Map<String, dynamic>>());
  }

  Future<void> _loadSummary() async {
    try {
      final d = await context.read<AppState>().api.get('/delivery/account');
      if (mounted) setState(() => _summary = Map<String, dynamic>.from(d));
    } catch (_) {}
  }

  static const _statusLabel = {
    'assigned': 'নতুন', 'out_for_delivery': 'পথে', 'delivered': 'ডেলিভারড', 'failed': 'ব্যর্থ',
  };
  static const _statusColor = {
    'assigned': Color(0xFFEA580C), 'out_for_delivery': Color(0xFF2563EB),
    'delivered': Color(0xFF0EA96E), 'failed': Color(0xFFE11D48),
  };

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cur = state.currency;
    final brand = state.brandColor;
    final name = (state.user?['name']?.toString() ?? '').split(' ').first;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async { setState(_load); await _loadSummary(); },
        child: CustomScrollView(slivers: [
          // Greeting + today summary header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: brandGradient(brand)),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('স্বাগতম, ${name.isEmpty ? 'ডেলিভারিম্যান' : name} 👋', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    const Text('আজকের ডেলিভারি সামলান', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ])),
                  Container(height: 44, width: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.local_shipping_rounded, color: Colors.white)),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  _hstat('সক্রিয়', '${_summary['active'] ?? 0}', Icons.pending_actions_rounded),
                  _hstat('ডেলিভারড', '${_summary['delivered'] ?? 0}', Icons.check_circle_rounded),
                  _hstat('আজ কালেকশন', money(cur, (_summary['today_collected'] ?? 0) as num), Icons.payments_rounded),
                ]),
              ]),
            ),
          ),
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
              child: Row(children: [
                _chip('সক্রিয়', 'active'),
                const SizedBox(width: 8),
                _chip('সম্পন্ন', 'done'),
              ]),
            ),
          ),
          // List
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator())));
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(children: [
                    Icon(_filter == 'active' ? Icons.inbox_rounded : Icons.check_circle_outline_rounded, size: 56, color: kFaint),
                    const SizedBox(height: 12),
                    Text(_filter == 'active' ? 'এখন কোনো ডেলিভারি অ্যাসাইন করা নেই।' : 'এখনো কোনো সম্পন্ন ডেলিভারি নেই।', style: const TextStyle(color: kMuted)),
                  ]),
                ));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _tile(list[i], cur),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _hstat(String label, String value, IconData icon) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
          ]),
        ),
      );

  Widget _chip(String label, String v) => ChoiceChip(label: Text(label), selected: _filter == v, onSelected: (_) { setState(() => _filter = v); _load(); });

  Widget _tile(Map<String, dynamic> a, String cur) {
    final st = (a['status'] ?? '').toString();
    final sc = _statusColor[st] ?? kMuted;
    final collect = ((a['total'] ?? 0) as num);
    final phone = (a['phone'] ?? '').toString();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DeliveryDetailScreen(assignmentId: a['id'] as int),
        )).then((_) { setState(_load); _loadSummary(); }),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: softCard(radius: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(height: 38, width: 38, decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.receipt_long_rounded, size: 19, color: sc)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kInk)),
                Text(a['customer'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: sc.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)), child: Text(_statusLabel[st] ?? st, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc))),
            ]),
            if ((a['address'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.location_on_outlined, size: 15, color: kFaint), const SizedBox(width: 6), Expanded(child: Text(a['address'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: kMuted)))]),
            ],
            const Divider(height: 18),
            Row(children: [
              Text('অর্ডার ${money(cur, collect)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
              const Spacer(),
              if (st == 'delivered')
                Text(a['no_payment'] == true ? 'পেমেন্ট নেই' : 'কালেক্ট ${money(cur, (a['collected_amount'] ?? 0) as num)}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: a['no_payment'] == true ? kMuted : kSuccess))
              else ...[
                if (phone.isNotEmpty)
                  InkWell(onTap: () => _call(phone), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0EA96E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.phone_rounded, size: 14, color: Color(0xFF0EA96E)), SizedBox(width: 4), Text('কল', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0EA96E)))]))),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Text('ডেলিভারি করুন', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sc)), Icon(Icons.chevron_right_rounded, size: 16, color: sc)])),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
