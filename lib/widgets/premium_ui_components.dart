import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =========================================================
/// NEO BABY TRACKER - PREMIUM UI SYSTEM (2026 Trends)
/// Aesthetic: Calm Minimalism
/// Philosophy: Reduce cognitive load, max legibility, soft UI
/// =========================================================

class PremiumColors {
  final BuildContext context;
  PremiumColors(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Backgrounds (60%)
  Color get background => isDark ? const Color(0xFF121212) : const Color(0xFFFDFDFD); // Deep Charcoal / Soft Pearl
  Color get surface => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF); // Elevated Dark / Pure White for cards
  Color get surfaceMuted => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF4F5F7); // Off-black / Off-white for tiles

  // Primary/Secondary (30%) - Trust, calm, health
  Color get sageGreen => isDark ? const Color(0xFF9CBDB5) : const Color(0xFF84A59D);
  Color get sereneBlue => isDark ? const Color(0xFFB8DEFF) : const Color(0xFFA2D2FF);
  Color get gentlePurple => isDark ? const Color(0xFFD6C1E3) : const Color(0xFFCDB4DB);

  // Accents (10%) - CTA, highlights, active states
  Color get warmPeach => isDark ? const Color(0xFFF6A3A1) : const Color(0xFFF28482);
  Color get softAmber => isDark ? const Color(0xFFFFC633) : const Color(0xFFFFB703);

  // Typography
  Color get textPrimary => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF2B2D42);
  Color get textSecondary => isDark ? Colors.white.withOpacity(0.60) : const Color(0xFF8D99AE);
  Color get textMuted => isDark ? Colors.white.withOpacity(0.38) : const Color(0xFFC0C4CC);
}

class PremiumTypography {
  final BuildContext context;
  PremiumTypography(this.context);

  TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: PremiumColors(context).textPrimary,
    letterSpacing: -0.5,
  );

  TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: PremiumColors(context).textPrimary,
    letterSpacing: -0.3,
  );

  TextStyle get title => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: PremiumColors(context).textPrimary,
  );

  TextStyle get bodyBold => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: PremiumColors(context).textPrimary,
  );

  TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: PremiumColors(context).textSecondary,
  );

  TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: PremiumColors(context).textSecondary,
  );
}

/// =========================================================
/// PREMIUM CARD
/// Floating, glass-like paper effect with subtle shadows
/// =========================================================
/// =========================================================
/// 2. THE LIQUID GLASS CARD
/// =========================================================
class PremiumCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;

  const PremiumCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// =========================================================
/// PREMIUM BUBBLE ICON
/// Reusable illustrative icon with soft circular background
/// =========================================================
class PremiumBubbleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double padding;

  const PremiumBubbleIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 28,
    this.padding = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), // Soft bubble background
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }
}

/// =========================================================
/// PREMIUM ACTION BUTTON
/// Pill-shaped, engaging CTA button
/// =========================================================
class PremiumActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  const PremiumActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100), // Fully rounded pill shape
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =========================================================
/// DATA TILE
/// Clean, muted surface for tabular data or lists
/// =========================================================
class DataTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const DataTile({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.5), 
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.02)]
                      : [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.1)],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// =========================================================
/// 1. THE MESH BACKGROUND (Provides colors for the glass to blur without breaking syntax)
/// =========================================================
class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        gradient: RadialGradient(
          center: const Alignment(-0.5, -0.6),
          radius: 1.5,
          colors: isDark
              ? [const Color(0xFF1A3A3A), const Color(0xFF121212), const Color(0xFF3A1A2A)] // Deep Sage & Salmon glow
              : [const Color(0xFFE0F2F1), const Color(0xFFF5F7FA), const Color(0xFFFCE4EC)], // Light Sage & Peach glow
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// =========================================================
/// PREMIUM SCAFFOLD
/// Easy wrapper to apply the GlassScaffoldBackground
/// =========================================================
class PremiumScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;

  const PremiumScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: body != null ? PremiumBackground(child: body!) : null,
    );
  }
}
