import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════
//  WHATSAPP TICKET SERVICE — Share E-Ticket via WhatsApp
//
//  Menggunakan wa.me deep-link agar kompatibel di
//  Android, iOS, dan Web (PWA).
// ═══════════════════════════════════════════════════════════
class WhatsAppTicketService {
  /// Kirim pesan E-Ticket ke WhatsApp.
  ///
  /// [phoneNumber] opsional — jika null, WhatsApp akan membuka
  /// picker kontak. Format: '6281234567890' (tanpa +).
  ///
  /// Returns `true` jika berhasil meluncurkan URL.
  static Future<bool> shareTicketToWhatsApp({
    required String bookingId,
    required String route,
    required String fleetName,
    String? phoneNumber,
  }) async {
    try {
      final message = _buildMessage(
        bookingId: bookingId,
        route: route,
        fleetName: fleetName,
      );

      final encodedMessage = Uri.encodeComponent(message);

      // Gunakan https://wa.me/ supaya support di semua platform
      // termasuk web/PWA.
      final url = phoneNumber != null && phoneNumber.isNotEmpty
          ? 'https://wa.me/$phoneNumber?text=$encodedMessage'
          : 'https://wa.me/?text=$encodedMessage';

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('[WhatsAppTicketService] ✅ WhatsApp launched');
        return true;
      } else {
        debugPrint('[WhatsAppTicketService] ❌ Tidak bisa membuka WhatsApp');
        return false;
      }
    } catch (e) {
      debugPrint('[WhatsAppTicketService] ⚠️ Exception: $e');
      return false;
    }
  }

  /// Susun pesan E-Ticket yang rapi dan informatif.
  static String _buildMessage({
    required String bookingId,
    required String route,
    required String fleetName,
  }) {
    return '''
🚐 *E-Ticket Minang Travel*
━━━━━━━━━━━━━━━━━

📋 *Kode Booking:* $bookingId
🛤️ *Rute:* $route
🚌 *Armada:* $fleetName

Tiket ini sah dan dapat ditunjukkan saat boarding.
Terima kasih telah menggunakan Minang Travel! 🙏
''';
  }
}
