import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/booking_model.dart';

// ═══════════════════════════════════════════════════════════
//  PDF TICKET SERVICE — Generate beautiful E-Ticket PDF
//
//  Generates a professional A4 PDF with:
//  - E-Travel branded header
//  - Booking details (code, route, date, fleet, price)
//  - QR Code (barcode) from booking code
//  - Perforated-style layout
// ═══════════════════════════════════════════════════════════
class PdfTicketService {
  static const _navy = PdfColor.fromInt(0xFF0F4C81);
  static const _textPrimary = PdfColor.fromInt(0xFF0F172A);
  static const _textSecondary = PdfColor.fromInt(0xFF475569);
  static const _textTertiary = PdfColor.fromInt(0xFF94A3B8);
  static const _borderLight = PdfColor.fromInt(0xFFF1F5F9);
  static const _success = PdfColor.fromInt(0xFF059669);
  static const _bg = PdfColor.fromInt(0xFFFAFBFD);

  /// Generate a PDF [Uint8List] for the given [booking].
  static Future<Uint8List> generateTicketPdf(BookingModel booking) async {
    final doc = pw.Document(
      title: 'E-Ticket ${booking.bookingCode}',
      author: 'E-Travel',
    );

    // Load fonts
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontMedium = await PdfGoogleFonts.interMedium();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontExtraBold = await PdfGoogleFonts.interExtraBold();
    final fontMono = await PdfGoogleFonts.jetBrainsMonoBold();

    // Price formatter
    final priceFmt = NumberFormat('#,###', 'id_ID');
    final priceStr = 'Rp ${priceFmt.format(booking.totalPrice)}';

    // Status
    String statusLabel;
    PdfColor statusColor;
    switch (booking.status) {
      case BookingStatus.paid:
        statusLabel = 'LUNAS';
        statusColor = _success;
        break;
      case BookingStatus.validated:
        statusLabel = 'TERVALIDASI';
        statusColor = const PdfColor.fromInt(0xFF0284C7);
        break;
      case BookingStatus.used:
        statusLabel = 'TERVALIDASI';
        statusColor = const PdfColor.fromInt(0xFF0284C7);
        break;
      case BookingStatus.completed:
        statusLabel = 'DIGUNAKAN';
        statusColor = const PdfColor.fromInt(0xFF0284C7);
        break;
      case BookingStatus.cancelled:
        statusLabel = 'DIBATALKAN';
        statusColor = const PdfColor.fromInt(0xFFDC2626);
        break;
      default:
        statusLabel = 'PENDING';
        statusColor = const PdfColor.fromInt(0xFFD97706);
    }

    // Seat label
    final seatLabel = booking.seatNumbers.isNotEmpty
        ? booking.seatNumbers.map((s) => 'No. $s').join(', ')
        : '${booking.seatsBooked} kursi';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ═══ HEADER ═══
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: _navy,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(16),
                    topRight: pw.Radius.circular(16),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'E-TRAVEL',
                          style: pw.TextStyle(
                            font: fontExtraBold,
                            fontSize: 22,
                            color: PdfColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Electronic Ticket',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 11,
                            color: const PdfColor.fromInt(0xAAFFFFFF),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        statusLabel,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ═══ ROUTE SECTION ═══
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'DARI',
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  fontSize: 9,
                                  color: _textTertiary,
                                  letterSpacing: 1,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                booking.origin,
                                style: pw.TextStyle(
                                  font: fontExtraBold,
                                  fontSize: 20,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: _navy.shade(0.95),
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Text(
                            '→',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: _navy,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'TUJUAN',
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  fontSize: 9,
                                  color: _textTertiary,
                                  letterSpacing: 1,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                booking.destination,
                                style: pw.TextStyle(
                                  font: fontExtraBold,
                                  fontSize: 20,
                                  color: _textPrimary,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 20),

                    // Date strip
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _bg,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: _borderLight, width: 0.5),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            booking.departureDate.isNotEmpty
                                ? booking.departureDate
                                : '-',
                            style: pw.TextStyle(
                              font: fontMedium,
                              fontSize: 12,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ═══ PERFORATED LINE (simulated) ═══
              pw.Container(
                height: 1,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: _borderLight,
                      width: 1,
                      style: pw.BorderStyle.dashed,
                    ),
                  ),
                ),
              ),

              // ═══ DETAILS SECTION ═══
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                child: pw.Column(
                  children: [
                    _pdfDetailRow(
                      'Nama Penumpang',
                      booking.userName,
                      fontMedium,
                      fontBold,
                    ),
                    pw.SizedBox(height: 14),
                    _pdfDetailRow(
                      'Nomor Kursi',
                      seatLabel,
                      fontMedium,
                      fontBold,
                    ),
                    pw.SizedBox(height: 14),
                    _pdfDetailRow(
                      'Armada',
                      booking.fleetName,
                      fontMedium,
                      fontBold,
                    ),
                    pw.SizedBox(height: 14),
                    _pdfDetailRow(
                      'Kode Booking',
                      booking.bookingCode,
                      fontMedium,
                      fontMono,
                      valueColor: _navy,
                    ),
                    pw.SizedBox(height: 14),

                    // Divider
                    pw.Container(height: 1, color: _borderLight),
                    pw.SizedBox(height: 14),

                    // Price
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Dibayar',
                          style: pw.TextStyle(
                            font: fontMedium,
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                        pw.Text(
                          priceStr,
                          style: pw.TextStyle(
                            font: fontExtraBold,
                            fontSize: 18,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ═══ QR CODE SECTION ═══
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(16),
                    bottomRight: pw.Radius.circular(16),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      height: 1,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: _borderLight,
                            width: 1,
                            style: pw.BorderStyle.dashed,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // QR
                    pw.Center(
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(
                          errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                        ),
                        data: booking.bookingCode,
                        width: 140,
                        height: 140,
                        color: _textPrimary,
                      ),
                    ),

                    pw.SizedBox(height: 14),

                    pw.Center(
                      child: pw.Text(
                        booking.bookingCode,
                        style: pw.TextStyle(
                          font: fontMono,
                          fontSize: 14,
                          color: _navy,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 16),

                    // Instruction
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _bg,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'Tunjukkan QR Code ini kepada sopir saat naik',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ═══ FOOTER ═══
              pw.Center(
                child: pw.Text(
                  'E-Travel — Perjalanan Nyaman, Harga Terjangkau',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9,
                    color: _textTertiary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Helper: detail row
  static pw.Widget _pdfDetailRow(
    String label,
    String value,
    pw.Font labelFont,
    pw.Font valueFont, {
    PdfColor valueColor = _textPrimary,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: labelFont,
            fontSize: 11,
            color: _textSecondary,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: valueFont, fontSize: 13, color: valueColor),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  SAVE PDF to device storage
  // ─────────────────────────────────────────────────────
  static Future<File> savePdf(BookingModel booking) async {
    final bytes = await generateTicketPdf(booking);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'E-Ticket_${booking.bookingCode}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ─────────────────────────────────────────────────────
  //  SHARE PDF via share_plus
  // ─────────────────────────────────────────────────────
  static Future<void> sharePdf(BookingModel booking) async {
    final file = await savePdf(booking);
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'E-Ticket ${booking.bookingCode} — '
          '${booking.origin} → ${booking.destination}',
      subject: 'E-Ticket Perjalanan ${booking.bookingCode}',
    );
  }

  // ─────────────────────────────────────────────────────
  //  PRINT / PREVIEW PDF via printing package
  // ─────────────────────────────────────────────────────
  static Future<void> printPdf(BookingModel booking) async {
    final bytes = await generateTicketPdf(booking);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
