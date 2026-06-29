// ignore_for_file: unused_field, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
}

// ─────────────────────────────────────────────────────────
//  USER ROLE ENUM
// ─────────────────────────────────────────────────────────
enum UserRole { user, admin, superAdmin }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.user:
        return _C.info;
      case UserRole.admin:
        return _C.teal;
      case UserRole.superAdmin:
        return _C.primary;
    }
  }

  Color get bgColor {
    switch (this) {
      case UserRole.user:
        return _C.infoBg;
      case UserRole.admin:
        return _C.teal.withValues(alpha: 0.08);
      case UserRole.superAdmin:
        return _C.primary.withValues(alpha: 0.08);
    }
  }
}

// ─────────────────────────────────────────────────────────
//  USER MODEL
// ─────────────────────────────────────────────────────────
class _UserData {
  final String uid;
  String name;
  String email;
  UserRole role;
  bool isSuspended;
  String get avatarLetter => name.isNotEmpty ? name[0].toUpperCase() : '?';

  _UserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isSuspended = false,
  });

  factory _UserData.fromFirestore(Map<String, dynamic> data) {
    UserRole role;
    switch (data['role'] ?? 'user') {
      case 'super_admin':
        role = UserRole.superAdmin;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.user;
    }
    return _UserData(
      uid: data['uid'] ?? '',
      name: data['namaLengkap'] ?? '',
      email: data['email'] ?? '',
      role: role,
      isSuspended: data['isSuspended'] ?? false,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MANAGE USERS PAGE
// ═══════════════════════════════════════════════════════════
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String _search = '';

  List<_UserData> _filterUsers(List<_UserData> users) {
    if (_search.isEmpty) return users;
    final q = _search.toLowerCase();
    return users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _C.primary,
        foregroundColor: _C.white,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manajemen Pengguna',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _C.white,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AuthService.usersStream(),
        builder: (context, snapshot) {
          // ── Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SkeletonLoader.list();
          }

          // ── Error ──
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.warning_2, size: 48, color: _C.error),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat data pengguna',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _C.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          final allUsers = (snapshot.data ?? [])
              .map((d) => _UserData.fromFirestore(d))
              .toList();
          final filtered = _filterUsers(allUsers);

          return Column(
            children: [
              // ── AppBar badge (user count) ──
              // ── Search bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: _C.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: _C.textHint,
                    ),
                    prefixIcon: Icon(
                      Iconsax.search_normal_1,
                      size: 18,
                      color: _C.textTertiary,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${allUsers.length} user',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _C.primary,
                          ),
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(minHeight: 24),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms),

              // ── Role filter chips ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    _roleBadge(
                      UserRole.superAdmin,
                      allUsers
                          .where((u) => u.role == UserRole.superAdmin)
                          .length,
                    ),
                    const SizedBox(width: 8),
                    _roleBadge(
                      UserRole.admin,
                      allUsers.where((u) => u.role == UserRole.admin).length,
                    ),
                    const SizedBox(width: 8),
                    _roleBadge(
                      UserRole.user,
                      allUsers.where((u) => u.role == UserRole.user).length,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _C.errorBg,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${allUsers.where((u) => u.isSuspended).length} suspended',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

              // ── User list ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.search_status,
                              size: 48,
                              color: _C.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada pengguna ditemukan',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _C.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPad + 24),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final u = filtered[i];
                          return _UserCard(
                            user: u,
                            index: i,
                            onChangeRole: () => _showRoleDialog(u),
                            onToggleSuspend: () => _toggleSuspend(u),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  ROLE BADGE
  // ─────────────────────────────────────────────────────
  Widget _roleBadge(UserRole role, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: role.bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${role.label} ($count)',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: role.color,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  CHANGE ROLE DIALOG
  // ─────────────────────────────────────────────────────
  void _showRoleDialog(_UserData user) {
    showDialog(
      context: context,
      builder: (ctx) {
        UserRole selected = user.role;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Ubah Role',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                  ),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: _C.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...UserRole.values.map(
                    (role) => GestureDetector(
                      onTap: () => setDialogState(() => selected = role),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected == role
                              ? role.bgColor
                              : _C.borderLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected == role
                                ? role.color
                                : _C.border.withValues(alpha: 0.5),
                            width: selected == role ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected == role
                                  ? Iconsax.tick_circle5
                                  : Iconsax.tick_circle,
                              size: 20,
                              color: selected == role
                                  ? role.color
                                  : _C.textHint,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              role.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: selected == role
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected == role
                                    ? role.color
                                    : _C.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.textSecondary,
                    side: BorderSide(color: _C.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: _C.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    // Convert enum to Firestore role string
                    String roleStr;
                    switch (selected) {
                      case UserRole.superAdmin:
                        roleStr = 'super_admin';
                        break;
                      case UserRole.admin:
                        roleStr = 'admin';
                        break;
                      default:
                        roleStr = 'user';
                    }

                    try {
                      await AuthService.updateUserRole(
                        uid: user.uid,
                        newRole: roleStr,
                      );
                      setState(() => user.role = selected);
                      Navigator.pop(ctx);
                      _snack('Role ${user.name} diubah ke ${selected.label}');
                    } catch (e) {
                      Navigator.pop(ctx);
                      _snack('Gagal mengubah role: $e');
                    }
                  },
                  child: Text(
                    'Simpan',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  TOGGLE SUSPEND
  // ─────────────────────────────────────────────────────
  void _toggleSuspend(_UserData user) async {
    final action = user.isSuspended ? 'aktifkan' : 'suspend';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: user.isSuspended ? _C.successBg : _C.errorBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            user.isSuspended ? Iconsax.shield_tick : Iconsax.shield_cross,
            color: user.isSuspended ? _C.success : _C.error,
            size: 26,
          ),
        ),
        title: Text(
          user.isSuspended ? 'Aktifkan Akun?' : 'Suspend Akun?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
        content: Text(
          user.isSuspended
              ? 'Aktifkan kembali akun "${user.name}"?'
              : 'Yakin ingin men-suspend akun "${user.name}"? User tidak dapat login.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.textSecondary,
              side: BorderSide(color: _C.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: user.isSuspended ? _C.success : _C.error,
              foregroundColor: _C.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              user.isSuspended ? 'Ya, Aktifkan' : 'Ya, Suspend',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final newSuspendState = !user.isSuspended;
      await AuthService.toggleSuspend(
        uid: user.uid,
        isSuspended: newSuspendState,
      );
      setState(() => user.isSuspended = newSuspendState);
      _snack(
        user.isSuspended
            ? 'Akun ${user.name} di-suspend'
            : 'Akun ${user.name} diaktifkan',
      );
    } catch (e) {
      _snack('Gagal: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: _C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  USER CARD
// ─────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final _UserData user;
  final int index;
  final VoidCallback onChangeRole;
  final VoidCallback onToggleSuspend;

  const _UserCard({
    required this.user,
    required this.index,
    required this.onChangeRole,
    required this.onToggleSuspend,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColors = [
      _C.primary,
      _C.teal,
      _C.info,
      _C.warning,
      const Color(0xFF7C3AED),
    ];
    final avatarColor = avatarColors[index % avatarColors.length];

    return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: user.isSuspended
                ? _C.errorBg.withValues(alpha: 0.4)
                : _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: user.isSuspended
                  ? _C.error.withValues(alpha: 0.2)
                  : _C.border.withValues(alpha: 0.5),
            ),
            boxShadow: user.isSuspended
                ? []
                : [
                    BoxShadow(
                      color: _C.primary.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: user.isSuspended
                            ? _C.textTertiary.withValues(alpha: 0.15)
                            : avatarColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.avatarLetter,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: user.isSuspended
                              ? _C.textTertiary
                              : avatarColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: user.isSuspended
                                        ? _C.textTertiary
                                        : _C.textPrimary,
                                    decoration: user.isSuspended
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isSuspended) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _C.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'SUSPENDED',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: _C.error,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _C.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: user.role.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: user.role.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.primary,
                          side: BorderSide(
                            color: _C.primary.withValues(alpha: 0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: Icon(Iconsax.user_edit, size: 15),
                        label: Text(
                          'Ubah Role',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: onChangeRole,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: user.isSuspended
                              ? _C.success
                              : _C.error,
                          side: BorderSide(
                            color: (user.isSuspended ? _C.success : _C.error)
                                .withValues(alpha: 0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: Icon(
                          user.isSuspended
                              ? Iconsax.shield_tick
                              : Iconsax.shield_cross,
                          size: 15,
                        ),
                        label: Text(
                          user.isSuspended ? 'Aktifkan' : 'Suspend',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: onToggleSuspend,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (200 + index * 60).ms, duration: 400.ms)
        .slideY(
          begin: 0.04,
          delay: (200 + index * 60).ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
