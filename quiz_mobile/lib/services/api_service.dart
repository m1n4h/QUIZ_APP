import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_app/models/quiz_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService extends GetxService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String graphqlEndpoint = '$baseUrl/graphql/';
  static const String restEndpoint = '$baseUrl/api';
  late SharedPreferences _prefs;
  String _token = '';

  get token => _token;

  @override
  Future<void> onInit() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString('token') ?? '';
    super.onInit();
  }

  // ========== GraphQL REQUEST HELPER ==========
  Future<Map<String, dynamic>> _graphqlRequest(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      print('Making GraphQL request with token: ${_token.isNotEmpty ? "YES" : "NO"}');
      print('Query: ${query.substring(0, query.length > 100 ? 100 : query.length)}...');
      
      final response = await http.post(
        Uri.parse(graphqlEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'query': query,
          if (variables != null) 'variables': variables,
        }),
      );

      print('GraphQL Response: ${response.statusCode}');
      print('GraphQL Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['errors'] != null && (data['errors'] as List).isNotEmpty) {
          final errorMessage = data['errors'][0]['message'].toString();
          print('GraphQL Error: $errorMessage');
          
          // If the error is authentication-related, clear auth data
          if (errorMessage.toLowerCase().contains('not authenticated') || 
              errorMessage.toLowerCase().contains('unauthorized')) {
            print('Authentication error detected, clearing auth data');
            await clearAuthData();
          }
          
          throw Exception(errorMessage);
        }
        
        return data['data'] ?? {};
      } else {
        // If there's an HTTP error, check if it's authentication-related
        if (response.statusCode == 401) {
          print('401 Unauthorized, clearing auth data');
          await clearAuthData();
        }
        throw Exception('GraphQL Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('GraphQL Request Error: $e');
      rethrow;
    }
  }

  // ========== TOKEN & USER MANAGEMENT ==========

  Future<void> saveToken(String token) async {
    _token = token;
    await _prefs.setString('token', token);
    print('Token saved: $token');
  }

  String? getToken() {
    return _prefs.getString('token');
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _prefs.setString('user', jsonEncode(user));
    print('User data saved: $user');
  }

  Map<String, dynamic>? getUserData() {
    final userString = _prefs.getString('user');
    if (userString != null) {
      try {
        return jsonDecode(userString);
      } catch (e) {
        print('Error decoding user data: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> clearAuthData() async {
    await _prefs.remove('token');
    await _prefs.remove('user');
    await _prefs.remove('onboarding_completed');
    _token = '';
    print('Auth data cleared');
  }

  Future<bool> checkAuthStatus() async {
    final token = getToken();
    final user = getUserData();
    return token != null && user != null && token.isNotEmpty;
  }

  String getUserRole() {
    final user = getUserData();
    return user?['role'] ?? 'student';
  }

  bool isFirstTime() {
    return !_prefs.containsKey('onboarding_completed');
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('onboarding_completed', true);
  }

  // ========== AUTHENTICATION METHODS (GraphQL) ==========

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login for: $email');

      const query = '''
        mutation Login(\$email: String!, \$password: String!) {
          login(email: \$email, password: \$password) {
            success
            token
            user {
              id
              email
              firstName
              lastName
              role
              profileImage
            }
            message
          }
        }
      ''';

      final result = await _graphqlRequest(query, variables: {
        'email': email,
        'password': password,
      });

      final loginData = result['login'];

      if (loginData['success'] == true) {
        await saveToken(loginData['token']);
        final userData = loginData['user'];
        if (userData != null) {
          await saveUserData(userData);
        } else {
          await saveUserData({
            'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
            'email': email,
            'firstName': 'Test',
            'lastName': 'User',
            'role': 'student',
          });
        }

        return {
          'success': true,
          'message': 'Login successful',
          'token': loginData['token'],
          'user': loginData['user'],
        };
      } else {
        return {
          'success': false,
          'message': loginData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    try {
      print('Attempting signup for: $email');

      const query = '''
        mutation Signup(\$email: String!, \$password: String!, \$username: String!, \$firstName: String!, \$lastName: String!, \$role: String!) {
          signup(email: \$email, password: \$password, username: \$username, firstName: \$firstName, lastName: \$lastName, role: \$role) {
            success
            message
            user {
              id
              email
              username
              firstName
              lastName
              role
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query, variables: {
        'email': email,
        'password': password,
        'username': email,
        'firstName': name.split(' ').first,
        'lastName': name.split(' ').length > 1 ? name.split(' ').last : '',
        'role': role,
      });

      final signupData = result['signup'];

      if (signupData['success'] == true) {
        final userData = signupData['user'];
        if (userData != null) {
          await saveUserData(userData);
        } else {
          await saveUserData({
            'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
            'email': email,
            'firstName': name,
            'role': role,
          });
        }

        return signupData;
      } else {
        return {
          'success': false,
          'message': signupData['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      print('Signup error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // ========== QUIZ RETRIEVAL METHODS (GraphQL) ==========

  Future<Quiz> getQuizById(String quizId) async {
    try {
      const query = '''
        query GetQuiz(\$id: String!) {
          quizDetail(id: \$id) {
            id
            title
            description
            timeLimit
            isPublished
            scheduledStart
            scheduledEnd
            allowReview
            showScore
            isAvailable
            timeUntilStart
            timeUntilEnd
            questionCount
            createdBy {
              id
              firstName
              lastName
            }
            questions {
              id
              questionText
              questionType
              points
              order
              choices {
                id
                choiceText
                isCorrect
                order
              }
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query, variables: {'id': quizId});
      final quizData = result['quizDetail'];

      if (quizData == null) {
        return _getMockQuiz(quizId);
      }

      return Quiz.fromJson(quizData as Map<String, dynamic>);
    } catch (e) {
      print('Get quiz by ID error: $e');
      return _getMockQuiz(quizId);
    }
  }

  // CORRECTED: Restoring and implementing getStudentQuizzes correctly
  Future<List<Quiz>> getStudentQuizzes() async {
    try {
      const query = '''
        query {
          availableQuizzes {
            id
            title
            description
            scheduledStart
            scheduledEnd
            timeLimit
            questionCount
            isAvailable
            timeUntilStart
            timeUntilEnd
            createdBy {
              id
              firstName
              lastName
            }
            questions {
              id
              questionText
              choices {
                id
                choiceText
                isCorrect
              }
            }
          }
        }
      ''';

      // Use the helper, it handles the token automatically and returns the 'data' map!
      final result = await _graphqlRequest(query);
      
      // The result is the 'data' part of the response, so we extract availableQuizzes
      final quizzesData = result['availableQuizzes'] as List? ?? [];

      return quizzesData
          .map((q) => Quiz.fromJson(q as Map<String, dynamic>))
          .toList();

    } catch (e) {
      print('Get student quizzes error: $e');
      return []; // Return empty list on failure
    }
  }

  Future<List<Quiz>> getTeacherQuizzes() async {
    try {
      const query = '''
        query {
          myQuizzes {
            id
            title
            description
            timeLimit
            isPublished
            scheduledStart
            scheduledEnd
            questionCount
            questions {
              id
              questionText
              questionType
              points
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query);
      final quizzesData = result['myQuizzes'] as List? ?? [];

      return quizzesData
          .map((q) => Quiz.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get teacher quizzes error: $e');
      return [];
    }
  }

  Future<List<Quiz>> getAllQuizzes() async {
    try {
      print('🔍 API: Getting all quizzes...');
      const query = '''
        query {
          allQuizzes {
            id
            title
            description
            timeLimit
            isPublished
            scheduledStart
            scheduledEnd
            questionCount
            createdBy {
              id
              firstName
              lastName
            }
            questions {
              id
              questionText
              questionType
              points
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query);
      print('📊 API: GraphQL result keys: ${result.keys}');
      final quizzesData = result['allQuizzes'] as List? ?? [];
      print('📊 API: Parsed ${quizzesData.length} quizzes');

      return quizzesData
          .map((q) => Quiz.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ API: Get all quizzes error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('🔍 API: Getting all users...');
      const query = '''
        query {
          allUsers {
            id
            email
            firstName
            lastName
            role
            isApproved
            isActive
          }
        }
      ''';

      final result = await _graphqlRequest(query);
      print('📊 API: GraphQL result: $result');
      final usersData = result['allUsers'] as List? ?? [];
      print('📊 API: Parsed ${usersData.length} users');

      return usersData.map((u) => u as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ API: Get all users error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      const query = '''
        query {
          allSubjects {
            id
            name
            description
          }
        }
      ''';

      final result = await _graphqlRequest(query);
      final subjectsData = result['allSubjects'] as List? ?? [];

      return subjectsData.map((s) => s as Map<String, dynamic>).toList();
    } catch (e) {
      print('Get subjects error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateSubject({
    required String subjectId,
    required String name,
    required String description,
  }) async {
    try {
      const mutation = '''
        mutation UpdateSubject(\$subjectId: String!, \$name: String!, \$description: String!) {
          updateSubject(subjectId: \$subjectId, name: \$name, description: \$description) {
            success
            message
            subject {
              id
              name
              description
            }
          }
        }
      ''';

      final variables = {
        'subjectId': subjectId,
        'name': name,
        'description': description,
      };

      final result = await _graphqlRequest(mutation, variables: variables);
      return result['updateSubject'] ?? {'success': false, 'message': 'Unknown error'};
    } catch (e) {
      print('Update subject error: $e');
      return {'success': false, 'message': 'Failed to update subject: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSubject({
    required String subjectId,
  }) async {
    try {
      const mutation = '''
        mutation DeleteSubject(\$subjectId: String!) {
          deleteSubject(subjectId: \$subjectId) {
            success
            message
          }
        }
      ''';

      final variables = {
        'subjectId': subjectId,
      };

      final result = await _graphqlRequest(mutation, variables: variables);
      return result['deleteSubject'] ?? {'success': false, 'message': 'Unknown error'};
    } catch (e) {
      print('Delete subject error: $e');
      return {'success': false, 'message': 'Failed to delete subject: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      const mutation = '''
        mutation UpdateUserRole(\$userId: String!, \$role: String!) {
          updateUserRole(userId: \$userId, role: \$role) {
            success
            message
            user {
              id
              email
              firstName
              lastName
              role
            }
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'userId': userId,
        'role': role,
      });

      final updateData = result['updateUserRole'];
      return {
        'success': updateData['success'] == true,
        'message': updateData['message'],
        'user': updateData['user'],
      };
    } catch (e) {
      print('Update user role error: $e');
      return {
        'success': false,
        'message': 'Error updating user role: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserApproval({
    required String userId,
    required bool isApproved,
  }) async {
    try {
      const mutation = '''
        mutation UpdateUserApproval(\$userId: String!, \$isApproved: Boolean!) {
          updateUserApproval(userId: \$userId, isApproved: \$isApproved) {
            success
            message
            user {
              id
              email
              firstName
              lastName
              role
              isApproved
            }
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'userId': userId,
        'isApproved': isApproved,
      });

      final updateData = result['updateUserApproval'];
      return {
        'success': updateData['success'] == true,
        'message': updateData['message'],
        'user': updateData['user'],
      };
    } catch (e) {
      print('Update user approval error: $e');
      return {
        'success': false,
        'message': 'Error updating user approval: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createSubject({
    required String name,
    String description = '',
  }) async {
    try {
      const mutation = '''
        mutation CreateSubject(\$name: String!, \$description: String) {
          createSubject(name: \$name, description: \$description) {
            success
            message
            subject {
              id
              name
              description
            }
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'name': name,
        'description': description,
      });

      final createData = result['createSubject'];
      return {
        'success': createData['success'] == true,
        'message': createData['message'],
        'subject': createData['subject'],
      };
    } catch (e) {
      print('Create subject error: $e');
      return {
        'success': false,
        'message': 'Error creating subject: $e',
      };
    }
  }

  // ========== QUIZ CRUD MUTATIONS (GraphQL) ==========

  Future<Quiz> createQuiz({
    required String title,
    required String description,
    required int timeLimit,
    String? subjectId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    bool allowReview = true,
    bool showScore = true,
  }) async {
    try {
      const mutation = '''
        mutation CreateQuiz(
          \$title: String!
          \$description: String
          \$subjectId: String
          \$timeLimit: Int
          \$scheduledStart: DateTime
          \$scheduledEnd: DateTime
          \$allowReview: Boolean
          \$showScore: Boolean
        ) {
          createQuiz(
            title: \$title
            description: \$description
            subjectId: \$subjectId
            timeLimit: \$timeLimit
            scheduledStart: \$scheduledStart
            scheduledEnd: \$scheduledEnd
            allowReview: \$allowReview
            showScore: \$showScore
          ) {
            quiz {
              id
              title
              description
              timeLimit
              isPublished
              scheduledStart
              scheduledEnd
            }
            success
            message
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'title': title,
        'description': description,
        'subjectId': subjectId,
        'timeLimit': timeLimit,
        'scheduledStart': scheduledStart?.toIso8601String(),
        'scheduledEnd': scheduledEnd?.toIso8601String(),
        'allowReview': allowReview,
        'showScore': showScore,
      });

      final createData = result['createQuiz'];

      if (createData['success'] == true) {
        return Quiz.fromJson(createData['quiz']);
      } else {
        throw Exception(createData['message']);
      }
    } catch (e) {
      print('Create quiz error: $e');
      rethrow;
    }
  }

  Future<Quiz> updateQuiz({
    required String quizId,
    required String title,
    required String description,
    required int timeLimit,
    String? subjectId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    bool? isPublished,
  }) async {
    try {
      const mutation = '''
        mutation UpdateQuiz(
          \$quizId: String!
          \$title: String
          \$description: String
          \$timeLimit: Int
          \$subjectId: String
          \$scheduledStart: DateTime
          \$scheduledEnd: DateTime
          \$isPublished: Boolean
        ) {
          updateQuiz(
            quizId: \$quizId
            title: \$title
            description: \$description
            timeLimit: \$timeLimit
            subjectId: \$subjectId
            scheduledStart: \$scheduledStart
            scheduledEnd: \$scheduledEnd
            isPublished: \$isPublished
          ) {
            quiz {
              id
              title
              description
              timeLimit
              isPublished
            }
            success
            message
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'quizId': quizId,
        'title': title,
        'description': description,
        'timeLimit': timeLimit,
        'subjectId': subjectId,
        'scheduledStart': scheduledStart?.toIso8601String(),
        'scheduledEnd': scheduledEnd?.toIso8601String(),
        'isPublished': isPublished,
      });

      final updateData = result['updateQuiz'];

      if (updateData['success'] == true) {
        return Quiz.fromJson(updateData['quiz']);
      } else {
        throw Exception(updateData['message']);
      }
    } catch (e) {
      print('Update quiz error: $e');
      rethrow;
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      const mutation = '''
        mutation DeleteQuiz(\$quizId: String!) {
          deleteQuiz(quizId: \$quizId) {
            success
            message
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'quizId': quizId,
      });

      final deleteData = result['deleteQuiz'];

      if (deleteData['success'] != true) {
        throw Exception(deleteData['message']);
      }
    } catch (e) {
      print('Delete quiz error: $e');
      rethrow;
    }
  }

  // ========== QUESTION METHODS (GraphQL) ==========

  Future<Question> createQuestion({
    required String quizId,
    required String questionText,
    required String questionType,
    required int points,
    required List<Map<String, dynamic>> choices,
  }) async {
    try {
      const mutation = '''
        mutation CreateQuestion(
          \$quizId: String!
          \$questionText: String!
          \$questionType: String!
          \$choices: [JSONString]!
          \$points: Int
        ) {
          createQuestion(
            quizId: \$quizId
            questionText: \$questionText
            questionType: \$questionType
            choices: \$choices
            points: \$points
          ) {
            question {
              id
              questionText
              questionType
              points
              order
              choices {
                id
                choiceText
                isCorrect
                order
              }
            }
            success
            message
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'quizId': quizId,
        'questionText': questionText,
        'questionType': questionType,
        'choices': choices.map((choice) => jsonEncode(choice)).toList(), // Convert to JSON strings
        'points': points,
      });

      final questionData = result['createQuestion'];

      if (questionData['success'] == true) {
        return Question.fromJson(questionData['question']);
      } else {
        throw Exception(questionData['message']);
      }
    } catch (e) {
      print('Create question error: $e');
      rethrow;
    }
  }

  // ========== QUIZ SUBMISSION (GraphQL) ==========

  Future<Map<String, dynamic>> submitQuiz({
    required String quizId,
    required List<Map<String, dynamic>> answers,
    int timeTaken = 0,
  }) async {
    try {
      print('Submitting quiz: $quizId with ${answers.length} answers');
      print('Time taken: $timeTaken seconds');
      
      const mutation = '''
        mutation SubmitQuiz(
          \$quizId: String!
          \$answers: [JSONString]!
          \$timeTaken: Int
        ) {
          submitQuiz(
            quizId: \$quizId
            answers: \$answers
            timeTaken: \$timeTaken
          ) {
            attempt {
              id
              score
              totalQuestions
              correctAnswers
              percentage
              status
              completedAt
            }
            success
            message
          }
        }
      ''';

      // Convert answers to JSON strings as expected by GraphQL
      final answersAsJsonStrings = answers.map((answer) => jsonEncode(answer)).toList();
      print('Converted answers: $answersAsJsonStrings');

      final result = await _graphqlRequest(mutation, variables: {
        'quizId': quizId,
        'answers': answersAsJsonStrings,
        'timeTaken': timeTaken,
      });

      final submitData = result['submitQuiz'];
      print('Submit response: $submitData');

      if (submitData['success'] == true) {
        final attempt = submitData['attempt'];
        return {
          'success': true,
          'score': attempt['score'] ?? 0,
          'total_questions': attempt['totalQuestions'] ?? 0,
          'correct_answers': attempt['correctAnswers'] ?? 0,
          'percentage': attempt['percentage'] ?? 0,
          'status': attempt['status'] ?? 'completed',
          'message': submitData['message'] ?? 'Quiz submitted successfully!',
        };
      } else {
        return {
          'success': false,
          'message': submitData['message'] ?? 'Failed to submit quiz',
        };
      }
    } catch (e) {
      print('Submit quiz error: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your connection and try again.',
      };
    }
  }

  // ========== TEACHER ANALYTICS METHODS (GraphQL) ==========

  Future<List<Map<String, dynamic>>> getQuizAttempts(String quizId) async {
    try {
      const query = '''
        query GetQuizAttempts(\$quizId: String!) {
          quizAttempts(quizId: \$quizId) {
            id
            score
            totalQuestions
            correctAnswers
            percentage
            status
            timeTaken
            completedAt
            studentName
            studentEmail
            user {
              id
              firstName
              lastName
              email
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query, variables: {'quizId': quizId});
      final attemptsData = result['quizAttempts'] as List? ?? [];

      return attemptsData.map((a) => a as Map<String, dynamic>).toList();
    } catch (e) {
      print('Get quiz attempts error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getQuizAnalytics(String quizId) async {
    try {
      const query = '''
        query GetQuizAnalytics(\$quizId: String!) {
          quizAnalytics(quizId: \$quizId) {
            quizId
            quizTitle
            totalAttempts
            uniqueStudents
            averageScore
            highestScore
            lowestScore
            averageCompletionTime
            passRate
            questionAnalytics {
              questionId
              questionText
              totalAttempts
              correctAttempts
              accuracyPercentage
              difficultyLevel
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query, variables: {'quizId': quizId});
      return result['quizAnalytics'] as Map<String, dynamic>?;
    } catch (e) {
      print('Get quiz analytics error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentPerformance(String quizId, String userId) async {
    try {
      const query = '''
        query GetStudentPerformance(\$quizId: String!, \$userId: String!) {
          studentPerformance(quizId: \$quizId, userId: \$userId) {
            studentId
            studentName
            studentEmail
            attempt {
              id
              score
              totalQuestions
              correctAnswers
              percentage
              status
              timeTaken
              completedAt
            }
            answers {
              id
              questionText
              selectedChoiceText
              correctChoiceText
              isCorrect
              pointsEarned
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query, variables: {
        'quizId': quizId,
        'userId': userId,
      });
      return result['studentPerformance'] as Map<String, dynamic>?;
    } catch (e) {
      print('Get student performance error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getQuizResults() async {
    try {
      const query = '''
        query {
          quizResults {
            id
            score
            totalQuestions
            correctAnswers
            percentage
            status
            completedAt
            quiz {
              id
              title
              description
            }
          }
        }
      ''';

      final result = await _graphqlRequest(query);
      final resultsData = result['quizResults'] as List? ?? [];

      return resultsData.map((r) => r as Map<String, dynamic>).toList();
    } catch (e) {
      print('Get quiz results error: $e');
      return [];
    }
  }

  // ========== QUESTION METHODS (GraphQL) ==========

  Future<Question> updateQuestion({
    required String questionId,
    String? questionText,
    String? questionType,
    int? points,
    int? order,
    List<Map<String, dynamic>>? choices,
  }) async {
    try {
      const mutation = '''
        mutation UpdateQuestion(
          \$questionId: String!
          \$questionText: String
          \$questionType: String
          \$points: Int
          \$order: Int
          \$choices: [JSONString]
        ) {
          updateQuestion(
            questionId: \$questionId
            questionText: \$questionText
            questionType: \$questionType
            points: \$points
            order: \$order
            choices: \$choices
          ) {
            question {
              id
              questionText
              questionType
              points
              order
              choices {
                id
                choiceText
                isCorrect
                order
              }
            }
            success
            message
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'questionId': questionId,
        'questionText': questionText,
        'questionType': questionType,
        'points': points,
        'order': order,
        if (choices != null) 'choices': choices.map((choice) => jsonEncode(choice)).toList(), // Convert to JSON strings
      });

      final questionData = result['updateQuestion'];

      if (questionData['success'] == true) {
        return Question.fromJson(questionData['question']);
      } else {
        throw Exception(questionData['message']);
      }
    } catch (e) {
      print('Update question error: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      const mutation = '''
        mutation DeleteQuestion(\$questionId: String!) {
          deleteQuestion(questionId: \$questionId) {
            success
            message
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'questionId': questionId,
      });

      final deleteData = result['deleteQuestion'];

      if (deleteData['success'] != true) {
        throw Exception(deleteData['message']);
      }
    } catch (e) {
      print('Delete question error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteUser({required String userId}) async {
    try {
      const mutation = '''
        mutation DeleteUser(\$userId: String!) {
          deleteUser(userId: \$userId) {
            success
            message
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'userId': userId,
      });

      final deleteData = result['deleteUser'];
      return {
        'success': deleteData['success'] == true,
        'message': deleteData['message'],
      };
    } catch (e) {
      print('Delete user error: $e');
      return {
        'success': false,
        'message': 'Error deleting user: $e',
      };
    }
  }

  Future<Map<String, dynamic>> suspendUser({
    required String userId,
    required bool isSuspended,
  }) async {
    try {
      const mutation = '''
        mutation SuspendUser(\$userId: String!, \$isSuspended: Boolean!) {
          suspendUser(userId: \$userId, isSuspended: \$isSuspended) {
            success
            message
            user {
              id
              email
              firstName
              lastName
              role
              isApproved
              isActive
            }
          }
        }
      ''';

      final result = await _graphqlRequest(mutation, variables: {
        'userId': userId,
        'isSuspended': isSuspended,
      });

      final suspendData = result['suspendUser'];
      return {
        'success': suspendData['success'] == true,
        'message': suspendData['message'],
        'user': suspendData['user'],
      };
    } catch (e) {
      print('Suspend user error: $e');
      return {
        'success': false,
        'message': 'Error suspending user: $e',
      };
    }
  }

  // ========== LOGOUT ==========

  // ========== PROFILE MANAGEMENT ==========
  
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      const query = '''
        query {
          userProfile {
            id
            email
            firstName
            lastName
            role
            isApproved
            isActive
          }
        }
      ''';

      final result = await _graphqlRequest(query);
      return result['userProfile'] ?? {};
    } catch (e) {
      print('Get user profile error: $e');
      throw Exception('Failed to load user profile');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      const mutation = '''
        mutation UpdateProfile(\$firstName: String!, \$lastName: String!, \$email: String!) {
          updateProfile(firstName: \$firstName, lastName: \$lastName, email: \$email) {
            success
            message
            user {
              id
              email
              firstName
              lastName
              role
            }
          }
        }
      ''';

      final variables = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

      final result = await _graphqlRequest(mutation, variables: variables);
      return result['updateProfile'] ?? {'success': false, 'message': 'Unknown error'};
    } catch (e) {
      print('Update profile error: $e');
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      const mutation = '''
        mutation ChangePassword(\$currentPassword: String!, \$newPassword: String!) {
          changePassword(currentPassword: \$currentPassword, newPassword: \$newPassword) {
            success
            message
          }
        }
      ''';

      final variables = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final result = await _graphqlRequest(mutation, variables: variables);
      return result['changePassword'] ?? {'success': false, 'message': 'Unknown error'};
    } catch (e) {
      print('Change password error: $e');
      return {'success': false, 'message': 'Failed to change password: $e'};
    }
  }

  // ========== LOGOUT ==========

 Future<void> logout() async {
  try {
    final token = getToken();
    if (token != null && token.isNotEmpty) {
      const mutation = '''
        mutation {
          logout {
            success
            message
          }
        }
      ''';

      await _graphqlRequest(mutation);
    }
  } catch (e) {
    print('Logout API error: $e');
  } finally {
    await clearAuthData();  // This clears token and user data
  }
}

  // ========== HELPER METHODS ==========
  // ========== HELPER METHODS ==========

  Quiz _getMockQuiz(String quizId) {
    // This mock needs to supply ALL required parameters from your final Quiz model.
    return Quiz(
      id: quizId,
      title: 'Sample Quiz',
      description: 'This is a sample quiz',
      subjectId: '1',
      timeLimit: 30,
      isPublished: true,
      createdAt: DateTime.now(),
      
      // Required fields for the final Quiz model
      timeUntilStart: 0,
      timeUntilEnd: 0,
      questionCount: 1,
      isAvailable: true,
      createdById: 'mock_user',
      createdByFirstName: 'Mock',
      createdByLastName: 'User',

      questions: [
        Question(
          id: '1',
          questionText: 'What is Flutter?',
          questionType: 'mcq',
          points: 5,
          order: 0,
          choices: [
            Choice(
              id: '1',
              choiceText: 'A programming language',
              isCorrect: false,
              order: 0,
            ),
            Choice(
              id: '2',
              choiceText: 'A UI toolkit',
              isCorrect: true,
              order: 1,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<ApiService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs.getString('token') ?? '';
    return this;
  }

// In api_service.dart, replace the empty googleAuth method with:
Future<Map<String, dynamic>> googleAuth({
  required String email,
  required String name,
  required String googleId,
  String? profileImage,
  String? accessToken,
}) async {
  try {
    print('Attempting Google auth for: $email');

    const mutation = r'''
      mutation GoogleAuth($accessToken: String!) {
        googleAuth(accessToken: $accessToken) {
          success
          token
          refresh
          user {
            id
            email
            firstName
            lastName
            role
            profileImage
          }
          message
        }
      }
    ''';

    final result = await _graphqlRequest(mutation, variables: {
      'accessToken': accessToken,
    });

    final authData = result['googleAuth'];

    if (authData != null && authData['success'] == true) {
      final token = authData['token'] as String?;
      final user = authData['user'] as Map<String, dynamic>?;

      if (token != null && token.isNotEmpty) {
        await saveToken(token);
      }

      if (user != null) {
        await saveUserData(user);
      } else {
        await saveUserData({
          'id': googleId,
          'email': email,
          'firstName': name,
          'role': 'student',
          'profileImage': profileImage,
        });
      }

      print('Google auth successful');
      return {
        'success': true,
        'message': 'Google login successful',
        'token': token,
        'user': user,
      };
    } else {
      return {
        'success': false,
        'message': authData?['message'] ?? 'Google auth failed',
      };
    }
  } catch (e) {
    print('Google auth error: $e');
    return {
      'success': false,
      'message': 'Network error: $e',
    };
  }
}
} // <--- Added the missing closing brace '}' here