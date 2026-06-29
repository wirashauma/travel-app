import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
}

class BahasaSettingsPage extends StatefulWidget {
  const BahasaSettingsPage({super.key});

  @override
  State<BahasaSettingsPage> createState() => _BahasaSettingsPageState();
}

class _BahasaSettingsPageState extends State<BahasaSettingsPage> {
  String _selectedLang = 'id';

  final List<Map<String, String>> _languages = [
    {
      'code': 'id',
      'name': 'Bahasa Indonesia',
      'flag': '🇮🇩',
      'label': 'ID',
    },
    {
      'code': 'en',
      'name': 'English (US)',
      'flag': '🇺🇸',
      'label': 'EN',
    },
    {
      'code': 'min',
      'name': 'Baso Minang',
      'flag': '🇮🇩',
      'label': 'MIN',
    },
  ];

  Widget _buildLanguageTile({
    required String code,
    required String name,
    required String flag,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedLang == code;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedLang = code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _C.primary : _C.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: _C.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Iconsax.tick_circle5,
                color: _C.primary,
                size: 20,
              )
            else
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _C.textSecondary.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: (100 + index * 80).ms,
          duration: 400.ms,
        ).slideY(
          begin: 0.04,
          delay: (100 + index * 80).ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          'Pilih Bahasa',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.white,
        foregroundColor: _C.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _C.borderLight, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Bahasa Aplikasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 4),
            Text(
              'Pilih bahasa utama yang ingin Anda gunakan di dalam aplikasi Minang Travel.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: _C.textSecondary,
                height: 1.4,
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
            const SizedBox(height: 20),

            ...List.generate(_languages.length, (index) {
              final lang = _languages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLanguageTile(
                  code: lang['code']!,
                  name: lang['name']!,
                  flag: lang['flag']!,
                  label: lang['label']!,
                  index: index,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
