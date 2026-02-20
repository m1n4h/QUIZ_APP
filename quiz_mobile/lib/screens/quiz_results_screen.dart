import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/services/api_service.dart';

class QuizResultsScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizResultsScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = Get.find<ApiService>();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _attempts = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  bool _analyticsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    
    _tabController.addListener(() {
      if (_tabController.index == 1 && _analytics == null && !_analyticsLoading) {
        _loadAnalytics();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final attempts = await _apiService.getQuizAttempts(widget.quizId);
      setState(() => _attempts = attempts);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load quiz results: $e',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);
    try {
      final analytics = await _apiService.getQuizAnalytics(widget.quizId);
      setState(() => _analytics = analytics);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load analytics: $e',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
    } finally {
      setState(() => _analyticsLoading = false);
    }
  }

  void _viewStudentDetails(Map<String, dynamic> attempt) {
    final userId = attempt['user']['id'];
    Get.to(() => StudentDetailScreen(
      quizId: widget.quizId,
      userId: userId,
      studentName: attempt['studentName'] ?? 'Unknown Student',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quiz Results'),
            Text(
              widget.quizTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Student Results'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentResultsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildStudentResultsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No student attempts yet',
              style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Students will appear here after taking the quiz',
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attempts.length,
        itemBuilder: (context, index) {
          final attempt = _attempts[index];
          return _buildStudentResultCard(attempt);
        },
      ),
    );
  }

  Widget _buildStudentResultCard(Map<String, dynamic> attempt) {
    final DateTime completedAtUtc = DateTime.parse(attempt['completedAt']);
    final DateTime completedAt = completedAtUtc.add(const Duration(hours: 3)); // Convert to EAT
    final String formattedDate = DateFormat('MMM d, yyyy').format(completedAt);
    final String formattedTime = DateFormat('HH:mm').format(completedAt);
    
    final int score = attempt['score']?.toInt() ?? 0;
    final int totalQuestions = attempt['totalQuestions'] ?? 0;
    final int correctAnswers = attempt['correctAnswers'] ?? 0;
    final double percentage = (attempt['percentage'] ?? 0.0).toDouble();
    final int timeTaken = attempt['timeTaken'] ?? 0;
    
    final String studentName = attempt['studentName'] ?? 'Unknown Student';
    final String studentEmail = attempt['studentEmail'] ?? '';
    
    // Format time taken
    final minutes = (timeTaken / 60).floor();
    final seconds = timeTaken % 60;
    final timeString = '${minutes}m ${seconds}s';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewStudentDetails(attempt),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _getStatusColor(attempt['status']).withOpacity(0.05),
              ],
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
                      backgroundColor: AppColors.primaryColor,
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: AppTextStyle.h3.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (studentEmail.isNotEmpty)
                            Text(
                              studentEmail,
                              style: AppTextStyle.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(attempt['status']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(attempt['status']).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${percentage.toInt()}%',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: _getStatusColor(attempt['status']),
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
                        'Score',
                        '$score/${totalQuestions * 2}',
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
                        'Time',
                        timeString,
                        Icons.timer,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildResultStat(
                        'Grade',
                        _getGrade(percentage),
                        Icons.grade,
                        _getStatusColor(attempt['status']),
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
                      Row(
                        children: [
                          Icon(Icons.visibility, size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'View Details',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analyticsLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_analytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No analytics data available',
              style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewStats(),
          const SizedBox(height: 24),
          _buildQuestionAnalytics(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    final analytics = _analytics!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Overview',
              style: AppTextStyle.h2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAnalyticCard(
                  'Total Attempts',
                  '${analytics['totalAttempts'] ?? 0}',
                  Icons.assignment_turned_in,
                  Colors.blue,
                ),
                _buildAnalyticCard(
                  'Unique Students',
                  '${analytics['uniqueStudents'] ?? 0}',
                  Icons.people,
                  Colors.green,
                ),
                _buildAnalyticCard(
                  'Average Score',
                  '${(analytics['averageScore'] ?? 0).toStringAsFixed(1)}',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildAnalyticCard(
                  'Pass Rate',
                  '${(analytics['passRate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.purple,
                ),
                _buildAnalyticCard(
                  'Highest Score',
                  '${analytics['highestScore'] ?? 0}',
                  Icons.star,
                  Colors.amber,
                ),
                _buildAnalyticCard(
                  'Avg. Time',
                  '${((analytics['averageCompletionTime'] ?? 0) / 60).toStringAsFixed(1)}m',
                  Icons.timer,
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionAnalytics() {
    final questionAnalytics = _analytics!['questionAnalytics'] as List? ?? [];
    
    if (questionAnalytics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question Performance',
              style: AppTextStyle.h2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questionAnalytics.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final question = questionAnalytics[index];
                final accuracy = (question['accuracyPercentage'] ?? 0.0).toDouble();
                final difficulty = question['difficultyLevel'] ?? 'Unknown';
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Question ${index + 1}',
                    style: AppTextStyle.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['questionText'] ?? '',
                        style: AppTextStyle.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${question['correctAttempts']}/${question['totalAttempts']} correct',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(difficulty).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          difficulty,
                          style: AppTextStyle.bodySmall.copyWith(
                            color: _getDifficultyColor(difficulty),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${accuracy.toStringAsFixed(1)}%',
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getDifficultyColor(difficulty),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyle.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
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
}

class StudentDetailScreen extends StatefulWidget {
  final String quizId;
  final String userId;
  final String studentName;

  const StudentDetailScreen({
    super.key,
    required this.quizId,
    required this.userId,
    required this.studentName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  Map<String, dynamic>? _performance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentPerformance();
  }

  Future<void> _loadStudentPerformance() async {
    setState(() => _isLoading = true);
    try {
      final performance = await _apiService.getStudentPerformance(
        widget.quizId,
        widget.userId,
      );
      setState(() => _performance = performance);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load student performance: $e',
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
        title: Text('${widget.studentName} - Details'),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : _performance == null
              ? Center(
                  child: Text(
                    'No performance data available',
                    style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
                  ),
                )
              : _buildPerformanceDetails(),
    );
  }

  Widget _buildPerformanceDetails() {
    final attempt = _performance!['attempt'] as Map<String, dynamic>;
    final answers = _performance!['answers'] as List;
    
    final DateTime completedAtUtc = DateTime.parse(attempt['completedAt']);
    final DateTime completedAt = completedAtUtc.add(const Duration(hours: 3));
    final String formattedDateTime = DateFormat('MMM d, yyyy at HH:mm').format(completedAt);
    
    final int score = attempt['score']?.toInt() ?? 0;
    final int totalQuestions = attempt['totalQuestions'] ?? 0;
    final int correctAnswers = attempt['correctAnswers'] ?? 0;
    final double percentage = (attempt['percentage'] ?? 0.0).toDouble();
    final int timeTaken = attempt['timeTaken'] ?? 0;
    
    final minutes = (timeTaken / 60).floor();
    final seconds = timeTaken % 60;
    final timeString = '${minutes}m ${seconds}s';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Summary Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Summary',
                    style: AppTextStyle.h2.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem('Score', '$score/${totalQuestions * 2}', Icons.star, Colors.amber),
                      ),
                      Expanded(
                        child: _buildSummaryItem('Correct', '$correctAnswers/$totalQuestions', Icons.check_circle, Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem('Percentage', '${percentage.toInt()}%', Icons.percent, Colors.blue),
                      ),
                      Expanded(
                        child: _buildSummaryItem('Time Taken', timeString, Icons.timer, Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Completed: $formattedDateTime',
                          style: AppTextStyle.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Detailed Answers
          Text(
            'Detailed Answers',
            style: AppTextStyle.h2.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: answers.length,
            itemBuilder: (context, index) {
              final answer = answers[index];
              final isCorrect = answer['isCorrect'] ?? false;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                              backgroundColor: isCorrect ? Colors.green : Colors.red,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCorrect 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${answer['pointsEarned'] ?? 0} pts',
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
                            answer['questionText'] ?? '',
                            style: AppTextStyle.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAnswerRow(
                          'Student Answer:',
                          answer['selectedChoiceText'] ?? 'Not answered',
                          isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildAnswerRow(
                          'Correct Answer:',
                          answer['correctChoiceText'] ?? 'No correct answer found',
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
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
}