import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'services/background_location.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/delivery_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBackgroundLocation();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: const DeliveryApp(),
    ),
  );
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(state.brandColor),
      home: switch (state.status) {
        AuthStatus.unknown => const _Splash(),
        AuthStatus.loggedOut => const LoginScreen(),
        AuthStatus.loggedIn => const DeliveryHome(),
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
