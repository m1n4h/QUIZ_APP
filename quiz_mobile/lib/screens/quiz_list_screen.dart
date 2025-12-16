
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/services/api_service.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  List<Quiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      // final quizzes = await _apiService.getStudentQuizzes();
      final quizzesData = await _apiService.getStudentQuizzes();
      // final quizzesList = quizzesData['availableQuizzes'] as List? ?? [];
      setState(() => _quizzes = _quizzes);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load quizzes: $e',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _apiService.logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 80,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No quizzes available',
                        style: AppTextStyle.h3
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return _QuizListItem(
                      quiz: quiz,
                      onTap: () {
                        Get.toNamed('/student-quiz/${quiz.id}');
                      },
                    );
                  },
                ),
    );
  }
}

class _QuizListItem extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;

  const _QuizListItem({
    required this.quiz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                style: AppTextStyle.h3.copyWith(
                  color: AppColors.primaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                quiz.description,
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.question_mark,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${quiz.questions.length} Questions',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${quiz.timeLimit} min',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Start Quiz',
                    style: AppTextStyle.buttonMedium.copyWith(
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}