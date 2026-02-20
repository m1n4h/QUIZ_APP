import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';

import 'package:quiz_app/screens/login_screen.dart';
import 'package:quiz_app/screens/question_screen.dart';



class StartScreen extends StatelessWidget {
  final String quizId;
  
  const StartScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryDark,
                  AppColors.accentColor.withOpacity(0.8),
                ],
              ),
            ),
          ),
          
          // Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: _buildPattern(),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Logout button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.offAll(() => const LoginScreen());
                      },
                      icon: const Icon(Icons.logout, color: AppColors.primaryColor),
                      label: Text(
                        'Logout',
                        style: AppTextStyle.buttonMedium.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo/Icon
                          Hero(
                            tag: 'quiz_logo',
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.secondaryColor.withOpacity(0.2),
                                    AppColors.secondaryColor.withOpacity(0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: AppColors.secondaryColor.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(40),
                                child: Icon(
                                  Icons.quiz_outlined,
                                  size: 80,
                                  color: AppColors.secondaryColor,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Title
                          Text(
                            "Quiz Master",
                            style: AppTextStyle.h1.copyWith(
                              color: AppColors.secondaryColor,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Subtitle
                          Text(
                            "Test your knowledge and improve your skills!",
                            style: AppTextStyle.bodyLarge.copyWith(
                              color: AppColors.secondaryColor.withOpacity(0.9),
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Start Quiz Button
                          ElevatedButton(
                            onPressed: () {
                              Get.toNamed('/student-quiz/$quizId');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryColor,
                              foregroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Start Quiz',
                                  style: AppTextStyle.buttonLarge.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 24,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // View Results Button
                          OutlinedButton(
                            onPressed: () {
                              // Navigate to results history
                              Get.toNamed('/results-history');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryColor,
                              side: const BorderSide(
                                color: AppColors.secondaryColor,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'View Previous Results',
                              style: AppTextStyle.buttonMedium.copyWith(
                                color: AppColors.secondaryColor,
                              ),
                            ),
                          ),
                        ],
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
  }

  Widget _buildPattern() {
    return CustomPaint(
      painter: _PatternPainter(),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw circles
    for (int i = 0; i < 10; i++) {
      final radius = 20.0 + i * 40.0;
      final center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw diagonal lines
    for (int i = -10; i < 10; i++) {
      final start = Offset(0, size.height / 2 + i * 40);
      final end = Offset(size.width, size.height / 2 + i * 40);
      canvas.drawLine(start, end, paint);
      
      final start2 = Offset(size.width / 2 + i * 40, 0);
      final end2 = Offset(size.width / 2 + i * 40, size.height);
      canvas.drawLine(start2, end2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}