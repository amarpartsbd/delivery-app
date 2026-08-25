import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    final password = _password.text;
    if (phone.length < 6) {
      setState(() => _error = 'সঠিক মোবাইল নম্বর দিন।');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'পাসওয়ার্ড দিন।');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      await context.read<AppState>().loginPhone(phone, password);
      // On success the app navigates via AuthStatus listener; nothing else here.
    } catch (e) {
      setState(() => _error = _clean(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _clean(String raw) {
    final m = RegExp(r'credentials do not match', caseSensitive: false);
    if (m.hasMatch(raw)) return 'ভুল মোবাইল নম্বর বা পাসওয়ার্ড।';
    return raw.replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<AppState>().brandColor;
    return Scaffold(
      body: Stack(children: [
        // Brand gradient top
        Container(height: 320, decoration: BoxDecoration(gradient: brandGradient(brand))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  height: 84, width: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
                  ),
                  child: Icon(Icons.two_wheeler_rounded, color: brand, size: 42),
                ),
              ),
              const SizedBox(height: 20),
              Text(AppConfig.appName, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
              const SizedBox(height: 6),
              const Text('আপনার অ্যাকাউন্টে প্রবেশ করুন', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 34),
              // Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: softCard(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('মোবাইল নম্বর', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                    decoration: const InputDecoration(hintText: '01XXXXXXXXX', prefixIcon: Icon(Icons.phone_iphone_rounded)),
                  ),
                  const SizedBox(height: 16),
                  const Text('পাসওয়ার্ড', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.error_outline_rounded, color: kDanger, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12.5))),
                    ]),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('লগইন করুন'),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              const Text('অফিস থেকে দেওয়া মোবাইল নম্বর ও পাসওয়ার্ড দিয়ে লগইন করুন।',
                  textAlign: TextAlign.center, style: TextStyle(color: kFaint, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }
}
