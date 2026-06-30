import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';


import '../../../core/services/firestore_dijkstra_service.dart';
import '../../booking_history/presentation/booking_history_page.dart';
import '../../search_result/presentation/search_result_page.dart';
import 'popular_routes_page.dart';

// ─────────────────────────────────────────────────────────
//  APP COLORS — Consistent with Auth palette
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFDC2626);
  static const Color orange = Color(0xFFF97316);
}

// ═══════════════════════════════════════════════════════════
//  HOME SEARCH PAGE
// ═══════════════════════════════════════════════════════════
class HomeSearchPage extends StatefulWidget {
  const HomeSearchPage({super.key});

  @override
  State<HomeSearchPage> createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends State<HomeSearchPage>
    with SingleTickerProviderStateMixin {
  // ── Form State ────────────────────────────────
  String? _originCity;
  String? _destinationCity;
  DateTime _selectedDate = DateTime.now();
  int _passengers = 1;

  // ── Firestore cities ──────────────────────────
  List<String> _cities = [];
  bool _isLoadingCities = true;

  // ── Swap animation ────────────────────────────
  late AnimationController _swapController;
  late Animation<double> _swapRotation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAFBFD),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _swapRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _swapController, curve: Curves.easeInOutCubic),
    );

    _loadCities();
  }

  // ── Load cities from Firestore routes ─────────
  Future<void> _loadCities() async {
    try {
      final cities = await FirestoreDijkstraService.instance.getAllCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCities = false);
    }
  }

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }


  // ── Greeting based on time ────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // ── Swap origin & destination ─────────────────
  void _swapCities() {
    if (_originCity == null && _destinationCity == null) return;
    _swapController.forward(from: 0);
    setState(() {
      final temp = _originCity;
      _originCity = _destinationCity;
      _destinationCity = temp;
    });
  }

  // ── Date Picker ───────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _C.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _C.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _C.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── City Selector Bottom Sheet ────────────────
  void _showCityPicker({required bool isOrigin}) {
    if (_isLoadingCities) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sedang memuat data kota...',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: _C.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CityPickerSheet(
        title: isOrigin ? 'Pilih Kota Asal' : 'Pilih Kota Tujuan',
        cities: _cities,
        selectedCity: isOrigin ? _originCity : _destinationCity,
        disabledCity: isOrigin ? _destinationCity : _originCity,
        onSelect: (city) {
          setState(() {
            if (isOrigin) {
              _originCity = city;
            } else {
              _destinationCity = city;
            }
          });
        },
      ),
    );
  }

  // ── Search Action ─────────────────────────────
  void _handleSearch() {
    if (_originCity == null || _destinationCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih kota asal dan tujuan terlebih dahulu',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: _C.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Navigate to Search Result page
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SearchResultPage(
          origin: _originCity!,
          destination: _destinationCity!,
          date: _selectedDate,
          passengers: _passengers,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ HEADER ═══════════════════════════
            _buildHeader(topPadding),

            const SizedBox(height: 24),

            // ═══ SEARCH CARD ══════════════════════
            _buildSearchCard(),

            const SizedBox(height: 32),

            // ═══ POPULAR ROUTES ═══════════════════
            _buildPopularRoutes(),

            const SizedBox(height: 32),

            // ═══ PROMO BANNER ═════════════════════
            _buildPromoBanner(),

            SizedBox(
              height: MediaQuery.of(context).padding.bottom + 24,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  1. HEADER
  // ─────────────────────────────────────────────────
  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 24),
      decoration: const BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $_greeting 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mau bepergian ke mana hari ini?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _C.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // History button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const BookingHistoryPage(),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                          parent: anim, curve: Curves.easeOut),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border, width: 1),
              ),
              child: const Icon(
                Iconsax.document_text,
                size: 20,
                color: _C.primary,
              ),
            ),
          ),

        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: -0.05, duration: 450.ms, curve: Curves.easeOutCubic);
  }

  // ─────────────────────────────────────────────────
  //  2. SEARCH CARD — Grab/Gojek‑inspired design
  // ─────────────────────────────────────────────────
  Widget _buildSearchCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F4C81).withValues(alpha: 0.06),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Route section ─────────────────────
            _buildRouteSection(),

            // ── Divider ────────────────────────────
            Container(height: 1, color: _C.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                children: [
                  // ── Date & Passengers row ──────────
                  Row(
                    children: [
                      Expanded(child: _buildDateChip()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPassengerChip()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Search Button ──────────────────
                  _buildSearchButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(
          begin: 0.08,
          delay: 200.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ── Route Section — connected Grab‑style ────────
  Widget _buildRouteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: dot‑connector line
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                // Origin dot
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _C.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _C.success.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Connector line
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _C.success.withValues(alpha: 0.4),
                          _C.danger.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Destination dot
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _C.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _C.danger.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right: fields
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Origin
                _buildLocationTile(
                  label: 'Dari',
                  value: _originCity,
                  hint: 'Kota asal',
                  onTap: () => _showCityPicker(isOrigin: true),
                ),
                // Swap button
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _swapCities,
                    child: RotationTransition(
                      turns: _swapRotation,
                      child: Container(
                        width: 32, height: 32,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.07),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.arrow_swap_horizontal,
                          size: 16, color: _C.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Destination
                _buildLocationTile(
                  label: 'Ke',
                  value: _destinationCity,
                  hint: 'Kota tujuan',
                  onTap: () => _showCityPicker(isOrigin: false),
                ),
              ],
            ),
          ),
          // Right arrow indicator
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: _C.textTertiary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── Location Tile — minimal line‑based input ────
  Widget _buildLocationTile({
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _C.borderLight, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _C.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? hint,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: value != null ? FontWeight.w700 : FontWeight.w400,
                      color: value != null ? _C.textPrimary : _C.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date Chip ────────────────────────────────────
  Widget _buildDateChip() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final formatted = isToday
        ? 'Hari Ini'
        : DateFormat('EEE, d MMM', 'id_ID').format(_selectedDate);

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.calendar_1, size: 16, color: _C.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tanggal',
                    style: GoogleFonts.inter(
                      fontSize: 9.5, fontWeight: FontWeight.w500,
                      color: _C.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5, fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Passenger Chip ───────────────────────────────
  Widget _buildPassengerChip() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Penumpang',
                  style: GoogleFonts.inter(
                    fontSize: 9.5, fontWeight: FontWeight.w500,
                    color: _C.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_passengers Orang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5, fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniBtn(Icons.remove_rounded, _passengers > 1,
                  () { if (_passengers > 1) setState(() => _passengers--); }
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '$_passengers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5, fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
              ),
              _miniBtn(Icons.add_rounded, _passengers < 14,
                  () { if (_passengers < 14) setState(() => _passengers++); }
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: enabled ? _C.primary.withValues(alpha: 0.08) : _C.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? _C.primary.withValues(alpha: 0.15)
                : _C.borderLight,
          ),
        ),
        child: Icon(icon, size: 13, color: enabled ? _C.primary : _C.textHint),
      ),
    );
  }

  // ── Search Button ───────────────────────────────
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: _handleSearch,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _C.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_normal, size: 18, color: _C.white),
            const SizedBox(width: 10),
            Text(
              'Cari Tiket',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _C.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  3. POPULAR ROUTES
  // ─────────────────────────────────────────────────
  Widget _buildPopularRoutes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rute Populer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const PopularRoutesPage(),
                      transitionsBuilder: (_, anim, __, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                              parent: anim, curve: Curves.easeOut),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration:
                          const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _C.primary,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 450.ms, duration: 450.ms),

        const SizedBox(height: 16),

        // Horizontal list — 4 rute populer Sumatera Barat
        SizedBox(
          height: 155,
          child: Builder(
            builder: (context) {
              const sumbarRoutes = [
                {'from': 'Padang', 'to': 'Bukittinggi', 'price': 45000, 'duration': '2 Jam', 'tag': 'Populer'},
                {'from': 'Padang', 'to': 'Payakumbuh', 'price': 55000, 'duration': '3 Jam', 'tag': null},
                {'from': 'Bukittinggi', 'to': 'Pekanbaru', 'price': 120000, 'duration': '5 Jam', 'tag': 'Antarprovinsi'},
                {'from': 'Padang', 'to': 'Solok', 'price': 40000, 'duration': '1.5 Jam', 'tag': null},
              ];
              final formatter = NumberFormat('#,###', 'id_ID');
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sumbarRoutes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final r = sumbarRoutes[index];
                  final from = r['from'] as String;
                  final to = r['to'] as String;
                  final price = r['price'] as int;
                  final duration = r['duration'] as String;
                  final tag = r['tag'] as String?;
                  return _PopularRouteCard(
                    from: from,
                    to: to,
                    price: 'Rp ${formatter.format(price)}',
                    duration: duration,
                    tag: tag,
                    tagColor: tag == 'Antarprovinsi' ? _C.orange : (tag != null ? _C.teal : null),
                    onTap: () => _onPopularRouteTap(from, to),
                  )
                      .animate()
                      .fadeIn(
                        delay: (550 + index * 100).ms,
                        duration: 450.ms,
                      )
                      .slideX(
                        begin: 0.08,
                        delay: (550 + index * 100).ms,
                        duration: 450.ms,
                        curve: Curves.easeOutCubic,
                      );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Popular Route Tap → auto-fill origin/destination ──
  void _onPopularRouteTap(String fromName, String toName) {
    setState(() {
      _originCity = fromName;
      _destinationCity = toName;
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Rute $fromName → $toName dipilih',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: _C.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ─────────────────────────────────────────────────
  //  4. PROMO BANNER
  // ─────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          onTap: () {
            Clipboard.setData(
              const ClipboardData(text: 'MINANG20'),
            );
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Kode Promo MINANG20 berhasil disalin!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: _C.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
          },
          child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.primary,
              _C.primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PROMO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Diskon 20% untuk\nperjalanan pertama!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan kode: MINANG20',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Iconsax.ticket_discount,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 500.ms)
        .slideY(
          begin: 0.08,
          delay: 700.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.97, 0.97),
          delay: 700.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ═══════════════════════════════════════════════════════════
//  POPULAR ROUTE CARD WIDGET
// ═══════════════════════════════════════════════════════════
class _PopularRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final String price;
  final String duration;
  final String? tag;
  final Color? tagColor;
  final VoidCallback? onTap;

  const _PopularRouteCard({
    required this.from,
    required this.to,
    required this.price,
    required this.duration,
    this.tag,
    this.tagColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: _C.primary.withValues(alpha: 0.08),
        highlightColor: _C.primary.withValues(alpha: 0.04),
        onTap: onTap,
        child: Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag (optional)
          if (tag != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (tagColor ?? _C.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: tagColor ?? _C.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 4),

          // Route
          Row(
            children: [
              Flexible(
                child: Text(
                  from,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Iconsax.arrow_right_3,
                  size: 14,
                  color: _C.textTertiary.withValues(alpha: 0.6),
                ),
              ),
              Flexible(
                child: Text(
                  to,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: _C.borderLight,
          ),

          // Price + duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _C.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.clock,
                      size: 12,
                      color: _C.textTertiary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        duration,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _C.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CITY PICKER BOTTOM SHEET — Firestore-driven (List<String>)
// ═══════════════════════════════════════════════════════════
class _CityPickerSheet extends StatefulWidget {
  final String title;
  final List<String> cities;
  final String? selectedCity;
  final String? disabledCity;
  final ValueChanged<String> onSelect;

  const _CityPickerSheet({
    required this.title,
    required this.cities,
    this.selectedCity,
    this.disabledCity,
    required this.onSelect,
  });

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.cities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(widget.cities);
      } else {
        _filtered = widget.cities
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _C.textPrimary,
              ),
              cursorColor: _C.primary,
              decoration: InputDecoration(
                hintText: 'Cari kota...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: _C.textHint,
                ),
                prefixIcon: const Icon(
                  Iconsax.search_normal,
                  size: 18,
                  color: _C.textTertiary,
                ),
                filled: true,
                fillColor: _C.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _C.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // City count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} kota ditemukan',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _C.textTertiary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // City list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(12, 4, 12, bottomPadding + 16),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final city = _filtered[index];
                final isSelected = city == widget.selectedCity;
                final isDisabled = city == widget.disabledCity;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isDisabled
                        ? null
                        : () {
                            widget.onSelect(city);
                            Navigator.pop(context);
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _C.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? _C.inputFill
                                  : _C.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Iconsax.building,
                              size: 16,
                              color: isDisabled
                                  ? _C.textHint
                                  : _C.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              city,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDisabled
                                    ? _C.textHint
                                    : _C.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Iconsax.tick_circle5,
                              size: 20,
                              color: _C.primary.withValues(alpha: 0.7),
                            ),
                          if (isDisabled)
                            Text(
                              'Sudah dipilih',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _C.textHint,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
