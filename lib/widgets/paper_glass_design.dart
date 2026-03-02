import 'dart:ui';
import 'package:flutter/material.dart';

// ============================================
// PAPER-GLASS DESIGN SYSTEM
// Hybrid 3D Paper-Craft & Glassmorphism
// ============================================

// Color Palette
class PaperGlassColors {
  static const Color background = Color(0xFFF9F8F4);  // Warm textured off-white
  static const Color sage = Color(0xFF7D9C8B);        // Sage green
  static const Color salmon = Color(0xFFE58C72);      // Salmon
  static const Color tan = Color(0xFFE8DCC4);         // Tan/Cream
  static const Color paperWhite = Color(0xFFFFFDF8);  // Paper white
  static const Color shadow = Color(0xFF5D4E37);      // Brown shadow
}

// ============================================
// PAPER BACKGROUND
// The textured warm scaffold background
// ============================================
class PaperBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const PaperBackground({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaperGlassColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          // Subtle paper texture gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCFBF7),
              PaperGlassColors.background,
              Color(0xFFF5F3ED),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

// ============================================
// PAPER CARD
// Looks like thick folded construction paper
// ============================================
class PaperCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const PaperCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? PaperGlassColors.paperWhite;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(4), // Sharp corners for paper feel
          boxShadow: [
            // Primary drop shadow
            BoxShadow(
              color: PaperGlassColors.shadow.withOpacity(0.2),
              offset: const Offset(4, 4),
              blurRadius: 2,
            ),
            // Sharp paper edge shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 1),
              blurRadius: 0,
            ),
            // Soft ambient shadow
            BoxShadow(
              color: Colors.black12,
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            // The "crease/fold" gradient overlay
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25), // Highlight (Top of fold)
                Colors.transparent,
                Colors.black.withOpacity(0.05), // Shadow (Bottom of fold)
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================
// QUICK STAT PAPER CARD
// Pre-styled card for dashboard stats
// ============================================
class QuickStatPaperCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickStatPaperCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      color: color.withOpacity(0.15),
      onTap: onTap,
      width: 150,
      height: 130,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with paper cutout style
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(1, 1),
                  blurRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Subtitle
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ============================================
// FEATURE PAPER CARD
// For the Explore section grid
// ============================================
class FeaturePaperCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const FeaturePaperCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      color: color.withOpacity(0.12),
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with paper effect
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(2, 2),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// GLASS OVERLAY
// Frosted glass pane that floats above cards
// ============================================
class GlassOverlay extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;

  const GlassOverlay({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================
// GLASS BOTTOM NAV BAR
// Frosted glass navigation bar
// ============================================
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              items: items,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: PaperGlassColors.sage,
              unselectedItemColor: Colors.grey[600],
              type: BottomNavigationBarType.fixed,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// PAPER APP BAR
// Styled app bar with paper aesthetic
// ============================================
class PaperAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool centerTitle;

  const PaperAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(
        title!,
        style: const TextStyle(
          color: Color(0xFF2D3436),
          fontWeight: FontWeight.w600,
        ),
      ) : null),
      centerTitle: centerTitle,
      backgroundColor: PaperGlassColors.background.withOpacity(0.95),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF2D3436)),
      actions: actions,
    );
  }
}
