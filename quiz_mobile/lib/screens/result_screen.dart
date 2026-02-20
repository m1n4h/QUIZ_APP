import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/models/quiz_model.dart';

// Extension to add firstWhereOrNull method to Iterable
extension FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _answerSummaryKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAnswerSummary() {
    final context = _answerSummaryKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No results to display',
                style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.offNamed('/quiz-list'),
                child: const Text('Back to Quizzes'),
              ),
            ],
          ),
        ),
      );
    }

    final quiz = args['quiz'] as Quiz?;
    final score = args['score'] as num? ?? 0;
    final totalQuestions = args['totalQuestions'] as int? ?? 0;
    final correctAnswers = args['correctAnswers'] as int? ?? 0;
    final percentage = args['percentage'] as num? ?? 0;
    final timeTaken = args['timeTaken'] as int? ?? 0;
    final userAnswers = args['answers'] as Map<String, String?>? ?? {};

    // Convert to proper types
    final scoreInt = score.toInt();
    final percentageInt = percentage.toInt();

    // Format time taken
    final minutes = (timeTaken / 60).floor();
    final seconds = timeTaken % 60;
    final timeString = '${minutes}m ${seconds}s';

    // Determine performance level
    String performanceLevel;
    Color performanceColor;
    IconData performanceIcon;
    
    if (percentageInt >= 90) {
      performanceLevel = 'Excellent!';
      performanceColor = Colors.green;
      performanceIcon = Icons.star;
    } else if (percentageInt >= 70) {
      performanceLevel = 'Good Job!';
      performanceColor = Colors.blue;
      performanceIcon = Icons.thumb_up;
    } else if (percentageInt >= 50) {
      performanceLevel = 'Keep Trying!';
      performanceColor = Colors.orange;
      performanceIcon = Icons.trending_up;
    } else {
      performanceLevel = 'Need Practice';
      performanceColor = Colors.red;
      performanceIcon = Icons.school;
    }

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
            controller: _scrollController,
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
                      if (quiz != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          quiz.title,
                          style: AppTextStyle.h3.copyWith(
                            color: AppColors.secondaryColor.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                            Icon(
                              performanceIcon,
                              size: 48,
                              color: performanceColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              performanceLevel,
                              style: AppTextStyle.h2.copyWith(
                                color: performanceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('Score', '${scoreInt}/${totalQuestions * 2}', Icons.star),
                                _buildStatItem('Correct', '$correctAnswers/$totalQuestions', Icons.check_circle),
                                _buildStatItem('Time', timeString, Icons.timer),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: performanceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: performanceColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                '$percentageInt%',
                                style: AppTextStyle.h1.copyWith(
                                  color: performanceColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
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
                            onPressed: _scrollToAnswerSummary,
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
                            icon: const Icon(Icons.visibility),
                            label: Text(
                              'Review Answers',
                              style: AppTextStyle.buttonMedium,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Get.offNamed('/quiz-list'),
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
                              'Back to Quizzes',
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
                key: _answerSummaryKey,
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
                          .firstWhereOrNull((c) => c.isCorrect == true);
                      final isCorrect = selectedChoice?.isCorrect == true;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: AppColors.secondaryColor,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCorrect ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
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
                                      child: Icon(
                                        isCorrect ? Icons.check : Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Question ${index + 1}',
                                        style: AppTextStyle.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCorrect 
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isCorrect ? 'Correct' : 'Wrong',
                                        style: AppTextStyle.bodySmall.copyWith(
                                          color: isCorrect ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    question.questionText,
                                    style: AppTextStyle.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildAnswerRow(
                                  'Your Answer:',
                                  selectedChoice?.choiceText ?? 'Not answered',
                                  isCorrect ? Colors.green : Colors.red,
                                ),
                                const SizedBox(height: 8),
                                _buildAnswerRow(
                                  'Correct Answer:',
                                  correctChoice?.choiceText ?? 'No correct answer found',
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: quiz?.questions.length ?? 0,
                  ),
                ),
              // Add bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerRow(String label, String answer, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: AppTextStyle.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              answer,
              style: AppTextStyle.bodyMedium.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyle.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
