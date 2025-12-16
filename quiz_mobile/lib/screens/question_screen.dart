// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:quiz_app/constants/app_styles.dart';
// import 'package:quiz_app/models/quiz_model.dart';
// import 'package:quiz_app/services/api_service.dart';

// class QuizScreen extends StatefulWidget {
//   final String quizId;

//   const QuizScreen({super.key, required this.quizId});

//   @override
//   State<QuizScreen> createState() => _QuizScreenState();
// }

// class _QuizScreenState extends State<QuizScreen> {
//   final ApiService _apiService = Get.find<ApiService>();
//   int _currentQuestionIndex = 0;
//   final Map<String, String?> _userAnswers = {};
//   bool _isLoading = true;
//   bool _isSubmitting = false; // Added to prevent double tap on submit
//   Quiz? _quiz;

//   @override
//   void initState() {
//     super.initState();
//     _loadQuiz();
//   }

//   Future<void> _loadQuiz() async {
//     try {
//       final quiz = await _apiService.getQuizById(widget.quizId);
      
//       // Initialize answers map
//       for (var question in quiz.questions) {
//         _userAnswers[question.id] = null;
//       }

//       setState(() {
//         _quiz = quiz;
//         _isLoading = false;
//       });
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to load quiz. Please check your connection.',
//         backgroundColor: AppColors.errorColor,
//         colorText: AppColors.secondaryColor,
//       );
//       setState(() => _isLoading = false);
//     }
//   }

//   void _selectAnswer(String choiceId) {
//     setState(() {
//       _userAnswers[_quiz!.questions[_currentQuestionIndex].id] = choiceId;
//     });
//   }

//   void _goToNextQuestion() {
//     if (_currentQuestionIndex < _quiz!.questions.length - 1) {
//       setState(() {
//         _currentQuestionIndex++;
//       });
//     }
//   }

//   void _goToPreviousQuestion() {
//     if (_currentQuestionIndex > 0) {
//       setState(() {
//         _currentQuestionIndex--;
//       });
//     }
//   }

//   Future<void> _submitQuiz() async {
//     setState(() => _isSubmitting = true);
//     try {
//       // Filter out null answers if your API doesn't accept them
//       final answers = _userAnswers.entries
//           .where((e) => e.value != null)
//           .map((e) => {
//                 'questionId': e.key,
//                 'choiceId': e.value,
//               })
//           .toList();

//       final result = await _apiService.submitQuiz(
//         quizId: widget.quizId,
//         answers: answers,
//       );

//       if (result['success'] == true) {
//         // Navigate to results
//         // Ensure you have a route defined for '/results' or use Get.off
//          Get.offNamed('/results', arguments: {
//           'quiz': _quiz,
//           'score': result['score'] ?? 0,
//           'totalQuestions': _quiz!.questions.length,
//         });
//       } else {
//         Get.snackbar('Error', result['message'] ?? 'Failed to submit');
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Submission failed: $e');
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_quiz == null || _quiz!.questions.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text("Error")),
//         body: const Center(child: Text("No questions found.")),
//       );
//     }

//     final currentQuestion = _quiz!.questions[_currentQuestionIndex];
//     final progressValue = (_currentQuestionIndex + 1) / _quiz!.questions.length;
//     final selectedChoiceId = _userAnswers[currentQuestion.id];
//     final isLastQuestion = _currentQuestionIndex == _quiz!.questions.length - 1;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_quiz!.title, style: AppTextStyle.h3),
//         backgroundColor: AppColors.secondaryColor,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.black),
//           onPressed: () => Get.back(),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1. Progress Bar
//               LinearProgressIndicator(
//                 value: progressValue,
//                 backgroundColor: Colors.grey[200],
//                 color: AppColors.primaryColor,
//                 minHeight: 8,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 "Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}",
//                 style: AppTextStyle.bodySmall.copyWith(color: Colors.grey),
//               ),
//               const SizedBox(height: 24),

//               // 2. Question Text
//               Text(
//                 currentQuestion.questionText,
//                 style: AppTextStyle.h2.copyWith(fontSize: 20),
//               ),
//               const SizedBox(height: 32),

//               // 3. Choices List
//               Expanded(
//                 child: ListView.separated(
//                   itemCount: currentQuestion.choices.length,
//                   separatorBuilder: (c, i) => const SizedBox(height: 12),
//                   itemBuilder: (context, index) {
//                     final choice = currentQuestion.choices[index];
//                     final isSelected = choice.id == selectedChoiceId;

//                     return GestureDetector(
//                       onTap: () => _selectAnswer(choice.id),
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: isSelected 
//                               ? AppColors.primaryColor.withOpacity(0.1) 
//                               : Colors.white,
//                           border: Border.all(
//                             color: isSelected 
//                                 ? AppColors.primaryColor 
//                                 : Colors.grey.shade300,
//                             width: 2,
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 24,
//                               height: 24,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: isSelected 
//                                       ? AppColors.primaryColor 
//                                       : Colors.grey.shade400,
//                                 ),
//                                 color: isSelected 
//                                     ? AppColors.primaryColor 
//                                     : Colors.transparent,
//                               ),
//                               child: isSelected
//                                   ? const Icon(Icons.check, size: 16, color: Colors.white)
//                                   : null,
//                             ),
//                             const SizedBox(width: 16),
//                             Expanded(
//                               child: Text(
//                                 choice.choiceText,
//                                 style: AppTextStyle.bodyMedium.copyWith(
//                                   fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                                   color: isSelected ? AppColors.primaryColor : Colors.black87,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // 4. Navigation Buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Previous Button
//                   if (_currentQuestionIndex > 0)
//                     TextButton(
//                       onPressed: _goToPreviousQuestion,
//                       child: Text("Previous", style: AppTextStyle.buttonMedium.copyWith(color: Colors.grey)),
//                     )
//                   else
//                     const SizedBox.shrink(),

//                   // Next or Submit Button
//                   ElevatedButton(
//                     onPressed: isLastQuestion 
//                         ? (_isSubmitting ? null : _submitQuiz) 
//                         : _goToNextQuestion,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryColor,
//                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     child: _isSubmitting 
//                         ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                         : Text(
//                             isLastQuestion ? "Submit Quiz" : "Next",
//                             style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
//                           ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart'; // Ensure this import is correct
import 'package:quiz_app/controllers/quiz_controller.dart'; // Import the new controller

// We change this from StatefulWidget to GetView
class QuizScreen extends GetView<QuizController> {
  final String quizId;

  // The constructor now binds the Controller to the screen using Get.put
   QuizScreen({super.key, required this.quizId}) {
    // Inject the controller with the required quizId argument
    Get.put(QuizController(quizId: quizId));
  }

  // We only need the build method now, no State class
  @override
  Widget build(BuildContext context) {
    // Obx wraps the entire body to react to loading state changes
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.quiz.value == null || controller.questions.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(child: Text("No questions found.")),
        );
      }

      final currentQuestion = controller.currentQuestion!;
      
      // Obx also wraps properties that depend on reactive state changes
      final progressValue = controller.progressValue;
      final selectedChoiceId = controller.selectedChoiceId;
      final isLastQuestion = controller.isLastQuestion;
      final isSubmitting = controller.isSubmitting.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(controller.quiz.value!.title, style: AppTextStyle.h3),
          backgroundColor: AppColors.secondaryColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Progress Bar
                LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.grey[200],
                  color: AppColors.primaryColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                Text(
                  // Use controller.currentQuestionIndex for display
                  "Question ${controller.currentQuestionIndex.value + 1} of ${controller.questions.length}",
                  style: AppTextStyle.bodySmall.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // 2. Question Text
                Text(
                  currentQuestion.questionText,
                  style: AppTextStyle.h2.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 32),

                // 3. Choices List
                Expanded(
                  // Use Obx to rebuild this part when the selected answer changes
                  child: Obx(() => ListView.separated(
                      itemCount: currentQuestion.choices.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final choice = currentQuestion.choices[index];
                        final isSelected = choice.id == selectedChoiceId;

                        return GestureDetector(
                          onTap: () => controller.selectAnswer(choice.id), // Call Controller method
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primaryColor.withOpacity(0.1) 
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primaryColor 
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                          ? AppColors.primaryColor 
                                          : Colors.grey.shade400,
                                    ),
                                    color: isSelected 
                                        ? AppColors.primaryColor 
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    choice.choiceText,
                                    style: AppTextStyle.bodyMedium.copyWith(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? AppColors.primaryColor : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Navigation Buttons (use Obx to react to isLastQuestion/isSubmitting)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    if (controller.currentQuestionIndex.value > 0)
                      TextButton(
                        onPressed: controller.goToPreviousQuestion,
                        child: Text("Previous", style: AppTextStyle.buttonMedium.copyWith(color: Colors.grey)),
                      )
                    else
                      const SizedBox.shrink(),

                    // Next or Submit Button
                    ElevatedButton(
                      // Check isLastQuestion and isSubmitting from the controller
                      onPressed: isLastQuestion 
                          ? (isSubmitting ? null : controller.submitQuiz) 
                          : controller.goToNextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isLastQuestion ? "Submit Quiz" : "Next",
                              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}