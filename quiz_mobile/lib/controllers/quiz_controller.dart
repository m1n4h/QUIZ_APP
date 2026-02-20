import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/services/api_service.dart';

class QuizController extends GetxController {
  // Dependencies
  final ApiService _apiService = Get.find<ApiService>();
  final String quizId;

  // Observable State
  final Rx<Quiz?> quiz = Rx<Quiz?>(null);
  final RxInt currentQuestionIndex = 0.obs;
  final RxMap<String, String?> userAnswers = RxMap<String, String?>({});
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxInt remainingSeconds = 0.obs;
  Timer? _timer;

  QuizController({required this.quizId});

  @override
  void onInit() {
    _loadQuiz();
    super.onInit();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // ========== Computed Properties ==========

  // Access the list of questions safely
  List<Question> get questions => quiz.value?.questions ?? [];

  // Get the currently displayed question
  Question? get currentQuestion => questions.isNotEmpty
      ? questions[currentQuestionIndex.value]
      : null;

  // Get the progress value for the LinearProgressIndicator
  double get progressValue {
    if (questions.isEmpty) return 0.0;
    return (currentQuestionIndex.value + 1) / questions.length;
  }

  // Check if the current question is the last one
  bool get isLastQuestion =>
      currentQuestionIndex.value == questions.length - 1;

  // Check the currently selected answer for the current question
  String? get selectedChoiceId => currentQuestion != null
      ? userAnswers[currentQuestion!.id]
      : null;

  // Get remaining time as a formatted string
  String get formattedTime {
    final minutes = (remainingSeconds.value / 60).floor();
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ========== Logic Methods ==========

  Future<void> _loadQuiz() async {
    try {
      final loadedQuiz = await _apiService.getQuizById(quizId);
      
      // Initialize answers map with null for all questions
      for (var question in loadedQuiz.questions) {
        userAnswers[question.id] = null;
      }

      quiz.value = loadedQuiz;
      remainingSeconds.value = loadedQuiz.timeLimit * 60;
      _startTimer();
      isLoading.value = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load quiz. Please check your connection.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onBackground,
      );
      isLoading.value = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _timer?.cancel();
        submitQuiz(); // Auto-submit when time is up
      }
    });
  }

  void selectAnswer(String choiceId) {
    if (currentQuestion != null) {
      userAnswers[currentQuestion!.id] = choiceId;
    }
  }

  void goToNextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
    }
  }

  void goToPreviousQuestion() {
    if (currentQuestionIndex.value > 0) {
      currentQuestionIndex.value--;
    }
  }

  Future<void> submitQuiz() async {
    isSubmitting.value = true;
    _timer?.cancel(); // Stop the timer
    
    try {
      // Prepare answers for API submission
      final answers = userAnswers.entries
          .where((e) => e.value != null)
          .map((e) => {
                'questionId': e.key,
                'choiceId': e.value,
              })
          .toList();

      print('Submitting quiz with ${answers.length} answers');

      final result = await _apiService.submitQuiz(
        quizId: quizId,
        answers: answers,
        timeTaken: quiz.value != null ? (quiz.value!.timeLimit * 60) - remainingSeconds.value : 0,
      );

      print('Submission result: $result');

      if (result['success'] == true && quiz.value != null) {
        // Show success message
        Get.snackbar(
          'Success!',
          'Quiz submitted successfully! Score: ${result['score'] ?? 0}/${result['total_questions'] ?? questions.length * 2}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Navigate to results with detailed information
        Get.offNamed('/results', arguments: {
          'quiz': quiz.value,
          'score': result['score'] ?? 0,
          'totalQuestions': questions.length,
          'correctAnswers': result['correct_answers'] ?? 0,
          'percentage': result['percentage'] ?? 0,
          'answers': userAnswers,
          'timeTaken': (quiz.value!.timeLimit * 60) - remainingSeconds.value,
        });
      } else {
        Get.snackbar(
          'Submission Failed', 
          result['message'] ?? 'Failed to submit quiz. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      print('Submission error: $e');
      Get.snackbar(
        'Error', 
        'Network error occurred. Please check your connection and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}