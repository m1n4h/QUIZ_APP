// File: lib/models/quiz_model.dart (or your main model file)

import 'dart:convert'; // Just in case

class Quiz {
  final String id;
  final String title;
  final String description;
  
  // DRF fields that may not be in the GraphQL query (made safe/nullable)
  final String? subjectId; // Made nullable as you are not querying it
  final DateTime createdAt; 
  
  // Fields returned by GraphQL (camelCase)
  final int timeLimit;
  final bool isPublished;
  final DateTime? scheduledStart; 
  final DateTime? scheduledEnd;   
  final int timeUntilStart;
  final int timeUntilEnd;
  final int questionCount;
  final bool isAvailable;
  
  // Fields from the nested 'createdBy' object
  final String createdById;
  final String createdByFirstName;
  final String createdByLastName;

  final int attemptsCount;
  final double averageScore;

  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.subjectId,
    required this.timeLimit,
    required this.isPublished,
    required this.createdAt,
    
    // Calculated/Scheduled fields
    this.scheduledStart,
    this.scheduledEnd,
    required this.timeUntilStart,
    required this.timeUntilEnd,
    required this.questionCount,
    required this.isAvailable,

    // Created By fields
    required this.createdById,
    required this.createdByFirstName,
    required this.createdByLastName,
    
    this.attemptsCount = 0,
    this.averageScore = 0.0,
    
    this.questions = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    
    // --- 1. CORE FIELDS & NULL/NAME SAFETY (Using camelCase) ---
    final String id = json['id'] as String? ?? '';
    final String title = json['title'] as String? ?? 'No Title';
    final String description = json['description'] as String? ?? 'No Description';
    final int timeLimit = json['timeLimit'] as int? ?? 0;        
    final bool isPublished = json['isPublished'] as bool? ?? false; 
    
    // The subjectId is not in the GraphQL response, so we must make it null or default it.
    final String? subjectId = json['subjectId'] as String?;

    // --- 2. DATE/TIME FIELD SAFETY ---
    final String? scheduledStartString = json['scheduledStart'];
    final DateTime? scheduledStart = scheduledStartString != null 
        ? DateTime.parse(scheduledStartString) 
        : null;

    final String? scheduledEndString = json['scheduledEnd'];
    final DateTime? scheduledEnd = scheduledEndString != null 
        ? DateTime.parse(scheduledEndString) 
        : null;
        
    // createdAt is not queried, default it to now.
    final DateTime createdAt = (json['createdAt'] as String?) != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(); 

    // --- 3. CALCULATED FIELD SAFETY ---
    final int timeUntilStart = json['timeUntilStart'] as int? ?? 0;
    final int timeUntilEnd = json['timeUntilEnd'] as int? ?? 0;
    final int questionCount = json['questionCount'] as int? ?? 0;
    final bool isAvailable = json['isAvailable'] as bool? ?? false;
    
    // --- 4. NESTED 'CREATED BY' FIELD SAFETY ---
    final Map<String, dynamic> createdBy = json['createdBy'] as Map<String, dynamic>? ?? {};
    final String createdById = createdBy['id'] as String? ?? '';
    final String createdByFirstName = createdBy['firstName'] as String? ?? ''; 
    final String createdByLastName = createdBy['lastName'] as String? ?? '';   

    final int attemptsCount = (json['attempts'] as List?)?.length ?? 0;
    final double averageScore = (json['averageScore'] as num?)?.toDouble() ?? 0.0;

    // --- 5. QUESTIONS LIST SAFETY ---
    final List<Question> questions = (json['questions'] as List?)
        ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList() ?? [];

    return Quiz(
      id: id,
      title: title,
      description: description,
      subjectId: subjectId,
      timeLimit: timeLimit,
      isPublished: isPublished,
      
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      timeUntilStart: timeUntilStart,
      timeUntilEnd: timeUntilEnd,
      questionCount: questionCount,
      isAvailable: isAvailable,
      
      createdById: createdById,
      createdByFirstName: createdByFirstName,
      createdByLastName: createdByLastName,
      
      attemptsCount: attemptsCount,
      averageScore: averageScore,
      
      createdAt: createdAt,

      questions: questions,
    );
  }
}

class Question {
  final String id;
  // Removed quizId
  final String questionText;
  final String questionType;
  final int points;
  final int order;
  final List<Choice> choices;

  Question({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.order,
    this.choices = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    
    final String questionText = json['questionText'] as String? ?? '';
    final String questionType = json['questionType'] as String? ?? 'mcq';
    final int points = json['points'] as int? ?? 1;
    final int order = json['order'] as int? ?? 0;

    final List<Choice> choices = (json['choices'] as List?)
        ?.map((c) => Choice.fromJson(c as Map<String, dynamic>))
        .toList() ?? [];
    
    return Question(
      id: json['id'],
      questionText: questionText,
      questionType: questionType,
      points: points,
      order: order,
      choices: choices,
    );
  }
}

class Choice {
  final String id;
  // Removed questionId
  final String choiceText;
  final bool isCorrect;
  final int order;

  Choice({
    required this.id,
    required this.choiceText,
    required this.isCorrect,
    required this.order,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    
    final String choiceText = json['choiceText'] as String? ?? '';
    final bool isCorrect = json['isCorrect'] as bool? ?? false;
    final int order = json['order'] as int? ?? 0;

    return Choice(
      id: json['id'],
      choiceText: choiceText,
      isCorrect: isCorrect,
      order: order,
    );
  }
}