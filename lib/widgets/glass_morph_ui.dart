import 'dart:ui';
import 'package:flutter/material.dart';

// ============================================
// APPLE-STYLE GLASSMORPHISM DESIGN SYSTEM
// New Mom Friendly • Soft • Calming • Premium
// ============================================

class NeoColors {
  // New Mom Friendly Color Palette - Soft & Calming
  static const Color blush = Color(0xFFFAE5E0);       // Soft blush pink
  static const Color lavender = Color(0xFFE8E0F0);    // Gentle lavender
  static const Color sage = Color(0xFFE0EDE5);        // Soft sage green
  static const Color cream = Color(0xFFFFF8F0);       // Warm cream
  static const Color peach = Color(0xFFFFE5D4);       // Soft peach
  static const Color skyBlue = Color(0xFFE0F0F8);     // Baby sky blue
  
  // Accent Colors
  static const Color rosePink = Color(0xFFE8A0A0);    // Rose accent
  static const Color mintGreen = Color(0xFF88C9A8);   // Mint accent
  static const Color softPurple = Color(0xFFB8A0D0);  // Soft purple accent
  static const Color coralOrange = Color(0xFFF0A080); // Coral accent
  
  // Text Colors
  static const Color textDark = Color(0xFF3A3A3C);    // Dark text
  static const Color textMedium = Color(0xFF6E6E73);  // Medium text
  static const Color textLight = Color(0xFF8E8E93);   // Light text
  
  // Background
  static const Color background = Color(0xFFFAF8F5);  // Warm off-white
  static const Color cardWhite = Color(0xFFFFFFFF);   // Pure white
}

// ============================================
// GLASS MORPH CARD
// Apple-style frosted glass effect
// ============================================
class GlassMorphCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? tintColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassMorphCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.tintColor,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final color = tintColor ?? Colors.white;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 0,
              offset: const Offset(0, 0),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.6),
                  ],
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

// ============================================
// QUICK STAT GLASS CARD
// For dashboard stat display
// ============================================
class QuickStatGlassCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickStatGlassCard({
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
    return GlassMorphCard(
      tintColor: color.withValues(alpha: 0.3),
      onTap: onTap,
      width: 160,
      height: 140,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoColors.textMedium,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: NeoColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: NeoColors.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================
// FEATURE GLASS CARD
// For Explore section grid
// ============================================
class FeatureGlassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const FeatureGlassCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphCard(
      tintColor: color.withValues(alpha: 0.15),
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with soft glow
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: NeoColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: NeoColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// GRADIENT BACKGROUND
// Smooth gradient scaffold background
// ============================================
class NeoBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const NeoBackground({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFAF5), // Warm white top
              NeoColors.background,
              Color(0xFFF5F0F0), // Slight blush bottom
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
// ============================================
// SIMPLE SLIDING NAV BAR
// Clean and neat native-feeling sliding indicator
// ============================================
class SlidingGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> icons;
  final List<String> labels;

  const SlidingGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, 12 + bottomPadding),
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / icons.length;
          return Stack(
            children: [
              // Continuous Sliding Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                left: currentIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Center(
                  child: Container(
                    width: itemWidth * 0.85,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A32) : NeoColors.mintGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
              ),
              // Nav Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(icons.length, (index) {
                  final isSelected = currentIndex == index;
                  final selectedColor = isDark ? Colors.white : NeoColors.mintGreen;
                  final unselectedColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9E9E9E);

                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: itemWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            color: isSelected ? selectedColor : unselectedColor,
                            size: 26,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? selectedColor : unselectedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
