import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SuratJalanPreviewPage extends StatelessWidget {
  final String driverName;
  final String licensePlate;
  final String vehicleType;
  final String origin;
  final String destination;
  final String departureTime;

  const SuratJalanPreviewPage({
    super.key,
    required this.driverName,
    required this.licensePlate,
    required this.vehicleType,
    required this.origin,
    required this.destination,
    required this.departureTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Surat Jalan - $driverName',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'surat_jalan_${driverName.toLowerCase().replaceAll(' ', '_')}.pdf',
        loadingWidget: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F4C81)),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final todayStr = DateFormat('dd MMMM yyyy', 'id').format(DateTime.now());
    final dayOfWeek = DateFormat('EEEE', 'id').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── KOP SURAT (LETTERHEAD) ──
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MINANG TRAVEL',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      width: 50,
                      height: 50,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                        shape: pw.BoxShape.circle,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'MT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.blue900),
                pw.SizedBox(height: 20),

                // ── JUDUL SURAT ──
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'SURAT TUGAS KEBERANGKATAN / SURAT JALAN',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                // ── ISI SURAT ──
                pw.Text(
                  'Dengan ini, Manajemen Operasional Minang Travel menerbitkan Surat Tugas Keberangkatan / Surat Jalan resmi kepada pengemudi di bawah ini:',
                  style: pw.TextStyle(fontSize: 10.5, color: PdfColors.black),
                ),
                pw.SizedBox(height: 16),

                // ── TABEL DETAIL TUGAS ──
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(160),
                    1: const pw.FixedColumnWidth(300),
                  },
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  children: [
                    _pdfTableRow('Nama Pengemudi', driverName),
                    _pdfTableRow('Model / Tipe Armada', vehicleType.isNotEmpty ? vehicleType : 'Minibus'),
                    _pdfTableRow('Nomor Plat Kendaraan', licensePlate),
                    _pdfTableRow('Rute Perjalanan', '$origin ke $destination'),
                    _pdfTableRow('Jam Keberangkatan', departureTime),
                    _pdfTableRow('Hari & Tanggal Tugas', '$dayOfWeek, $todayStr'),
                  ],
                ),
                pw.SizedBox(height: 20),

                // ── KETENTUAN TUGAS ──
                pw.Text(
                  'Ketentuan Penugasan:',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 4),
                pw.Bullet(
                  text: 'Pengemudi wajib berkendara dengan mengutamakan keselamatan penumpang dan barang.',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
                pw.Bullet(
                  text: 'Pengemudi wajib meneliti manifest penumpang dan paket sebelum keberangkatan.',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
                pw.Bullet(
                  text: 'Surat tugas ini bersifat resmi dan wajib dibawa selama masa perjalanan tugas berlangsung.',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 40),

                // ── TANDA TANGAN ──
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Penerima Tugas,', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 45),
                        pw.Text(driverName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Container(width: 100, height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 2),
                        pw.Text('Pengemudi Resmi', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Pemberi Tugas,', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 45),
                        pw.Text('Minang Travel Admin', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Container(width: 100, height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 2),
                        pw.Text('Manajer Operasional', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
          ),
        ),
      ],
    );
  }
}
