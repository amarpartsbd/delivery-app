import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'deliveries_screen.dart';
import 'account_screen.dart';
import 'delivery_profile_screen.dart';

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});
  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  int _index = 0;
  LocationService? _loc;

  @override
  void initState() {
    super.initState();
    // Start streaming live location to the company admin's Track Delivery map.
    _loc = LocationService()..start();
  }

  @override
  void dispose() {
    _loc?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [DeliveriesScreen(), AccountScreen(), DeliveryProfileScreen()];
    return Scaffold(
      body: Column(children: [
        Expanded(child: IndexedStack(index: _index, children: pages)),
        if (_loc != null)
          ListenableBuilder(
            listenable: _loc!,
            builder: (context, _) {
              final ok = _loc!.ok;
              final bg = ok ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED);
              final fg = ok ? const Color(0xFF047857) : const Color(0xFFB45309);
              return Material(
                color: bg,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(children: [
                      Icon(ok ? Icons.gps_fixed_rounded : Icons.gps_off_rounded, size: 15, color: fg),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_loc!.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg))),
                      if (!ok)
                        TextButton(
                          onPressed: () => _loc!.start(),
                          style: TextButton.styleFrom(foregroundColor: fg, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 30)),
                          child: const Text('আবার চেষ্টা', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                ),
              );
            },
          ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'ডেলিভারি'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'অ্যাকাউন্ট'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'প্রোফাইল'),
        ],
      ),
    );
  }
}
