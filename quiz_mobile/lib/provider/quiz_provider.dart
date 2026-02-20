// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:quiz_app/models/quiz_model.dart';
// import 'package:quiz_app/core/services/api_service.dart';
// import 'package:get/get.dart';

// class QuizState {
//   final List<Question> questions;
//   final List<Map<String, dynamic>> userAnswers;
//   final bool isLoading;
//   final String? error;

//   QuizState({
//     this.questions = const [],
//     this.userAnswers = const [],
//     this.isLoading = false,
//     this.error,
//   });

//   QuizState copyWith({
//     List<Question>? questions,
//     List<Map<String, dynamic>>? userAnswers,
//     bool? isLoading,
//     String? error,
//   }) {
//     return QuizState(
//       questions: questions ?? this.questions,
//       userAnswers: userAnswers ?? this.userAnswers,
//       isLoading: isLoading ?? this.isLoading,
//       error: error ?? this.error,
//     );
//   }
// }

// class QuizNotifier extends StateNotifier<QuizState> {
//   final ApiService _apiService = Get.find<ApiService>();

//   QuizNotifier() : super(QuizState());

//   Future<void> loadQuizQuestions(String quizId) async {
//     state = state.copyWith(isLoading: true, error: null);
    
//     try {
//       final questions = await _apiService.getQuizQuestions(quizId);
//       state = state.copyWith(
//         questions: questions,
//         isLoading: false,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: 'Failed to load questions: $e',
//       );
//     }
//   }

//   void addAnswer({
//     required String questionId,
//     required String? selectedChoiceId,
//     required String answerText,
//   }) {
//     final newAnswer = {
//       'question_id': questionId,
//       'selected_choice_id': selectedChoiceId,
//       'answer_text': answerText,
//       'timestamp': DateTime.now().toIso8601String(),
//     };
    
//     state = state.copyWith(
//       userAnswers: [...state.userAnswers, newAnswer],
//     );
//   }

//   void resetQuiz() {
//     state = QuizState();
//   }

//   Future<Map<String, dynamic>> submitQuiz(String quizId) async {
//     try {
//       return await _apiService.submitQuiz(
//         quizId: quizId,
//         answers: state.userAnswers,
//       );
//     } catch (e) {
//       return {
//         'success': false,
//         'message': 'Failed to submit quiz: $e',
//         'score': 0,
//         'correct_answers': 0,
//         'total_questions': state.questions.length,
//       };
//     }
//   }
// }

// final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
//   (ref) => QuizNotifier(),
// );