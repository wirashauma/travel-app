import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/midtrans_config.dart';
import '../../../core/services/booking_service.dart';

/// Halaman WebView untuk menampilkan Midtrans Snap Payment Page.
///
/// Setelah user menyelesaikan pembayaran, Snap akan redirect ke
/// `finishRedirectUrl`. WebView mendeteksi URL tersebut dan
/// otomatis mengkonfirmasi pembayaran di Firestore.
class MidtransWebviewPage extends StatefulWidget {
  final String bookingId;
  final String bookingCode;

  /// URL Snap yang akan dibuka di WebView.
  /// Format: https://app.sandbox.midtrans.com/snap/v2/vtweb/{snap_token}
  final String snapUrl;

  /// Optional callback untuk konfirmasi pembayaran kustom (misal untuk package).
  /// Jika null, menggunakan [BookingService.confirmPayment].
  final Future<void> Function()? onPaymentSuccess;

  const MidtransWebviewPage({
    super.key,
    required this.bookingId,
    required this.bookingCode,
    required this.snapUrl,
    this.onPaymentSuccess,
  });

  @override
  State<MidtransWebviewPage> createState() => _MidtransWebviewPageState();
}

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFEF4444);
  static const Color textTertiary = Color(0xFF94A3B8);
}

class _MidtransWebviewPageState extends State<MidtransWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentDone = false;
  bool _isProcessing = false;
  int _loadingProgress = 0;
  Timer? _timeoutTimer;

  /// Waktu maksimal menunggu pembayaran sebelum timeout.
  static const _kTimeoutSeconds = 900;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadingProgress = 100;
              });
            }
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onNavigationRequest: (request) {
            return _handleNavigation(request.url);
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: $error');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));

    // Auto-cancel jika user tidak selesai dalam 15 menit
    _timeoutTimer = Timer(const Duration(seconds: _kTimeoutSeconds), () {
      if (mounted && !_paymentDone) {
        _showExpiredDialog();
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// Deteksi redirect URL dari Midtrans Snap.
  NavigationDecision _handleNavigation(String url) {
    // Payment selesai (sukses)
    if (url.startsWith(MidtransConfig.finishRedirectUrl)) {
      _confirmAndNavigate();
      return NavigationDecision.prevent;
    }

    // Payment gagal atau dibatalkan user
    if (url.startsWith(MidtransConfig.unfinishRedirectUrl) ||
        url.startsWith(MidtransConfig.errorRedirectUrl)) {
      _showPaymentFailedDialog();
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Konfirmasi pembayaran di Firestore → kembali ke PaymentPage untuk redirect.
  Future<void> _confirmAndNavigate() async {
    if (_isProcessing || _paymentDone) return;
    setState(() => _isProcessing = true);

    _timeoutTimer?.cancel();

    try {
      if (widget.onPaymentSuccess != null) {
        await widget.onPaymentSuccess!();
      } else {
        await BookingService.confirmPayment(widget.bookingId);
      }

      if (!mounted) return;
      setState(() {
        _paymentDone = true;
        _isProcessing = false;
      });

      // Pop back to PaymentPage with success result
      // PaymentPage will handle the redirect to LiveETicketPage
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal konfirmasi pembayaran: $e',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: _C.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.clock, color: _C.danger, size: 22),
            const SizedBox(width: 8),
            Text(
              'Waktu Habis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Batas waktu pembayaran 15 menit telah habis.\n\n'
          'Pesanan akan dibatalkan secara otomatis.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textTertiary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            child: Text(
              'Kembali',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailedDialog() {
    if (!mounted || _paymentDone) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.close_circle, color: _C.danger, size: 22),
            const SizedBox(width: 8),
            Text(
              'Pembayaran Gagal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Pembayaran tidak berhasil.\n\n'
          'Silakan coba lagi atau hubungi customer service.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textTertiary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: _paymentDone,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            // App Bar
            _buildAppBar(topPadding),
            // Loading bar
            if (_isLoading) _buildLoadingBar(),
            // WebView
            Expanded(
              child: _paymentDone
                  ? _buildSuccessOverlay()
                  : WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 20, 16),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isProcessing ? null : _confirmExit,
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: const Color(0xFF0F172A),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Text(
            'Pembayaran Midtrans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildLoadingBar() {
    return LinearProgressIndicator(
      value: _loadingProgress / 100,
      backgroundColor: const Color(0xFFF1F5F9),
      valueColor: const AlwaysStoppedAnimation<Color>(_C.primary),
      minHeight: 2,
    );
  }

  Widget _buildSuccessOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _C.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.tick_circle,
              size: 48,
              color: _C.success,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 20),
          Text(
            'Pembayaran Berhasil!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _C.success,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Mengarahkan ke e-tiket...',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _C.textTertiary,
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Batalkan Pembayaran?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Jika Anda keluar, silakan lanjutkan pembayaran dari halaman '
          'riwayat pemesanan.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF475569),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Tetap Bayar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Keluar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _C.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, false);
    }
  }
}
