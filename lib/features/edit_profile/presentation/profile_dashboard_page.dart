import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/logout_dialog.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'edit_profile_page.dart';
import 'sesi_login_page.dart';
import 'notifikasi_settings_page.dart';
import 'bahasa_settings_page.dart';
import 'bantuan_cs_page.dart';
import 'syarat_ketentuan_page.dart';
import 'kebijakan_privasi_page.dart';
import 'tentang_aplikasi_page.dart';
import 'daftar_driver_page.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
}

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  int _totalTrips = 0;
  bool _loadingTrips = true;

  @override
  void initState() {
    super.initState();
    _loadTripsCount();
  }

  Future<void> _loadTripsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Get user role first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;
      final role = userDoc.data()?['role'] as String? ?? 'user';

      int count = 0;
      if (role == 'admin') {
        // Driver role: count bookings associated with their fleets
        final fleetsSnap = await FirebaseFirestore.instance
            .collection('fleets')
            .where('driverId', isEqualTo: user.uid)
            .get();

        if (fleetsSnap.docs.isNotEmpty) {
          final fleetIds = fleetsSnap.docs.map((d) => d.id).toList();

          // Firestore 'whereIn' limits to 10 items per query
          final chunkedFleetIds = <List<String>>[];
          for (var i = 0; i < fleetIds.length; i += 10) {
            chunkedFleetIds.add(fleetIds.sublist(
                i, i + 10 > fleetIds.length ? fleetIds.length : i + 10));
          }

          for (final chunk in chunkedFleetIds) {
            final bookingsSnap = await FirebaseFirestore.instance
                .collection('bookings')
                .where('fleetId', whereIn: chunk)
                .get();
            count += bookingsSnap.docs.length;
          }
        }
      } else {
        // Regular passenger: count their bookings
        final bookingsSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .get();
        count = bookingsSnap.docs.length;
      }

      if (mounted) {
        setState(() {
          _totalTrips = count;
          _loadingTrips = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingTrips = false);
      }
    }
  }

  String _getMemberLabel(Timestamp? createdAt) {
    if (createdAt == null) {
      return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.now());
    }
    return DateFormat('dd MMM yyyy', 'id_ID').format(createdAt.toDate());
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: _C.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: _C.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: _C.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: List.generate(items.length, (index) {
            if (index == items.length - 1) return items[index];
            return Column(
              children: [
                items[index],
                const Divider(color: _C.borderLight, height: 1, indent: 60),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Text(
            'Sesi expired. Silakan login kembali.',
            style: GoogleFonts.inter(fontSize: 14, color: _C.textTertiary),
          ),
        ),
      );
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SkeletonLoader.profile();
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['namaLengkap'] as String? ?? user.displayName ?? 'Pengguna';
          final email = data['email'] as String? ?? user.email ?? '';
          final role = data['role'] as String? ?? 'user';
          final profileUrl = data['profileImageUrl'] as String?;
          final createdAt = data['createdAt'] as Timestamp?;

          final isDriver = role == 'admin';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: 40 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══ BLUE HEADER CONTAINER ═══
                Container(
                  padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 60),
                  decoration: const BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      // Centered Title
                      Text(
                        'Akun Saya',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _C.white,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Avatar, Name, Email Row
                      Row(
                        children: [
                          // White bordered circular avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _C.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl != null && profileUrl.isNotEmpty
                                  ? null
                                  : Text(
                                      initial,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Name & details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                // Verified Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 13,
                                        color: Colors.greenAccent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isDriver ? 'Driver Mitra' : 'Terverifikasi',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                    ],
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

                // ═══ STATS CARD (Overlapping) ═══
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _C.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F4C81).withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Col 1: Trips count
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _C.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.ticket_2,
                                  color: _C.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _loadingTrips
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _C.primary,
                                      ),
                                    )
                                  : Text(
                                      '$_totalTrips',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: _C.textPrimary,
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              Text(
                                isDriver ? 'Total Narik' : 'Total Trip',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vertical Divider
                        Container(
                          width: 1,
                          height: 50,
                          color: _C.borderLight,
                        ),

                        // Col 2: Member duration
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _C.teal.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.calendar_1,
                                  color: _C.teal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getMemberLabel(createdAt),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: _C.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bergabung',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ═══ MENU SECTIONS ═══
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Akun Saya
                      _buildSectionHeader('Akun Saya'),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Iconsax.user,
                          title: 'Edit Profil',
                          subtitle: 'Ubah nama, foto, dan informasi lainnya',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfilePage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.monitor,
                          title: 'Sesi Login',
                          subtitle: 'Kelola perangkat yang login',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SesiLoginPage(),
                              ),
                            );
                          },
                        ),
                      ]),

                      // Section 2: Preferensi
                      _buildSectionHeader('Preferensi'),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Iconsax.notification,
                          title: 'Notifikasi',
                          subtitle: 'Atur pemberitahuan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotifikasiSettingsPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.global,
                          title: 'Bahasa',
                          subtitle: 'Indonesia',
                          trailing: Text(
                            'ID',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _C.primary,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BahasaSettingsPage(),
                              ),
                            );
                          },
                        ),
                      ]),

                      // Section 3: Bantuan & Info
                      _buildSectionHeader('Bantuan & Info'),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Iconsax.message_question,
                          title: 'Bantuan & CS',
                          subtitle: 'FAQ dan hubungi kami',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BantuanCsPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.document_text,
                          title: 'Syarat & Ketentuan',
                          subtitle: 'Kebijakan layanan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SyaratKetentuanPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.shield_tick,
                          title: 'Kebijakan Privasi',
                          subtitle: 'Data dan privasi Anda',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const KebijakanPrivasiPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.info_circle,
                          title: 'Tentang Aplikasi',
                          subtitle: 'Versi dan informasi lainnya',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TentangAplikasiPage(),
                              ),
                            );
                          },
                        ),
                        // Only show for passenger role
                        if (!isDriver)
                          _buildMenuItem(
                            icon: Iconsax.truck_fast,
                            title: 'Daftar Jadi Driver',
                            subtitle: 'Bergabung sebagai mitra driver',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DaftarDriverPage(),
                                ),
                              );
                            },
                          ),
                      ]),

                      const SizedBox(height: 36),

                      // Exit Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => AuthUtils.showLogoutConfirmation(context),
                            icon: const Icon(Iconsax.logout_1, size: 18),
                            label: Text(
                              'Keluar dari Akun',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              backgroundColor: const Color(0xFFFEF2F2),
                              side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
