class AppConfig {
  /// Single API base for all tenants — the company is resolved from the
  /// authenticated user. Works for custom-domain tenants too.
  ///
  /// Dev tips:
  ///   Android emulator → http://10.0.2.2:8131/api/v1/app
  ///   iOS simulator    → https://erp.sahin.cloud/api/v1/app
  static const String apiBaseUrl = 'https://erp.sahin.cloud/api/v1/app';

  static const String appName = 'Turn360 Delivery';
}
