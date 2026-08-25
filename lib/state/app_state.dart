import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// Holds session (token, user, company) and exposes the shared [ApiClient].
class AppState extends ChangeNotifier {
  AppState();

  final ApiClient api = ApiClient();
  final _storage = const FlutterSecureStorage();

  AuthStatus status = AuthStatus.unknown;
  Map<String, dynamic>? user;
  Map<String, dynamic>? company;

  String? get token => _token;
  String? _token;

  /// Company primary colour for theming (falls back to indigo).
  Color get brandColor {
    final hex = company?['primary_color']?.toString();
    if (hex != null && hex.startsWith('#') && hex.length == 7) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return const Color(0xFF4F46E5);
  }

  String get currency => (company?['currency_symbol'] ?? '৳').toString();

  bool can(String permission) {
    final roles = (user?['roles'] as List?)?.cast<String>() ?? const [];
    if (roles.contains('Super Admin')) return true;
    final perms = (user?['permissions'] as List?)?.cast<String>() ?? const [];
    return perms.contains(permission);
  }

  Future<void> bootstrap() async {
    _token = await _storage.read(key: 'token');
    if (_token == null) {
      _set(AuthStatus.loggedOut);
      return;
    }
    api.setToken(_token);
    try {
      final me = await api.get('/me');
      user = Map<String, dynamic>.from(me['user']);
      company = me['company'] != null ? Map<String, dynamic>.from(me['company']) : null;
      _set(AuthStatus.loggedIn);
    } catch (_) {
      await logout();
    }
  }

  /// Phone + password login (delivery app — no OTP).
  Future<void> loginPhone(String phone, String password) async {
    final res = await api.post('/login-phone', body: {
      'phone': phone,
      'password': password,
      'device_name': 'mobile',
    });
    await _saveSession(res);
  }

  Future<void> _saveSession(dynamic res) async {
    _token = res['token'];
    await _storage.write(key: 'token', value: _token);
    api.setToken(_token);
    user = Map<String, dynamic>.from(res['user']);
    company = res['company'] != null ? Map<String, dynamic>.from(res['company']) : null;
    _set(AuthStatus.loggedIn);
  }

  Future<void> logout() async {
    // Stop the always-on location foreground service.
    FlutterBackgroundService().invoke('stopService');
    try {
      await api.post('/logout');
    } catch (_) {}
    await _storage.delete(key: 'token');
    _token = null;
    api.setToken(null);
    user = null;
    company = null;
    _set(AuthStatus.loggedOut);
  }

  void _set(AuthStatus s) {
    status = s;
    notifyListeners();
  }
}
