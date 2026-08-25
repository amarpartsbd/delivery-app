import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../config.dart';

/// Configure the always-on location service. Call once at app startup.
/// The service is a foreground service (persistent notification) so location
/// keeps streaming even when the app is backgrounded or closed.
Future<void> initBackgroundLocation() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      autoStartOnBoot: false,
      isForegroundMode: true,
      initialNotificationTitle: 'ডেলিভারি ট্র্যাকিং',
      initialNotificationContent: 'লোকেশন শেয়ার চালু হচ্ছে…',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Background isolate entry point — pings the server every 30s.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }
  service.on('stopService').listen((_) => service.stopSelf());

  const storage = FlutterSecureStorage();
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Future<void> ping() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        return; // logged out — stay quiet
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        service.invoke('update', {'ok': false, 'msg': 'GPS off'});
        return;
      }
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        service.invoke('update', {'ok': false, 'msg': 'no permission'});
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await dio.post(
        '/delivery/location',
        data: {'lat': pos.latitude, 'lng': pos.longitude, 'accuracy': pos.accuracy},
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
      );
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'ডেলিভারি ট্র্যাকিং চালু',
          content: 'আপনার লোকেশন লাইভ শেয়ার হচ্ছে',
        );
      }
      service.invoke('update', {'ok': true, 'at': DateTime.now().toIso8601String()});
    } catch (_) {
      service.invoke('update', {'ok': false, 'msg': 'error'});
    }
  }

  await ping();
  Timer.periodic(const Duration(seconds: 30), (_) => ping());
}
