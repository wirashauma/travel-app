import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════
//  EMAIL TICKET SERVICE — Send E-Ticket via EmailJS REST API
//
//  Menggunakan EmailJS free-tier (frontend-only, tanpa Node).
//  Endpoint: https://api.emailjs.com/api/v1.0/email/send
//
//  SETUP:
//  1. Buat akun di https://www.emailjs.com
//  2. Buat Email Service (Gmail/Outlook) → dapatkan service_id
//  3. Buat Email Template → dapatkan template_id
//     Template variables: {{user_name}}, {{user_email}},
//     {{booking_id}}, {{route}}, {{fleet_name}}
//  4. Salin Public Key dari Account → Integration → dapatkan user_id
//  5. Isi ketiga placeholder di bawah.
// ═══════════════════════════════════════════════════════════
class EmailTicketService {
  // ── EmailJS Credentials (isi dengan milik Anda) ──
  static const String _serviceId = 'YOUR_SERVICE_ID';
  static const String _templateId = 'YOUR_TEMPLATE_ID';
  static const String _userId = 'YOUR_PUBLIC_KEY'; // public key

  static const String _endpoint =
      'https://api.emailjs.com/api/v1.0/email/send';

  /// Kirim E-Ticket ke email pengguna via EmailJS.
  ///
  /// Returns `true` jika berhasil, `false` jika gagal.
  /// Tidak melempar exception — aman dipanggil tanpa crash.
  static Future<bool> sendEmailTicket({
    required String userEmail,
    required String userName,
    required String bookingId,
    required String route,
    required String fleetName,
  }) async {
    try {
      final body = jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _userId,
        'template_params': {
          'user_name': userName,
          'user_email': userEmail,
          'booking_id': bookingId,
          'route': route,
          'fleet_name': fleetName,
        },
      });

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('[EmailTicketService] ✅ Email terkirim ke $userEmail');
        return true;
      } else {
        debugPrint(
          '[EmailTicketService] ❌ Gagal kirim email — '
          'status: ${response.statusCode}, body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      // Internet putus, timeout, atau error lain — tidak crash.
      debugPrint('[EmailTicketService] ⚠️ Exception: $e');
      return false;
    }
  }
}
