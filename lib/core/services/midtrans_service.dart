import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/midtrans_config.dart';

/// Hasil dari generate Snap token.
class MidtransTokenResult {
  final String token;
  final String redirectUrl;

  const MidtransTokenResult({
    required this.token,
    required this.redirectUrl,
  });
}

/// Service untuk berkomunikasi dengan Midtrans Snap API.
///
/// Dokumentasi Snap API: https://docs.midtrans.com/reference/snap-api
///
/// ## Alur (via Cloud Functions)
/// 1. Flutter → call `generateSnapToken` Cloud Function
/// 2. Cloud Function → POST `/snap/v1/transactions` → Midtrans
/// 3. Midtrans → return `{ token, redirect_url }` → Cloud Function → Flutter
/// 4. Flutter → Buka `redirect_url` di WebView
/// 5. User bayar di halaman Snap
/// 6. WebView deteksi callback → `BookingService.confirmPayment()`
class MidtransService {
  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Encode server key untuk Basic Auth (fallback direct API).
  static String get _authHeader {
    final credentials = '${MidtransConfig.serverKey}:';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  /// Generate Snap token via direct API call.
  static Future<MidtransTokenResult> generateSnapToken({
    required String orderId,
    required int grossAmount,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? itemName,
    int? itemQuantity,
  }) async {
    return _generateViaDirectApi(
      orderId: orderId,
      grossAmount: grossAmount,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      itemName: itemName,
      itemQuantity: itemQuantity,
    );
  }

  /// ── Via direct API call (server key di Flutter) ──
  static Future<MidtransTokenResult> _generateViaDirectApi({
    required String orderId,
    required int grossAmount,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? itemName,
    int? itemQuantity,
  }) async {
    final qty = itemQuantity ?? 1;
    final pricePerItem = grossAmount ~/ qty;

    final body = {
      'transaction_details': {
        'order_id': orderId,
        'gross_amount': grossAmount,
      },
      'customer_details': {
        if (customerName != null) 'first_name': customerName,
        if (customerEmail != null) 'email': customerEmail,
        if (customerPhone != null) 'phone': customerPhone,
      },
      'item_details': [
        for (var i = 0; i < qty; i++)
          {
            'id': i == 0 ? orderId : '$orderId-${i + 1}',
            'price': i == qty - 1
                ? grossAmount - (pricePerItem * (qty - 1))
                : pricePerItem,
            'quantity': 1,
            'name': itemName ?? 'Tiket Travel',
            'category': 'Transportasi',
          },
      ],
      'callbacks': {
        'finish': MidtransConfig.finishRedirectUrl,
        'unfinish': MidtransConfig.unfinishRedirectUrl,
        'error': MidtransConfig.errorRedirectUrl,
      },
      'enabled_payments': [
        'bca_va',
        'bni_va',
        'bri_va',
        'mandiri_va',
        'gopay',
        'shopeepay',
        'qris',
      ],
    };

    final response = await http.post(
      Uri.parse('${MidtransConfig.baseUrl}/transactions'),
      headers: {
        ..._headers,
        'Authorization': _authHeader,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw MidtransException(
        'Gagal generate Snap token',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final redirectUrl = data['redirect_url'] as String;

    return MidtransTokenResult(token: token, redirectUrl: redirectUrl);
  }
}

class MidtransException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const MidtransException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    final buf = StringBuffer('MidtransException: $message');
    if (statusCode != null) buf.write(' (HTTP $statusCode)');
    if (body != null && body!.isNotEmpty) {
      buf.write('\nResponse: $body');
    }
    return buf.toString();
  }
}
