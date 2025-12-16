import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/models/quiz_model.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No results to display',
            style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final quiz = args['quiz'] as Quiz?;
    final score = args['score'] as int? ?? 0;
    final totalQuestions = args['totalQuestions'] as int? ?? 0;
    final userAnswers = args['answers'] as Map<String, String?>? ?? {};

    // Calculate correct answers
    int correctAnswers = 0;
    if (quiz != null) {
      for (var question in quiz.questions) {
        final selectedChoiceId = userAnswers[question.id];
        if (selectedChoiceId != null) {
          final selectedChoice = question.choices
              .firstWhereOrNull((c) => c.id == selectedChoiceId);
          if (selectedChoice?.isCorrect ?? false) {
            correctAnswers++;
          }
        }
      }
    }

    final percentage = totalQuestions > 0
        ? ((correctAnswers / totalQuestions) * 100).toInt()
        : 0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Quiz Complete!',
                        style: AppTextStyle.h1.copyWith(
                          color: AppColors.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$correctAnswers',
                              style: AppTextStyle.h1.copyWith(
                                color: AppColors.primaryColor,
                                fontSize: 64,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'out of $totalQuestions correct',
                              style: AppTextStyle.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: percentage >= 70
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Score: $percentage%',
                                style: AppTextStyle.h3.copyWith(
                                  color: percentage >= 70
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryColor,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              'Review',
                              style: AppTextStyle.buttonMedium,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Get.offNamed('/student-dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: AppColors.secondaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.home),
                            label: Text(
                              'Home',
                              style: AppTextStyle.buttonMedium.copyWith(
                                color: AppColors.secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Answer Summary',
                    style: AppTextStyle.h2.copyWith(
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ),
              if (quiz != null)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final question = quiz.questions[index];
                      final selectedChoiceId = userAnswers[question.id];
                      final selectedChoice = question.choices
                          .firstWhereOrNull((c) => c.id == selectedChoiceId);
                      final correctChoice = question.choices
                          .firstWhereOrNull((c) => c.isCorrect);
                      final isCorrect = selectedChoice?.isCorrect ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: isCorrect
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                    child: Text(
                                      '${index + 1}',
                                      style: AppTextStyle.bodyMedium.copyWith(
                                        color: AppColors.secondaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      question.questionText,
                                      style: AppTextStyle.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildAnswerRow(
                                'Your Answer:',
                                selectedChoice?.choiceText ?? 'Not answered',
                                isCorrect ? Colors.green : Colors.red,
                              ),
                              if (!isCorrect) ...[
                                const SizedBox(height: 8),
                                _buildAnswerRow(
                                  'Correct Answer:',
                                  correctChoice?.choiceText ?? 'N/A',
                                  Colors.green,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: quiz?.questions.length ?? 0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerRow(String label, String answer, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            answer,
            style: AppTextStyle.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}