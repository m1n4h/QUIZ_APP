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

  QuizController({required this.quizId});

  @override
  void onInit() {
    _loadQuiz();
    super.onInit();
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

  // ========== Logic Methods ==========

  Future<void> _loadQuiz() async {
    try {
      final loadedQuiz = await _apiService.getQuizById(quizId);
      
      // Initialize answers map with null for all questions
      for (var question in loadedQuiz.questions) {
        userAnswers[question.id] = null;
      }

      quiz.value = loadedQuiz;
      isLoading.value = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load quiz. Please check your connection.',
        // Assuming AppColors is available or replace with standard colors
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onBackground,
      );
      isLoading.value = false;
    }
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
    try {
      // Prepare answers for API submission
      final answers = userAnswers.entries
          .where((e) => e.value != null)
          .map((e) => {
                'questionId': e.key,
                'choiceId': e.value,
              })
          .toList();

      final result = await _apiService.submitQuiz(
        quizId: quizId,
        answers: answers,
      );

      if (result['success'] == true && quiz.value != null) {
        // Navigate to results
         Get.offNamed('/results', arguments: {
          'quiz': quiz.value,
          'score': result['score'] ?? 0,
          'totalQuestions': questions.length,
        });
      } else {
        Get.snackbar('Error', result['message'] ?? 'Failed to submit quiz.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Submission failed: $e');
    } finally {
      isSubmitting.value = false;
    }
  }
}