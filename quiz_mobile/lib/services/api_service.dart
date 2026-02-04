import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_app/models/quiz_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService extends GetxService {
  static const String baseUrl = 'http://192.168.0.108:8000';
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
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

      print('GraphQL Headers - Authorization present: ${headers.containsKey('Authorization')} tokenLength: ${_token.length}');

      final response = await http.post(
        Uri.parse(graphqlEndpoint),
        headers: headers,
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
          throw Exception(data['errors'][0]['message']);
        }
        
        return data['data'] ?? {};
      } else {
        throw Exception('GraphQL Error: ${response.statusCode}');
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
        await saveUserData(loginData['user'] ?? {
          'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'email': email,
          'firstName': 'Test',
          'lastName': 'User',
          'role': 'student',
        });

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
        await saveUserData(signupData['user'] ?? {
          'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'email': email,
          'firstName': name,
          'role': role,
        });

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

  // ========== QUIZ CRUD MUTATIONS (GraphQL) ==========

  Future<Quiz> createQuiz({
    required String title,
    required String description,
    required int timeLimit,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    bool allowReview = true,
    bool showScore = true,
  }) async {
    try {
      // Quick auth guard for clearer client-side error message
      if (_token.isEmpty) {
        print('CreateQuiz blocked: no token present');
        throw Exception('Not authenticated. Please log in.');
      }

      const mutation = '''
        mutation CreateQuiz(
          \$title: String!
          \$description: String
          \$subjectId: String!
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
              allowReview
              showScore
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
        'subjectId': '1',
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
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    bool? isPublished,
     required bool allowReview,
     required bool showScore,
  }) async {
    try {
      const mutation = '''
        mutation UpdateQuiz(
          \$quizId: String!
          \$title: String
          \$description: String
          \$timeLimit: Int
          \$scheduledStart: DateTime
          \$scheduledEnd: DateTime
          \$allowReview: Boolean
          \$showScore: Boolean
          \$isPublished: Boolean
        ) {
          updateQuiz(
            quizId: \$quizId
            title: \$title
            description: \$description
            timeLimit: \$timeLimit
            scheduledStart: \$scheduledStart
            scheduledEnd: \$scheduledEnd
            allowReview: \$allowReview
            showScore: \$showScore
            isPublished: \$isPublished
          ) {
            quiz {
              id
              title
              description
              timeLimit
              isPublished
              allowReview
              showScore
              scheduledStart
              scheduledEnd
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
        'scheduledStart': scheduledStart?.toIso8601String(),
        'scheduledEnd': scheduledEnd?.toIso8601String(),
        'allowReview': allowReview,
        'showScore': showScore,
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
        'choices': choices,
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

      final result = await _graphqlRequest(mutation, variables: {
        'quizId': quizId,
        'answers': answers,
        'timeTaken': timeTaken,
      });

      final submitData = result['submitQuiz'];

      if (submitData['success'] == true) {
        return {
          'success': true,
          'score': submitData['attempt']['score'],
          'total_questions': submitData['attempt']['totalQuestions'],
          'correct_answers': submitData['attempt']['correctAnswers'],
          'percentage': submitData['attempt']['percentage'],
          'status': submitData['attempt']['status'],
          'message': submitData['message'],
        };
      } else {
        return {
          'success': false,
          'message': submitData['message'],
        };
      }
    } catch (e) {
      print('Submit quiz error: $e');
      return {
        'success': false,
        'message': 'Error submitting quiz: $e',
      };
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

  Quiz _getMockQuiz(String quizId) {
    // This mock needs to supply ALL required parameters from your final Quiz model.
    return Quiz(
      id: quizId,
      title: 'Sample Quiz',
      description: 'This is a sample quiz',
      subjectId: '1',
      timeLimit: 30,
      isPublished: true,
      allowReview: true,
      showScore: true,
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
          // Corrected: Removed the unexpected 'quizId' argument here.
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
          ], quizId: '',
        ),
      ],
    );
  }

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

      await saveUserData(user ?? {
        'id': googleId,
        'email': email,
        'firstName': name,
        'role': 'student',
        'profileImage': profileImage,
      });

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