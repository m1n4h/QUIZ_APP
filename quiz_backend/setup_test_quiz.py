#!/usr/bin/env python
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'quiz_backend.settings')
django.setup()

from quiz_api.models import User, Subject, Quiz, Question, Choice, QuizAttempt

def clean_and_setup_test_data():
    print("Cleaning up existing test data...")
    
    # Delete existing sample quizzes
    Quiz.objects.filter(title__icontains='sample').delete()
    
    # Get or create users
    try:
        admin_user = User.objects.get(email='admin@test.com')
        teacher_user = User.objects.get(email='teacher@test.com')
        student_user = User.objects.get(email='student@test.com')
    except User.DoesNotExist:
        print("Test users not found. Please run create_test_users.py first.")
        return
    
    # Get or create subject
    math_subject, created = Subject.objects.get_or_create(
        name='Mathematics',
        defaults={
            'description': 'Mathematics quizzes and tests',
            'created_by': admin_user
        }
    )
    
    print("Creating test quiz...")
    
    # Create a proper test quiz
    quiz = Quiz.objects.create(
        title='Basic Math Quiz',
        description='A simple math quiz to test basic arithmetic skills',
        subject=math_subject,
        created_by=teacher_user,
        time_limit=10,  # 10 minutes
        is_published=True,
        allow_review=True,
        show_score=True,
        randomize_questions=False,
        randomize_choices=False
    )
    
    # Create questions with choices
    questions_data = [
        {
            'text': 'What is 2 + 2?',
            'choices': [
                {'text': '3', 'correct': False},
                {'text': '4', 'correct': True},
                {'text': '5', 'correct': False},
                {'text': '6', 'correct': False}
            ]
        },
        {
            'text': 'What is 5 × 3?',
            'choices': [
                {'text': '12', 'correct': False},
                {'text': '15', 'correct': True},
                {'text': '18', 'correct': False},
                {'text': '20', 'correct': False}
            ]
        },
        {
            'text': 'What is 10 ÷ 2?',
            'choices': [
                {'text': '4', 'correct': False},
                {'text': '5', 'correct': True},
                {'text': '6', 'correct': False},
                {'text': '8', 'correct': False}
            ]
        },
        {
            'text': 'What is 7 - 3?',
            'choices': [
                {'text': '3', 'correct': False},
                {'text': '4', 'correct': True},
                {'text': '5', 'correct': False},
                {'text': '10', 'correct': False}
            ]
        },
        {
            'text': 'What is the square root of 16?',
            'choices': [
                {'text': '2', 'correct': False},
                {'text': '4', 'correct': True},
                {'text': '6', 'correct': False},
                {'text': '8', 'correct': False}
            ]
        }
    ]
    
    for i, q_data in enumerate(questions_data):
        question = Question.objects.create(
            quiz=quiz,
            question_text=q_data['text'],
            question_type='mcq',
            points=2,  # 2 points per question
            order=i
        )
        
        for j, choice_data in enumerate(q_data['choices']):
            Choice.objects.create(
                question=question,
                choice_text=choice_data['text'],
                is_correct=choice_data['correct'],
                order=j
            )
    
    print(f"Created quiz '{quiz.title}' with {len(questions_data)} questions")
    print(f"Total possible score: {len(questions_data) * 2} points")
    
    # Clean up any existing quiz attempts for test users
    QuizAttempt.objects.filter(user__email__in=['admin@test.com', 'teacher@test.com', 'student@test.com']).delete()
    print("Cleaned up existing quiz attempts")
    
    print("Test data setup complete!")
    print(f"Quiz ID: {quiz.id}")
    print("You can now test the quiz submission with proper questions and answers.")

if __name__ == '__main__':
    clean_and_setup_test_data()