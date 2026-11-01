import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.travel_explore_rounded,
      'tag': 'DISCOVER',
      'title': 'Discover rooms near your preferred location',
      'desc': 'Find verified, private, budget and premium rooms in Delhi, Lucknow, Noida, and across top cities without any middleman.',
    },
    {
      'icon': Icons.calendar_month_rounded,
      'tag': 'INSTANT BOOK',
      'title': 'Book rooms for your selected dates',
      'desc': 'Atomic slot locking guarantees your dates are locked in real-time. Transparent pricing, zero broker calling hassle.',
    },
    {
      'icon': Icons.airplane_ticket_rounded,
      'tag': 'PASS & REMINDER',
      'title': 'Manage bookings & receive live updates',
      'desc': 'Receive instant WhatsApp passes with Digital Door Access PINs, Google Maps navigation, and 24-hr Stay Extension priority.',
    },
  ];

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.home, color: navy, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('My Roomy', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Skip', style: TextStyle(color: muted, fontSize: 14)),
                  ),
                ],
              ),
            ),

            // Page Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final s = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: lime.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: lime.withValues(alpha: 0.12),
                                blurRadius: 36,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(s['icon'] as IconData, size: 56, color: lime),
                        ),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: lime.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s['tag'] as String,
                            style: const TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Indicators & Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 7,
                        width: _currentIndex == i ? 24 : 7,
                        decoration: BoxDecoration(
                          color: _currentIndex == i ? lime : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: navy,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_currentIndex == _slides.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentIndex == _slides.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
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
}
