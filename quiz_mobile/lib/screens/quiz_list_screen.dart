import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/screens/profile_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = Get.find<ApiService>();
  late TabController _tabController;
  List<Quiz> _quizzes = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  bool _resultsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuizzes();
    _tabController.addListener(() {
      if (_tabController.index == 1 && _results.isEmpty && !_resultsLoading) {
        _loadResults();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final quizzes = await _apiService.getStudentQuizzes();
      setState(() => _quizzes = quizzes);
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

  Future<void> _loadResults() async {
    setState(() => _resultsLoading = true);
    try {
      final results = await _apiService.getQuizResults();
      setState(() => _results = results);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load results: $e',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
    } finally {
      setState(() => _resultsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Get.to(() => const ProfileScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _apiService.logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available Quizzes'),
            Tab(text: 'My Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizzesTab(),
          _buildResultsTab(),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_quizzes.isEmpty) {
      return Center(
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
              style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
    );
  }

  Widget _buildResultsTab() {
    if (_resultsLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No quiz results yet',
              style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a quiz to see your results here',
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        
        // Parse the completion date and convert to Tanzania time
        final DateTime completedAtUtc = DateTime.parse(result['completedAt']);
        final DateTime completedAt = completedAtUtc.add(const Duration(hours: 3)); // Convert to EAT (UTC+3)
        final String formattedDate = DateFormat('MMM d, yyyy').format(completedAt);
        final String formattedTime = DateFormat('HH:mm').format(completedAt);
        
        final int score = result['score'] ?? 0;
        final int totalQuestions = result['totalQuestions'] ?? 0;
        final int correctAnswers = result['correctAnswers'] ?? 0;
        final double percentage = (result['percentage'] ?? 0.0).toDouble();
        
        // Get quiz title from nested quiz object or fallback
        String quizTitle = 'Quiz'; // Default fallback
        if (result['quiz'] != null && result['quiz']['title'] != null) {
          quizTitle = result['quiz']['title'];
        } else if (result['quizTitle'] != null) {
          quizTitle = result['quizTitle'];
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _getStatusColor(result['status']).withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          quizTitle,
                          style: AppTextStyle.h3.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(result['status']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(result['status']).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${percentage.toInt()}%',
                          style: AppTextStyle.bodyMedium.copyWith(
                            color: _getStatusColor(result['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResultStat(
                          'Points',
                          '$score pts',
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      Expanded(
                        child: _buildResultStat(
                          'Correct',
                          '$correctAnswers/$totalQuestions',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildResultStat(
                          'Grade',
                          _getGrade(percentage),
                          Icons.grade,
                          _getStatusColor(result['status']),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: AppTextStyle.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              formattedTime,
                              style: AppTextStyle.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'very_good':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyle.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
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