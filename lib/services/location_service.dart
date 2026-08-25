import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin controller around the always-on background location service. It handles
/// permissions, starts/stops the foreground service and mirrors its status so
/// the UI can show whether live tracking is on. Actual pinging happens in the
/// background isolate (see background_location.dart), so it keeps running even
/// when the app is backgrounded or closed.
class LocationService extends ChangeNotifier {
  LocationService();

  String status = 'লোকেশন চালু হচ্ছে…';
  bool ok = false;

  StreamSubscription? _sub;

  Future<void> start() async {
    if (!await _ensurePermissions()) {
      return;
    }

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }

    _sub?.cancel();
    _sub = service.on('update').listen((event) {
      if (event == null) return;
      if (event['ok'] == true) {
        _set('লাইভ · ব্যাকগ্রাউন্ডেও লোকেশন শেয়ার হচ্ছে', true);
      } else {
        _set(_friendly(event['msg']?.toString() ?? ''), false);
      }
    });

    _set('লোকেশন চালু হচ্ছে…', true);
  }

  Future<void> stop() async {
    FlutterBackgroundService().invoke('stopService');
    await _sub?.cancel();
  }

  Future<bool> _ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _set('ফোনের লোকেশন (GPS) চালু করুন', false);
      return false;
    }

    final loc = await Permission.location.request();
    if (!loc.isGranted) {
      _set('লোকেশন পারমিশন দিন — তারপর Retry চাপুন', false);
      return false;
    }

    // Best effort — "সবসময় অনুমতি দিন" gives the most reliable background tracking.
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }
    // Android 13+ needs this to show the tracking notification.
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    return true;
  }

  String _friendly(String msg) {
    switch (msg) {
      case 'GPS off':
        return 'ফোনের লোকেশন (GPS) চালু করুন';
      case 'no permission':
        return 'লোকেশন পারমিশন দিন — "সবসময় অনুমতি দিন" বেছে নিন';
      default:
        return 'লোকেশন পাঠানো যাচ্ছে না — Retry চাপুন';
    }
  }

  void _set(String s, bool good) {
    status = s;
    ok = good;
    notifyListeners();
  }
}
