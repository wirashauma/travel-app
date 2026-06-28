import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────
//  AUTH COLOR PALETTE — Clean, Professional, Trust-worthy
//  Navy Blue + White + Slate Gray (NO purple)
// ─────────────────────────────────────────────────────────
class AuthColors {
  // Primary — Trust Blue / Deep Navy
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color primaryDark = Color(0xFF0A3A63);

  // Teal accent
  static const Color teal = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);

  // Background
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8FAFC);

  // Input fill
  static const Color inputFill = Color(0xFFF7F8FA);
  static const Color inputFillFocused = Color(0xFFF0F4FF);

  // Border
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF0F4C81);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textPlaceholder = Color(0xFFCBD5E1);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}

// ─────────────────────────────────────────────────────────
//  AUTH TEXT FIELD — Clean outline, light fill, radius 12
// ─────────────────────────────────────────────────────────
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AuthColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: GoogleFonts.inter(
            color: AuthColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: AuthColors.primary,
          cursorWidth: 1.5,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              color: AuthColors.textPlaceholder,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                prefixIcon,
                color: AuthColors.textTertiary,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AuthColors.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AuthColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AuthColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AuthColors.borderFocused,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AuthColors.error.withValues(alpha: 0.5),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AuthColors.error,
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 11.5,
              color: AuthColors.error,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AUTH PRIMARY BUTTON — Solid Navy, full-width
// ─────────────────────────────────────────────────────────
class AuthPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _pressed
                ? AuthColors.primaryDark
                : AuthColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AuthColors.primary.withValues(alpha: 0.2),
                blurRadius: _pressed ? 8 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AUTH LINK TEXT — "Sudah punya akun? Masuk" etc.
// ─────────────────────────────────────────────────────────
class AuthLinkText extends StatelessWidget {
  final String prefix;
  final String actionText;
  final VoidCallback onTap;

  const AuthLinkText({
    super.key,
    required this.prefix,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: GoogleFonts.inter(
            color: AuthColors.textTertiary,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: GoogleFonts.plusJakartaSans(
              color: AuthColors.primary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AUTH HEADER — Title + subtitle (clean left-aligned)
// ─────────────────────────────────────────────────────────
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogo;
  final bool centerAlign;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
    this.centerAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centerAlign ? TextAlign.center : TextAlign.left;

    return Column(
      crossAxisAlignment: align,
      children: [
        if (showLogo) ...[
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AuthColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 30,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 32),
        ],

        // Title
        Text(
          title,
          textAlign: textAlign,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AuthColors.textPrimary,
            height: 1.15,
          ),
        )
            .animate()
            .fadeIn(delay: showLogo ? 150.ms : 0.ms, duration: 450.ms)
            .slideY(
              begin: 0.12,
              delay: showLogo ? 150.ms : 0.ms,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          subtitle,
          textAlign: textAlign,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: AuthColors.textTertiary,
            height: 1.55,
          ),
        )
            .animate()
            .fadeIn(delay: showLogo ? 300.ms : 120.ms, duration: 450.ms)
            .slideY(
              begin: 0.12,
              delay: showLogo ? 300.ms : 120.ms,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AUTH SCAFFOLD — Clean white background
// ─────────────────────────────────────────────────────────
class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: child,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SOCIAL DIVIDER — "atau masuk dengan"
// ─────────────────────────────────────────────────────────
class AuthDivider extends StatelessWidget {
  final String text;
  const AuthDivider({super.key, this.text = 'atau'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AuthColors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AuthColors.border, height: 1)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  GOOGLE LOGIN BUTTON — Outline style, single full-width
// ─────────────────────────────────────────────────────────
class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onTap;

  const GoogleLoginButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AuthColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuthColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple "G" icon using text for clean look
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AuthColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Masuk dengan Google',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AuthColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
