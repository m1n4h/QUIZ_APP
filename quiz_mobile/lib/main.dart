import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_theme.dart';
import 'package:quiz_app/screens/login_screen.dart';
import 'package:quiz_app/screens/onboarding_screen.dart';
import 'package:quiz_app/screens/question_screen.dart';

import 'package:quiz_app/screens/quiz_list_screen.dart';
import 'package:quiz_app/screens/result_screen.dart';
import 'package:quiz_app/screens/signup_screen.dart';
import 'package:quiz_app/screens/splash_screen.dart';
import 'package:quiz_app/screens/teacher_dashboard_screen.dart';
import 'package:quiz_app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIXED GetX initialization
  await Get.putAsync<ApiService>(() async {
    final service = ApiService();
    await service.init();
    return service;
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'QuizMaster',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => SplashScreen()),
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
         GetPage(
    name: '/student-quiz/:quizId',
    page: () {
      final quizId = Get.parameters['quizId'] ?? '';
      return QuizScreen(quizId: quizId);
    },
  ),
  GetPage(name: '/results', page: () => const ResultScreen()),
  GetPage(name: '/teacher-dashboard', page: () => const TeacherDashboardScreen()),
      ],
    );
  }
}

 //note///////////
// Created AuthMiddleware class to check authentication status
//✅ Added middlewares: [AuthMiddleware()] to protected routes:
// /quiz-list
// /student-quiz/:quizId
// /results
// /teacher-dashboard
// ✅ When logged out user tries to access quiz, they're redirected to /login

// How it works:

// User logs out → token is cleared in ApiService
// User restarts app → SplashScreen checks if logged in
// If ApiService.token is empty, user is sent to login screen
// Protected routes check token via middleware and redirect to login if needed


// Replace the entire main.dart file with this code...................below


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:quiz_app/constants/app_theme.dart';
// import 'package:quiz_app/screens/login_screen.dart';
// import 'package:quiz_app/screens/onboarding_screen.dart';
// import 'package:quiz_app/screens/question_screen.dart';
// import 'package:quiz_app/screens/quiz_list_screen.dart';
// import 'package:quiz_app/screens/result_screen.dart';
// import 'package:quiz_app/screens/signup_screen.dart';
// import 'package:quiz_app/screens/splash_screen.dart';
// import 'package:quiz_app/screens/teacher_dashboard_screen.dart';
// import 'package:quiz_app/services/api_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Get.putAsync<ApiService>(() async {
//     final service = ApiService();
//     await service.init();
//     return service;
//   });

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'QuizMaster',
//       theme: AppThemes.light,
//       darkTheme: AppThemes.dark,
//       themeMode: ThemeMode.light,
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/',
//       getPages: [
//         GetPage(name: '/', page: () => const SplashScreen()),
//         GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
//         GetPage(name: '/login', page: () => const LoginScreen()),
//         GetPage(name: '/signup', page: () => const SignupScreen()),
//         GetPage(
//           name: '/quiz-list',
//           page: () => const QuizListScreen(),
//           middlewares: [AuthMiddleware()],
//         ),
//         GetPage(
//           name: '/student-quiz/:quizId',
//           page: () {
//             final quizId = Get.parameters['quizId'] ?? '';
//             return QuizScreen(quizId: quizId);
//           },
//           middlewares: [AuthMiddleware()],
//         ),
//         GetPage(
//           name: '/results',
//           page: () => const ResultScreen(),
//           middlewares: [AuthMiddleware()],
//         ),
//         GetPage(
//           name: '/teacher-dashboard',
//           page: () => const TeacherDashboardScreen(),
//           middlewares: [AuthMiddleware()],
//         ),
//       ],
//     );
//   }
// }

// /// Middleware to check if user is authenticated
// class AuthMiddleware extends GetMiddleware {
//   @override
//   int? get priority => 1;

//   @override
//   RouteSettings? redirect(String? route) {
//     final apiService = Get.find<ApiService>();
    
//     // Check if user token exists (user is logged in)
//     if (apiService.token.isEmpty) {
//       // Redirect to login if not authenticated
//       return RouteSettings(name: '/login');
//     }
//     return null;
//   }
// }