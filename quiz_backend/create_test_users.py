#!/usr/bin/env python
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'quiz_backend.settings')
django.setup()

from quiz_api.models import User, Subject

def create_test_users():
    # Create admin user
    try:
        admin_user = User.objects.get(email='admin@test.com')
        print(f"Admin user already exists: {admin_user.email}")
    except User.DoesNotExist:
        admin_user = User.objects.create_user(
            username='admin_user',
            email='admin@test.com',
            password='admin123',
            first_name='Admin',
            last_name='User',
        )
        admin_user.role = 'admin'
        admin_user.is_approved = True
        admin_user.is_staff = True
        admin_user.is_superuser = True
        admin_user.save()
        print(f"Created admin user: {admin_user.email}")

    # Create teacher user
    try:
        teacher_user = User.objects.get(email='teacher@test.com')
        print(f"Teacher user already exists: {teacher_user.email}")
    except User.DoesNotExist:
        teacher_user = User.objects.create_user(
            username='teacher_user',
            email='teacher@test.com',
            password='teacher123',
            first_name='Teacher',
            last_name='User',
        )
        teacher_user.role = 'teacher'
        teacher_user.is_approved = True
        teacher_user.save()
        print(f"Created teacher user: {teacher_user.email}")

    # Create student user
    try:
        student_user = User.objects.get(email='student@test.com')
        print(f"Student user already exists: {student_user.email}")
    except User.DoesNotExist:
        student_user = User.objects.create_user(
            username='student_user',
            email='student@test.com',
            password='student123',
            first_name='Student',
            last_name='User',
        )
        student_user.role = 'student'
        student_user.is_approved = True
        student_user.save()
        print(f"Created student user: {student_user.email}")

    # Create default subjects
    subjects = [
        {'name': 'Mathematics', 'description': 'Math related quizzes'},
        {'name': 'Science', 'description': 'Science related quizzes'},
        {'name': 'History', 'description': 'History related quizzes'},
        {'name': 'English', 'description': 'English language quizzes'},
    ]
    
    for subject_data in subjects:
        subject, created = Subject.objects.get_or_create(
            name=subject_data['name'],
            defaults={
                'description': subject_data['description'],
                'created_by': admin_user,
            }
        )
        if created:
            print(f"Created subject: {subject.name}")
        else:
            print(f"Subject already exists: {subject.name}")

if __name__ == '__main__':
    create_test_users()
    print("Test users and subjects created successfully!")