import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/controllers/quiz_controller.dart';

class QuizScreen extends GetView<QuizController> {
  final String quizId;

  QuizScreen({super.key, required this.quizId})
      : controller = Get.put(QuizController(quizId: quizId));

  @override
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.remainingSeconds.value < 60 
                        ? Colors.red.withOpacity(0.1) 
                        : AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: controller.remainingSeconds.value < 60 
                            ? Colors.red 
                            : AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.formattedTime,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: controller.remainingSeconds.value < 60 
                              ? Colors.red 
                              : AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Progress Bar
                LinearProgressIndicator(
                  value: controller.progressValue,
                  backgroundColor: Colors.grey[200],
                  color: AppColors.primaryColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                Text(
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
                  child: ListView.separated(
                    itemCount: currentQuestion.choices.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final choice = currentQuestion.choices[index];
                      final isSelected = controller.selectedChoiceId == choice.id;

                      return GestureDetector(
                        onTap: () => controller.selectAnswer(choice.id),
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

                const SizedBox(height: 20),

                // 4. Navigation Buttons
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
                      onPressed: controller.isLastQuestion 
                          ? (controller.isSubmitting.value ? null : controller.submitQuiz) 
                          : controller.goToNextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: controller.isSubmitting.value 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              controller.isLastQuestion ? "Submit Quiz" : "Next",
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