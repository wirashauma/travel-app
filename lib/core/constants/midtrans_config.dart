class MidtransConfig {
  /// Client key — public, aman di Flutter.
  static const String clientKey = 'SB-Mid-client-482qQn-QWNCrxd1D';

  /// false = Sandbox (app.sandbox.midtrans.com)
  /// true  = Production (app.midtrans.com)
  static const bool isProduction = false;

  /// true  = Generate token via Firebase Cloud Functions (server key aman).
  /// false = Generate token langsung dari Flutter (hanya untuk testing).
  static const bool useCloudFunctions = false;

  /// Server key — hanya dipakai jika [useCloudFunctions] == false.
  static const String serverKey = 'SB-Mid-server-54hGCcibaZiviQmtujHrrHh-';

  static String get baseUrl => isProduction
      ? 'https://app.midtrans.com/snap/v1'
      : 'https://app.sandbox.midtrans.com/snap/v1';

  static String get snapRedirectUrl => isProduction
      ? 'https://app.midtrans.com/snap/v2/vtweb'
      : 'https://app.sandbox.midtrans.com/snap/v2/vtweb';

  /// URL callback setelah pembayaran selesai — dideteksi oleh WebView.
  static const String finishRedirectUrl =
      'https://etravel.app/payment-finish';

  /// URL jika pembayaran gagal — dideteksi oleh WebView.
  static const String unfinishRedirectUrl =
      'https://etravel.app/payment-unfinish';

  /// URL jika user menutup Snap sebelum selesai.
  static const String errorRedirectUrl =
      'https://etravel.app/payment-error';
}
