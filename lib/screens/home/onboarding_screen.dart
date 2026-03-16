import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/local_storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const pages = [
    {
      'emoji': '👶',
      'title': 'Track Everything',
      'subtitle': 'Log feeds, sleep, diapers, and milestones\nall in one beautiful app.',
      'color': 0xFFF28482,
    },
    {
      'emoji': '📊',
      'title': 'Smart Analytics',
      'subtitle': 'Get insights into your baby\'s patterns\nwith beautiful charts and reports.',
      'color': 0xFFA2D2FF,
    },
    {
      'emoji': '🤖',
      'title': 'AI Assistant',
      'subtitle': 'Ask our AI chatbot for parenting\ntips and guidance anytime.',
      'color': 0xFFCDB4DB,
    },
    {
      'emoji': '💚',
      'title': 'You\'re Ready!',
      'subtitle': 'Let\'s start this beautiful journey\ntogether. You\'ve got this!',
      'color': 0xFF84A59D,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() async {
    final ls = context.read<LocalStorageService>();
    await ls.saveString('onboarding_done', 'true');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip', style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) => _buildPage(pages[i]),
              ),
            ),

            // Dots and Next
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Color(pages[_currentPage]['color'] as int)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started
                  GestureDetector(
                    onTap: () {
                      if (_currentPage == pages.length - 1) {
                        _finish();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: _currentPage == pages.length - 1 ? 28 : 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Color(pages[_currentPage]['color'] as int),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Color(pages[_currentPage]['color'] as int).withValues(alpha: 0.4),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    final color = Color(page['color'] as int);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glow circle
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 40)],
            ),
            child: Center(
              child: Text(page['emoji'] as String, style: const TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 40),
          Text(page['title'] as String, style: GoogleFonts.plusJakartaSans(
            fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
          )),
          const SizedBox(height: 16),
          Text(
            page['subtitle'] as String,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.white60, height: 1.5),
          ),
        ],
      ),
    );
  }
}
