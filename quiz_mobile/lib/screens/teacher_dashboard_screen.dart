import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/screens/quiz_results_screen.dart';
import 'package:quiz_app/screens/profile_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = Get.find<ApiService>();
  late TabController _tabController;
  List<Quiz> _quizzes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final quizzes = await _apiService.getTeacherQuizzes();
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

  void _openCreateQuizDialog() {
    Get.dialog(
      CreateQuizDialog(onQuizCreated: _loadQuizzes),
    );
  }

  void _editQuiz(Quiz quiz) {
    Get.to(
      () => EditQuizScreen(quiz: quiz, onSaved: _loadQuizzes),
    );
  }

  void _viewQuizResults(Quiz quiz) {
    Get.to(() => QuizResultsScreen(
      quizId: quiz.id,
      quizTitle: quiz.title,
    ));
  }

  Future<void> _deleteQuiz(String quizId) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteQuiz(quizId);
                Get.back();
                _loadQuizzes();
                Get.snackbar(
                  'Success',
                  'Quiz deleted successfully',
                  backgroundColor: AppColors.successColor,
                  colorText: AppColors.secondaryColor,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete quiz: $e',
                  backgroundColor: AppColors.errorColor,
                  colorText: AppColors.secondaryColor,
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
            Tab(text: 'My Quizzes'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Quizzes Tab
          _buildQuizzesTab(),
          // Analytics Tab
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateQuizDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
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
              'No quizzes yet',
              style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openCreateQuizDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
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
        return QuizCard(
          quiz: quiz,
          onEdit: () => _editQuiz(quiz),
          onDelete: () => _deleteQuiz(quiz.id),
          onViewResults: () => _viewQuizResults(quiz),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_quizzes.isEmpty) {
      return Center(
        child: Text(
          'No quiz data available',
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: AppTextStyle.h3.copyWith(color: AppColors.primaryColor),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Attempts',
                      '${quiz.attemptsCount}',
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Avg Score',
                      '${quiz.averageScore.toStringAsFixed(1)}%',
                      Icons.analytics,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Questions',
                      '${quiz.questions.length}',
                      Icons.help_outline,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyle.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewResults;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.onEdit,
    required this.onDelete,
    required this.onViewResults,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 4),
                      Text(
                        quiz.description,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    quiz.isPublished ? 'Published' : 'Draft',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: quiz.isPublished
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
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
                ),
                Expanded(
                  child: Row(
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await Get.find<ApiService>().updateQuiz(
                        quizId: quiz.id,
                        title: quiz.title,
                        description: quiz.description,
                        timeLimit: quiz.timeLimit,
                        isPublished: !quiz.isPublished,
                      );
                      onEdit(); // Refresh
                    } catch (e) {
                      Get.snackbar('Error', 'Failed to update status: $e');
                    }
                  },
                  icon: Icon(quiz.isPublished ? Icons.visibility_off : Icons.visibility),
                  label: Text(quiz.isPublished ? 'Unpublish' : 'Publish'),
                  style: TextButton.styleFrom(
                    foregroundColor: quiz.isPublished ? Colors.orange : Colors.green,
                  ),
                ),
                TextButton.icon(
                  onPressed: onViewResults,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Results'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Get.to(
                    () => ManageQuestionsScreen(quiz: quiz),
                  ),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Questions'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateQuizDialog extends StatefulWidget {
  final VoidCallback onQuizCreated;

  const CreateQuizDialog({super.key, required this.onQuizCreated});

  @override
  State<CreateQuizDialog> createState() => _CreateQuizDialogState();
}

class _CreateQuizDialogState extends State<CreateQuizDialog> {
  final ApiService _apiService = Get.find<ApiService>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '30');
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _apiService.getSubjects();
      setState(() {
        _subjects = subjects;
        if (subjects.isNotEmpty) {
          _selectedSubjectId = subjects.first['id'];
        }
      });
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  Future<void> _createQuiz() async {
    if (_titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter quiz title',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.createQuiz(
        title: _titleController.text,
        description: _descriptionController.text,
        timeLimit: int.parse(_timeLimitController.text),
        subjectId: _selectedSubjectId,
      );

      Get.back();
      widget.onQuizCreated();
      Get.snackbar(
        'Success',
        'Quiz created successfully',
        backgroundColor: AppColors.successColor,
        colorText: AppColors.secondaryColor,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create quiz: $e',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Quiz'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Quiz Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintMaxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _timeLimitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Time Limit (minutes)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _subjects.isEmpty
              ? const CircularProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: _subjects.map((s) {
                    return DropdownMenuItem<String>(
                      value: s['id'],
                      child: Text(s['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubjectId = value);
                  },
                ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.secondaryColor,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }
}

class EditQuizScreen extends StatefulWidget {
  final Quiz quiz;
  final VoidCallback onSaved;

  const EditQuizScreen({
    super.key,
    required this.quiz,
    required this.onSaved,
  });

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeLimitController;
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);
    _descriptionController =
        TextEditingController(text: widget.quiz.description);
    _timeLimitController =
        TextEditingController(text: '${widget.quiz.timeLimit}');
    _selectedSubjectId = widget.quiz.subjectId;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _apiService.getSubjects();
      setState(() {
        _subjects = subjects;
      });
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  Future<void> _saveQuiz() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateQuiz(
        quizId: widget.quiz.id,
        title: _titleController.text,
        description: _descriptionController.text,
        timeLimit: int.parse(_timeLimitController.text),
        subjectId: _selectedSubjectId,
      );

      Get.back();
      widget.onSaved();
      Get.snackbar(
        'Success',
        'Quiz updated successfully',
        backgroundColor: AppColors.successColor,
        colorText: AppColors.secondaryColor,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update quiz: $e',
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
        title: const Text('Edit Quiz'),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeLimitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Time Limit (minutes)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _subjects.isEmpty
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _subjects.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'],
                        child: Text(s['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSubjectId = value);
                    },
                  ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Changes',
                        style: AppTextStyle.buttonMedium.copyWith(
                          color: AppColors.secondaryColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(
                  () => ManageQuestionsScreen(quiz: widget.quiz),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Manage Questions',
                  style: AppTextStyle.buttonMedium.copyWith(
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }
}

class ManageQuestionsScreen extends StatefulWidget {
  final Quiz quiz;

  const ManageQuestionsScreen({super.key, required this.quiz});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  late List<Question> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.quiz.questions);
  }

  void _addQuestion() {
    Get.dialog(
      CreateQuestionDialog(
        onQuestionCreated: (question) {
          setState(() {
            _questions.add(question);
          });
        },
        quizId: widget.quiz.id,
      ),
    );
  }

  void _editQuestion(int index) {
    Get.dialog(
      CreateQuestionDialog(
        question: _questions[index],
        onQuestionCreated: (updatedQuestion) {
          setState(() {
            _questions[index] = updatedQuestion;
          });
        },
        quizId: widget.quiz.id,
      ),
    );
  }

  void _deleteQuestion(int index) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteQuestion(_questions[index].id);
                setState(() {
                  _questions.removeAt(index);
                });
                Get.back();
                Get.snackbar('Success', 'Question deleted');
              } catch (e) {
                Get.snackbar('Error', 'Failed to delete: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Questions'),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: _questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.question_mark_outlined,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: AppTextStyle.h3
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      question.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${question.choices.length} choices'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editQuestion(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteQuestion(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CreateQuestionDialog extends StatefulWidget {
  final Function(Question) onQuestionCreated;
  final String quizId;
  final Question? question;

  const CreateQuestionDialog({
    super.key,
    required this.onQuestionCreated,
    required this.quizId,
    this.question,
  });

  @override
  State<CreateQuestionDialog> createState() => _CreateQuestionDialogState();
}

class _CreateQuestionDialogState extends State<CreateQuestionDialog> {
  final ApiService _apiService = Get.find<ApiService>();
  final _questionController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  String _questionType = 'mcq';
  List<Map<String, dynamic>> _choices = [
    {'text': '', 'isCorrect': false},
    {'text': '', 'isCorrect': false},
  ];
  bool _isLoading = false;
  bool? _trueFalseAnswer; // Track True/False selection

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!.questionText;
      _pointsController.text = widget.question!.points.toString();
      _questionType = widget.question!.questionType;
      _choices = widget.question!.choices
          .map((c) => {'text': c.choiceText, 'isCorrect': c.isCorrect})
          .toList();
      
      // Initialize True/False answer if it's a true_false question
      if (_questionType == 'true_false' && _choices.isNotEmpty) {
        _trueFalseAnswer = _choices[0]['isCorrect'] == true ? true : false;
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (_questionController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter question text',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      Question question;
      if (widget.question != null) {
        question = await _apiService.updateQuestion(
          questionId: widget.question!.id,
          questionText: _questionController.text,
          questionType: _questionType,
          points: int.parse(_pointsController.text),
          choices: _choices,
        );
      } else {
        question = await _apiService.createQuestion(
          quizId: widget.quizId,
          questionText: _questionController.text,
          questionType: _questionType,
          points: int.parse(_pointsController.text),
          choices: _choices,
        );
      }

      Get.back();
      widget.onQuestionCreated(question);
      Get.snackbar(
        'Success',
        'Question ${widget.question != null ? 'updated' : 'created'} successfully',
        backgroundColor: AppColors.successColor,
        colorText: AppColors.secondaryColor,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save question: $e',
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.secondaryColor,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.question != null ? 'Edit Question' : 'Create Question',
                style: AppTextStyle.h3,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Question Text',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintMaxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _questionType,
                decoration: InputDecoration(
                  labelText: 'Question Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice')),
                  DropdownMenuItem(
                      value: 'true_false', child: Text('True/False')),
                  DropdownMenuItem(
                      value: 'short_answer', child: Text('Short Answer')),
                ],
                onChanged: (value) {
                  setState(() {
                    _questionType = value!;
                    // Initialize choices based on question type
                    if (_questionType == 'true_false') {
                      _trueFalseAnswer = null; // Reset selection
                      _choices = [
                        {'text': 'True', 'isCorrect': false},
                        {'text': 'False', 'isCorrect': false},
                      ];
                    } else if (_questionType == 'mcq') {
                      _choices = [
                        {'text': '', 'isCorrect': false},
                        {'text': '', 'isCorrect': false},
                      ];
                    } else if (_questionType == 'short_answer') {
                      _choices = [
                        {'text': '', 'isCorrect': true},
                      ];
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_questionType == 'mcq') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Choices', style: AppTextStyle.bodyMedium),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _choices.add({'text': '', 'isCorrect': false});
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Choice'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._choices.asMap().entries.map((entry) {
                  int idx = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _choices[idx]['text'],
                            onChanged: (value) {
                              _choices[idx]['text'] = value;
                            },
                            decoration: InputDecoration(
                              hintText: 'Choice ${idx + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: _choices[idx]['isCorrect'],
                          onChanged: (value) {
                            setState(() {
                              _choices[idx]['isCorrect'] = value ?? false;
                            });
                          },
                        ),
                        if (_choices.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _choices.removeAt(idx);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ] else if (_questionType == 'true_false') ...[
                const Text('Correct Answer', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('True'),
                        value: true,
                        groupValue: _trueFalseAnswer,
                        onChanged: (val) {
                          setState(() {
                            _trueFalseAnswer = val;
                            _choices = [
                              {'text': 'True', 'isCorrect': val == true},
                              {'text': 'False', 'isCorrect': val == false},
                            ];
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('False'),
                        value: false,
                        groupValue: _trueFalseAnswer,
                        onChanged: (val) {
                          setState(() {
                            _trueFalseAnswer = val;
                            _choices = [
                              {'text': 'True', 'isCorrect': val == false},
                              {'text': 'False', 'isCorrect': val == true},
                            ];
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (_questionType == 'short_answer') ...[
                TextFormField(
                  initialValue: _choices.isNotEmpty ? _choices[0]['text'] : '',
                  onChanged: (value) {
                    setState(() {
                      _choices = [{'text': value, 'isCorrect': true}];
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Correct Answer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.secondaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(widget.question != null ? 'Save' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
}