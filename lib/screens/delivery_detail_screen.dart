import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../theme.dart';

class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({super.key, required this.assignmentId});
  final int assignmentId;
  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  Map<String, dynamic>? _d;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await context.read<AppState>().api.get('/delivery/assignments/${widget.assignmentId}');
      _d = Map<String, dynamic>.from(r['data']);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    try {
      await context.read<AppState>().api.post('/delivery/assignments/${widget.assignmentId}/start');
      _load();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _deliver() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeliverSheet(
        assignmentId: widget.assignmentId,
        collect: ((_d?['collect_amount'] ?? 0) as num).toDouble(),
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _launch(String scheme, String value) async {
    final uri = Uri.parse('$scheme$value');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<AppState>().currency;
    final d = _d;
    final delivered = d?['status'] == 'delivered';
    return Scaffold(
      appBar: AppBar(title: Text(d?['order_number'] ?? 'ডেলিভারি')),
      body: _loading || d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              // Customer + contact
              Container(
                padding: const EdgeInsets.all(16),
                decoration: softCard(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['customer'] ?? 'কাস্টমার', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
                  if ((d['address'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.location_on_outlined, size: 18, color: kFaint), const SizedBox(width: 8), Expanded(child: Text(d['address'], style: const TextStyle(color: kMuted, height: 1.4)))]),
                  ],
                  const SizedBox(height: 14),
                  Row(children: [
                    if (d['phone'] != null) Expanded(child: OutlinedButton.icon(onPressed: () => _launch('tel:', d['phone']), icon: const Icon(Icons.phone_rounded, size: 18), label: const Text('কল করুন'))),
                    if (d['phone'] != null && (d['address'] ?? '').toString().isNotEmpty) const SizedBox(width: 10),
                    if ((d['address'] ?? '').toString().isNotEmpty) Expanded(child: OutlinedButton.icon(onPressed: () => _launch('https://www.google.com/maps/search/?api=1&query=', Uri.encodeComponent(d['address'])), icon: const Icon(Icons.map_outlined, size: 18), label: const Text('ম্যাপ'))),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              // Collection highlight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF0EA96E).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF0EA96E).withValues(alpha: 0.25))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('কালেক্ট করতে হবে', style: TextStyle(fontWeight: FontWeight.w600, color: kInk)),
                  Text(money(cur, (d['collect_amount'] ?? 0) as num), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0EA96E))),
                ]),
              ),
              const SizedBox(height: 14),
              const Text('পণ্যসমূহ', style: TextStyle(fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 8),
              Container(
                decoration: softCard(radius: 16),
                child: Column(children: [
                  for (final it in (d['items'] as List).cast<Map<String, dynamic>>())
                    ListTile(
                      dense: true,
                      title: Text(it['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text('${_qty(it['quantity'])} × ${money(cur, (it['unit_price'] ?? 0) as num)}${(it['variant'] ?? '').toString().isNotEmpty ? '  ·  ${it['variant']}' : ''}', style: const TextStyle(fontSize: 12)),
                      trailing: Text(money(cur, (it['line_total'] ?? 0) as num), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              if (delivered)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: softCard(),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF0EA96E)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d['no_payment'] == true ? 'ডেলিভারড — কোনো পেমেন্ট নেওয়া হয়নি।' : 'ডেলিভারড — কালেক্ট ${money(cur, (d['collected_amount'] ?? 0) as num)}।', style: const TextStyle(fontWeight: FontWeight.w600, color: kInk))),
                  ]),
                )
              else ...[
                if (d['status'] == 'assigned')
                  OutlinedButton.icon(onPressed: _start, icon: const Icon(Icons.directions_run_rounded), label: const Text('শুরু করুন — পথে আছি')),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0EA96E)),
                  onPressed: _deliver,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('ডেলিভারড হিসেবে মার্ক করুন'),
                ),
              ],
            ]),
    );
  }

  String _qty(dynamic q) {
    final n = (q as num).toDouble();
    return n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
  }
}

class _DeliverSheet extends StatefulWidget {
  const _DeliverSheet({required this.assignmentId, required this.collect});
  final int assignmentId;
  final double collect;
  @override
  State<_DeliverSheet> createState() => _DeliverSheetState();
}

class _DeliverSheetState extends State<_DeliverSheet> {
  late final TextEditingController _amount = TextEditingController(text: widget.collect.toStringAsFixed(0));
  String? _photoPath;
  bool _noPayment = false;
  bool _saving = false;
  String? _error;

  Future<void> _takePhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60, maxWidth: 1280);
    if (img != null) setState(() => _photoPath = img.path);
  }

  Future<void> _submit() async {
    if (_photoPath == null) { setState(() => _error = 'আগে একটি প্রমাণ ছবি তুলুন।'); return; }
    if (!_noPayment && (double.tryParse(_amount.text.trim()) ?? -1) < 0) { setState(() => _error = 'সঠিক টাকার পরিমাণ দিন অথবা "পেমেন্ট নেই" বেছে নিন।'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      final res = await context.read<AppState>().api.postForm('/delivery/assignments/${widget.assignmentId}/deliver',
        fields: {
          'no_payment': _noPayment ? '1' : '0',
          if (!_noPayment) 'collected_amount': _amount.text.trim(),
        },
        filePath: _photoPath,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Delivered.')));
      }
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<AppState>().currency;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('ডেলিভারি সম্পন্ন করুন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          // Proof photo
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              height: 150,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
              alignment: Alignment.center,
              child: _photoPath == null
                  ? const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_a_photo_rounded, size: 34, color: kFaint), SizedBox(height: 8), Text('প্রমাণ ছবি তুলুন', style: TextStyle(color: kMuted))])
                  : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_photoPath!), height: 150, width: double.infinity, fit: BoxFit.cover)),
            ),
          ),
          if (_photoPath != null)
            Align(alignment: Alignment.center, child: TextButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.refresh, size: 16), label: const Text('আবার তুলুন'))),
          const SizedBox(height: 12),
          // Payment
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('কোনো পেমেন্ট নেওয়া হয়নি'),
            value: _noPayment,
            onChanged: (v) => setState(() => _noPayment = v),
          ),
          if (!_noPayment)
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(labelText: 'কালেক্ট করা টাকা', prefixText: '$cur '),
            ),
          if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: kDanger))],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0EA96E)),
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('ডেলিভারি সাবমিট করুন'),
          ),
        ]),
      ),
    );
  }
}
