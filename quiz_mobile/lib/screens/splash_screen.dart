import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/screens/login_screen.dart';
import 'package:quiz_app/screens/teacher_dashboard_screen.dart';
import 'package:quiz_app/screens/quiz_list_screen.dart';
import 'package:quiz_app/screens/onboarding_screen.dart';
import 'package:quiz_app/screens/admin_dashboard_screen.dart';
import 'package:quiz_app/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService apiService = Get.find<ApiService>();

  @override
  void initState() {
    super.initState();
    print('SplashScreen initState');
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Wait 2.5 seconds for splash animation
    await Future.delayed(const Duration(milliseconds: 2500));

    try {
      // Check auth status
      final isLoggedIn = await apiService.checkAuthStatus();
      print('Auth Status: $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn) {
        // User is logged in - get their role
        final role = apiService.getUserRole();
        print('User Role: $role');

        // Navigate based on role
        if (role == 'teacher') {
          Get.off(() => const TeacherDashboardScreen());
        } else if (role == 'admin') {
          Get.off(() => const AdminDashboardScreen());
        } else {
          Get.off(() => const QuizListScreen());
        }
      } else {
        // User is NOT logged in
        // Check if first time user
        final isFirstTime = apiService.isFirstTime();
        print('First Time: $isFirstTime');

        if (isFirstTime) {
          Get.off(() => const OnboardingScreen());
        } else {
          // User has used app before but logged out
          Get.off(() => const LoginScreen());
        }
      }
    } catch (e) {
      print('Navigation error: $e');
      Get.off(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryLight,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // background pattern
            /*
            const Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: GridPattern(color: AppColors.secondaryColor),
              ),
            ),
            */

            // main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // animated logo container
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            size: 48,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // animated text
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'QUIZ',
                          style: AppTextStyle.h1.copyWith(
                            color: AppColors.secondaryColor,
                            fontSize: 36,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          'MASTER',
                          style: AppTextStyle.h2.copyWith(
                            color: AppColors.secondaryColor,
                            fontSize: 28,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // bottom tagline
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Text(
                  'Learn • Practice • Excel',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.secondaryColor,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPattern extends StatelessWidget {
  final Color color;
  const GridPattern({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: GridPainter(color: color));
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 20.0;

    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}