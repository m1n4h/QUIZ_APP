
import urllib.request
import json
from django.conf import settings

import graphene
from graphene_django import DjangoObjectType
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import User, Subject, Quiz, Question, Choice, QuizAttempt, Answer

class UserType(DjangoObjectType):
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'role', 'profile_image', 'is_approved', 'is_active']

class SubjectType(DjangoObjectType):
    class Meta:
        model = Subject
        fields = ['id', 'name', 'description', 'created_by']

class ChoiceType(DjangoObjectType):
    class Meta:
        model = Choice
        fields = ['id', 'choice_text', 'order', 'is_correct']

class QuestionType(DjangoObjectType):
    choices = graphene.List(ChoiceType)
    
    class Meta:
        model = Question
        fields = ['id', 'question_text', 'question_type', 'points', 'order', 'choices']
    
    def resolve_choices(self, info):
        """Ensures the choices field always returns a QuerySet (an iterable), 
           even if empty, preventing the 'Expected Iterable' error."""
        # The related_name in your models.py is 'choices'
        return list(self.choices.all())

class QuizAttemptType(DjangoObjectType):
    quiz_title = graphene.String()
    student_name = graphene.String()
    student_email = graphene.String()
    
    class Meta:
        model = QuizAttempt
        fields = ['id', 'quiz', 'user', 'score', 'total_questions', 'correct_answers', 'percentage', 'status', 'time_taken', 'completed_at']
    
    def resolve_quiz_title(self, info):
        return self.quiz.title
    
    def resolve_student_name(self, info):
        return f"{self.user.first_name} {self.user.last_name}".strip() or self.user.username
    
    def resolve_student_email(self, info):
        return self.user.email

class QuizType(DjangoObjectType):
    questions = graphene.List(QuestionType)
    is_available = graphene.Boolean()
    time_until_start = graphene.Int()
    time_until_end = graphene.Int()
    question_count = graphene.Int()
    attempts = graphene.List(QuizAttemptType)
    average_score = graphene.Float()
    
    class Meta:
        model = Quiz
        fields = [
            'id', 'title', 'description', 'time_limit', 'is_published',
            'scheduled_start', 'scheduled_end', 'allow_review', 'show_score',
            'randomize_questions', 'randomize_choices', 'created_by', 'questions',
            'attempts', 'average_score'
        ]
    
    def resolve_questions(self, info):
        """Ensures the questions field always returns a QuerySet (an iterable), 
           even if empty, preventing the 'Expected Iterable' error."""
        # The related_name in your models.py is 'questions'
        return list(self.questions.all())
    
    def resolve_is_available(self, info):
        return self.is_available_now()
    
    def resolve_time_until_start(self, info):
        result = self.time_until_start()
        return result if result is not None else 0
    
    def resolve_time_until_end(self, info):
        result = self.time_until_end()
        return result if result is not None else 0
    
    def resolve_question_count(self, info):
        return self.questions.count()
    
    def resolve_attempts(self, info):
        return self.attempts.all()
    
    def resolve_average_score(self, info):
        attempts = self.attempts.all()
        if not attempts:
            return 0
        return sum(a.score for a in attempts) / len(attempts)

class AnswerType(DjangoObjectType):
    question_text = graphene.String()
    selected_choice_text = graphene.String()
    correct_choice_text = graphene.String()
    
    class Meta:
        model = Answer
        fields = ['id', 'question', 'selected_choice', 'answer_text', 'is_correct', 'points_earned']
    
    def resolve_question_text(self, info):
        return self.question.question_text
    
    def resolve_selected_choice_text(self, info):
        return self.selected_choice.choice_text if self.selected_choice else None
    
    def resolve_correct_choice_text(self, info):
        correct_choice = self.question.choices.filter(is_correct=True).first()
        return correct_choice.choice_text if correct_choice else None


class QuestionAnalyticsType(graphene.ObjectType):
    question_id = graphene.String()
    question_text = graphene.String()
    total_attempts = graphene.Int()
    correct_attempts = graphene.Int()
    accuracy_percentage = graphene.Float()
    average_time_spent = graphene.Float()
    difficulty_level = graphene.String()


class QuizAnalyticsType(graphene.ObjectType):
    quiz_id = graphene.String()
    quiz_title = graphene.String()
    total_attempts = graphene.Int()
    unique_students = graphene.Int()
    average_score = graphene.Float()
    highest_score = graphene.Float()
    lowest_score = graphene.Float()
    average_completion_time = graphene.Float()
    pass_rate = graphene.Float()
    question_analytics = graphene.List(QuestionAnalyticsType)


class StudentPerformanceType(graphene.ObjectType):
    student_id = graphene.String()
    student_name = graphene.String()
    student_email = graphene.String()
    attempt = graphene.Field(QuizAttemptType)
    answers = graphene.List(AnswerType)
    time_per_question = graphene.List(graphene.Float)


class GoogleAuthMutation(graphene.Mutation):
    class Arguments:
        id_token = graphene.String(required=False)
        access_token = graphene.String(required=False)

    success = graphene.Boolean()
    token = graphene.String()
    refresh = graphene.String()
    user = graphene.Field(UserType)
    message = graphene.String()

    def mutate(self, info, id_token=None, access_token=None):
        if not id_token and not access_token:
            return GoogleAuthMutation(success=False, message="Provide id_token or access_token")

        payload = None
        try:
            if id_token:
                url = f'https://oauth2.googleapis.com/tokeninfo?id_token={id_token}'
                with urllib.request.urlopen(url) as resp:
                    payload = json.load(resp)
                client_id = getattr(settings, 'GOOGLE_CLIENT_ID', None)
                if client_id:
                    aud = payload.get('aud') or payload.get('audience')
                    if aud and aud != client_id:
                        return GoogleAuthMutation(success=False, message='Token audience mismatch')
            else:
                url = f'https://www.googleapis.com/oauth2/v3/userinfo?access_token={access_token}'
                with urllib.request.urlopen(url) as resp:
                    payload = json.load(resp)
        except Exception as e:
            return GoogleAuthMutation(success=False, message=f'Google token verification failed: {str(e)}')

        google_id = payload.get('sub')
        email = payload.get('email')
        picture = payload.get('picture')

        user = None
        if google_id:
            user = User.objects.filter(google_id=google_id).first()
        if not user and email:
            user = User.objects.filter(email=email).first()

        if not user:
            username = (email.split('@')[0] if email else f'google_{(google_id or "")[:8]}')
            try:
                user = User.objects.create_user(
                    username=username,
                    email=email or f'{username}@example.com',
                    password=User.objects.make_random_password()
                )
                user.google_id = google_id
                if picture:
                    user.profile_image = picture
                user.save()
            except Exception as e:
                return GoogleAuthMutation(success=False, message=f'User creation failed: {str(e)}')

        updated = False
        if google_id and not user.google_id:
            user.google_id = google_id
            updated = True
        if picture and not user.profile_image:
            user.profile_image = picture
            updated = True
        if updated:
            user.save()

        try:
            refresh = RefreshToken.for_user(user)
            return GoogleAuthMutation(
                success=True,
                token=str(refresh.access_token),
                refresh=str(refresh),
                user=user,
                message="Authentication successful"
            )
        except Exception as e:
            return GoogleAuthMutation(success=False, message=f'Failed to create JWT: {str(e)}')
        
        
        
        
# Mutations
class LoginMutation(graphene.Mutation):
    class Arguments:
        email = graphene.String(required=True)
        password = graphene.String(required=True)
    
    success = graphene.Boolean()
    token = graphene.String()
    refresh = graphene.String()
    user = graphene.Field(UserType)
    message = graphene.String()
    
    def mutate(self, info, email, password):
        # Directly get user by email and check password
        try:
            user = User.objects.get(email=email)
            
            if user.check_password(password):
                # Check if user account is suspended
                if not user.is_active:
                    return LoginMutation(success=False, message='Your account has been suspended. Please contact an administrator.')
                
                # Check if teacher needs approval
                if user.role == 'teacher' and not user.is_approved:
                    return LoginMutation(success=False, message='Your account is pending admin approval.')
                
                # If all checks pass, generate token
                refresh = RefreshToken.for_user(user)
                return LoginMutation(
                    success=True,
                    token=str(refresh.access_token),
                    refresh=str(refresh),
                    user=user
                )
            else:
                return LoginMutation(success=False, message='Invalid credentials')
        except User.DoesNotExist:
            return LoginMutation(success=False, message='Invalid credentials')

class SignupMutation(graphene.Mutation):
    class Arguments:
        email = graphene.String(required=True)
        password = graphene.String(required=True)
        username = graphene.String(required=True)
        first_name = graphene.String()
        last_name = graphene.String()
        role = graphene.String()

    success = graphene.Boolean()
    message = graphene.String()
    user = graphene.Field(UserType)

    def mutate(self, info, email, password, username, first_name='', last_name='', role='student'):
        if User.objects.filter(email=email).exists():
            return SignupMutation(success=False, message='Email already exists')

        try:
            user = User.objects.create_user(username=username, email=email, password=password,
                                            first_name=first_name, last_name=last_name)
            user.role = role or 'student'
            # Auto-approve students and admins, only teachers need manual approval
            if user.role in ['student', 'admin']:
                user.is_approved = True
            user.save()
            return SignupMutation(success=True, user=user, message='User created')
        except Exception as e:
            return SignupMutation(success=False, message=str(e))

class LogoutMutation(graphene.Mutation):
    success = graphene.Boolean()
    message = graphene.String()

    def mutate(self, info):
        return LogoutMutation(success=True, message='Logged out')

class CreateQuizMutation(graphene.Mutation):
    class Arguments:
        title = graphene.String(required=True)
        description = graphene.String()
        subject_id = graphene.String()
        time_limit = graphene.Int()
        scheduled_start = graphene.DateTime()
        scheduled_end = graphene.DateTime()
        allow_review = graphene.Boolean()
        show_score = graphene.Boolean()
    
    quiz = graphene.Field(QuizType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, title, description='', subject_id=None, time_limit=30, 
               scheduled_start=None, scheduled_end=None, allow_review=True, show_score=True):
        if not info.context.user.is_authenticated:
            return CreateQuizMutation(success=False, message='Not authenticated')
        
        if info.context.user.role not in ['teacher', 'admin']:
            return CreateQuizMutation(success=False, message='Only teachers can create quizzes')
        
        try:
            # If no subject_id provided, use a default subject or create one
            if subject_id:
                subject = Subject.objects.get(id=subject_id)
            else:
                # Create or get a default subject
                subject, created = Subject.objects.get_or_create(
                    name='General',
                    defaults={'description': 'Default subject for quizzes'}
                )
            
            quiz = Quiz.objects.create(
                title=title,
                description=description,
                subject=subject,
                created_by=info.context.user,
                time_limit=time_limit,
                scheduled_start=scheduled_start,
                scheduled_end=scheduled_end,
                allow_review=allow_review,
                show_score=show_score
            )
            return CreateQuizMutation(success=True, quiz=quiz)
        except Exception as e:
            return CreateQuizMutation(success=False, message=str(e))

class UpdateQuizMutation(graphene.Mutation):
    class Arguments:
        quiz_id = graphene.String(required=True)
        title = graphene.String()
        description = graphene.String()
        time_limit = graphene.Int()
        subject_id = graphene.String()
        scheduled_start = graphene.DateTime()
        scheduled_end = graphene.DateTime()
        allow_review = graphene.Boolean()
        show_score = graphene.Boolean()
        is_published = graphene.Boolean()
    
    quiz = graphene.Field(QuizType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, quiz_id, **kwargs):
        if not info.context.user.is_authenticated:
            return UpdateQuizMutation(success=False, message='Not authenticated')
        
        try:
            quiz = Quiz.objects.get(id=quiz_id, created_by=info.context.user)
            
            for key, value in kwargs.items():
                if value is not None:
                    if key == 'subject_id':
                        # Handle subject assignment
                        subject = Subject.objects.get(id=value)
                        quiz.subject = subject
                    else:
                        setattr(quiz, key, value)
            
            quiz.save()
            return UpdateQuizMutation(success=True, quiz=quiz)
        except Quiz.DoesNotExist:
            return UpdateQuizMutation(success=False, message='Quiz not found')
        except Subject.DoesNotExist:
            return UpdateQuizMutation(success=False, message='Subject not found')
        except Exception as e:
            return UpdateQuizMutation(success=False, message=str(e))

class CreateQuestionMutation(graphene.Mutation):
    class Arguments:
        quiz_id = graphene.String(required=True)
        question_text = graphene.String(required=True)
        question_type = graphene.String(required=True)
        points = graphene.Int()
        order = graphene.Int()
        choices = graphene.List(graphene.types.json.JSONString)
    
    question = graphene.Field(QuestionType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, quiz_id, question_text, question_type, choices, points=1, order=0):
        if not info.context.user.is_authenticated:
            return CreateQuestionMutation(success=False, message='Not authenticated')
        
        try:
            quiz = Quiz.objects.get(id=quiz_id, created_by=info.context.user)
            question = Question.objects.create(
                quiz=quiz,
                question_text=question_text,
                question_type=question_type,
                points=points,
                order=order
            )
            
            import json
            for idx, choice_data in enumerate(choices):
                # Handle both string and dict formats
                if isinstance(choice_data, str):
                    choice_data = json.loads(choice_data)
                elif isinstance(choice_data, dict):
                    # Already a dict, use as is
                    pass
                else:
                    # Convert to dict if needed
                    choice_data = dict(choice_data)
                
                Choice.objects.create(
                    question=question,
                    choice_text=choice_data.get('text', ''),
                    is_correct=choice_data.get('isCorrect', False),
                    order=idx
                )
            
            return CreateQuestionMutation(success=True, question=question)
        except Quiz.DoesNotExist:
            return CreateQuestionMutation(success=False, message='Quiz not found')
        except Exception as e:
            return CreateQuestionMutation(success=False, message=str(e))

class UpdateQuestionMutation(graphene.Mutation):
    class Arguments:
        question_id = graphene.String(required=True)
        question_text = graphene.String()
        question_type = graphene.String()
        points = graphene.Int()
        order = graphene.Int()
        choices = graphene.List(graphene.types.json.JSONString)
    
    question = graphene.Field(QuestionType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, question_id, **kwargs):
        if not info.context.user.is_authenticated:
            return UpdateQuestionMutation(success=False, message='Not authenticated')
        
        try:
            question = Question.objects.get(id=question_id, quiz__created_by=info.context.user)
            
            choices_data = kwargs.pop('choices', None)
            
            for key, value in kwargs.items():
                if value is not None:
                    setattr(question, key, value)
            
            question.save()
            
            if choices_data is not None:
                # For simplicity, we'll replace all choices
                question.choices.all().delete()
                import json
                for idx, choice_data in enumerate(choices_data):
                    # Handle both string and dict formats
                    if isinstance(choice_data, str):
                        choice_data = json.loads(choice_data)
                    elif isinstance(choice_data, dict):
                        # Already a dict, use as is
                        pass
                    else:
                        # Convert to dict if needed
                        choice_data = dict(choice_data)
                    
                    Choice.objects.create(
                        question=question,
                        choice_text=choice_data.get('text', ''),
                        is_correct=choice_data.get('isCorrect', False),
                        order=idx
                    )
            
            return UpdateQuestionMutation(success=True, question=question)
        except Question.DoesNotExist:
            return UpdateQuestionMutation(success=False, message='Question not found')
        except Exception as e:
            return UpdateQuestionMutation(success=False, message=str(e))

class DeleteQuizMutation(graphene.Mutation):
    class Arguments:
        quiz_id = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, quiz_id):
        if not info.context.user.is_authenticated:
            return DeleteQuizMutation(success=False, message='Not authenticated')
        
        try:
            quiz = Quiz.objects.get(id=quiz_id, created_by=info.context.user)
            quiz.delete()
            return DeleteQuizMutation(success=True, message='Quiz deleted successfully')
        except Quiz.DoesNotExist:
            return DeleteQuizMutation(success=False, message='Quiz not found')
        except Exception as e:
            return DeleteQuizMutation(success=False, message=str(e))

class DeleteQuestionMutation(graphene.Mutation):
    class Arguments:
        question_id = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, question_id):
        if not info.context.user.is_authenticated:
            return DeleteQuestionMutation(success=False, message='Not authenticated')
        
        try:
            question = Question.objects.get(id=question_id, quiz__created_by=info.context.user)
            question.delete()
            return DeleteQuestionMutation(success=True, message='Question deleted successfully')
        except Question.DoesNotExist:
            return DeleteQuestionMutation(success=False, message='Question not found')
        except Exception as e:
            return DeleteQuestionMutation(success=False, message=str(e))

class SubmitQuizMutation(graphene.Mutation):
    class Arguments:
        quiz_id = graphene.String(required=True)
        answers = graphene.List(graphene.types.json.JSONString)
        time_taken = graphene.Int()
    
    attempt = graphene.Field(QuizAttemptType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, quiz_id, answers, time_taken=0):
        if not info.context.user.is_authenticated:
            return SubmitQuizMutation(success=False, message='Not authenticated')
        
        try:
            import json
            
            quiz = Quiz.objects.get(id=quiz_id)
            
            if not quiz.is_available_now():
                return SubmitQuizMutation(success=False, message='Quiz is not available')
            
            attempt = QuizAttempt.objects.create(
                user=info.context.user,
                quiz=quiz,
                total_questions=quiz.questions.count(),
                time_taken=time_taken
            )
            
            total_score = 0
            correct_answers = 0
            
            # Handle answers - they can be JSON strings or already parsed dicts
            for answer_item in answers:
                try:
                    # Try to parse as JSON string first
                    if isinstance(answer_item, str):
                        answer_data = json.loads(answer_item)
                    else:
                        # Already a dict
                        answer_data = answer_item
                    
                    question_id = answer_data.get('questionId')
                    selected_choice_id = answer_data.get('choiceId')
                    answer_text = answer_data.get('answer_text', '')
                    
                    if not question_id:
                        continue
                    
                    question = Question.objects.get(id=question_id, quiz=quiz)
                    selected_choice = None
                    is_correct = False
                    points_earned = 0
                    
                    if selected_choice_id:
                        selected_choice = Choice.objects.get(id=selected_choice_id)
                        is_correct = selected_choice.is_correct
                    
                    if is_correct:
                        points_earned = question.points
                        total_score += points_earned
                        correct_answers += 1
                    
                    Answer.objects.create(
                        attempt=attempt,
                        question=question,
                        selected_choice=selected_choice,
                        answer_text=answer_text,
                        is_correct=is_correct,
                        points_earned=points_earned
                    )
                except Question.DoesNotExist:
                    print(f"Question {question_id} not found in quiz {quiz_id}")
                    continue
                except Choice.DoesNotExist:
                    print(f"Choice {selected_choice_id} not found")
                    continue
                except Exception as e:
                    print(f"Error processing answer: {e}")
                    continue
            
            attempt.score = total_score
            attempt.correct_answers = correct_answers
            attempt.save()  # This will auto-calculate percentage and status
            
            return SubmitQuizMutation(success=True, attempt=attempt, message='Quiz submitted successfully')
        except Quiz.DoesNotExist:
            return SubmitQuizMutation(success=False, message='Quiz not found')
        except Exception as e:
            print(f"Submit quiz error: {e}")
            import traceback
            traceback.print_exc()
            return SubmitQuizMutation(success=False, message=f'Error: {str(e)}')

class UpdateUserRoleMutation(graphene.Mutation):
    class Arguments:
        user_id = graphene.String(required=True)
        role = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    user = graphene.Field(UserType)
    
    def mutate(self, info, user_id, role):
        if not info.context.user.is_authenticated:
            return UpdateUserRoleMutation(success=False, message='Not authenticated')
        
        # Only admins can update user roles
        if info.context.user.role != 'admin':
            return UpdateUserRoleMutation(success=False, message='Only admins can update user roles')
        
        try:
            user = User.objects.get(id=user_id)
            user.role = role
            user.save()
            return UpdateUserRoleMutation(success=True, user=user, message='User role updated successfully')
        except User.DoesNotExist:
            return UpdateUserRoleMutation(success=False, message='User not found')
        except Exception as e:
            return UpdateUserRoleMutation(success=False, message=str(e))

class UpdateUserApprovalMutation(graphene.Mutation):
    class Arguments:
        user_id = graphene.String(required=True)
        is_approved = graphene.Boolean(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    user = graphene.Field(UserType)
    
    def mutate(self, info, user_id, is_approved):
        if not info.context.user.is_authenticated:
            return UpdateUserApprovalMutation(success=False, message='Not authenticated')
        
        if info.context.user.role != 'admin':
            return UpdateUserApprovalMutation(success=False, message='Only admins can approve users')
        
        try:
            user = User.objects.get(id=user_id)
            user.is_approved = is_approved
            user.save()
            return UpdateUserApprovalMutation(success=True, user=user, message='User approval status updated')
        except User.DoesNotExist:
            return UpdateUserApprovalMutation(success=False, message='User not found')
        except Exception as e:
            return UpdateUserApprovalMutation(success=False, message=str(e))

class DeleteUserMutation(graphene.Mutation):
    class Arguments:
        user_id = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, user_id):
        if not info.context.user.is_authenticated:
            return DeleteUserMutation(success=False, message='Not authenticated')
        
        if info.context.user.role != 'admin':
            return DeleteUserMutation(success=False, message='Only admins can delete users')
        
        try:
            user = User.objects.get(id=user_id)
            if user.role == 'admin' and User.objects.filter(role='admin').count() <= 1:
                return DeleteUserMutation(success=False, message='Cannot delete the last admin user')
            
            user.delete()
            return DeleteUserMutation(success=True, message='User deleted successfully')
        except User.DoesNotExist:
            return DeleteUserMutation(success=False, message='User not found')
        except Exception as e:
            return DeleteUserMutation(success=False, message=str(e))

class SuspendUserMutation(graphene.Mutation):
    class Arguments:
        user_id = graphene.String(required=True)
        is_suspended = graphene.Boolean(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    user = graphene.Field(UserType)
    
    def mutate(self, info, user_id, is_suspended):
        if not info.context.user.is_authenticated:
            return SuspendUserMutation(success=False, message='Not authenticated')
        
        if info.context.user.role != 'admin':
            return SuspendUserMutation(success=False, message='Only admins can suspend users')
        
        try:
            user = User.objects.get(id=user_id)
            # We'll use is_active field for suspension
            user.is_active = not is_suspended
            user.save()
            
            status = 'suspended' if is_suspended else 'activated'
            return SuspendUserMutation(success=True, user=user, message=f'User {status} successfully')
        except User.DoesNotExist:
            return SuspendUserMutation(success=False, message='User not found')
        except Exception as e:
            return SuspendUserMutation(success=False, message=str(e))

class CreateSubjectMutation(graphene.Mutation):
    class Arguments:
        name = graphene.String(required=True)
        description = graphene.String()
    
    subject = graphene.Field(SubjectType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, name, description=''):
        if not info.context.user.is_authenticated:
            return CreateSubjectMutation(success=False, message='Not authenticated')
        
        # Allow both teachers and admins to create subjects
        if info.context.user.role not in ['teacher', 'admin']:
            return CreateSubjectMutation(success=False, message='Only teachers and admins can create subjects')
        
        try:
            subject = Subject.objects.create(
                name=name,
                description=description,
                created_by=info.context.user
            )
            return CreateSubjectMutation(success=True, subject=subject)
        except Exception as e:
            return CreateSubjectMutation(success=False, message=str(e))

class UpdateSubjectMutation(graphene.Mutation):
    class Arguments:
        subject_id = graphene.String(required=True)
        name = graphene.String(required=True)
        description = graphene.String()
    
    subject = graphene.Field(SubjectType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, subject_id, name, description=''):
        if not info.context.user.is_authenticated:
            return UpdateSubjectMutation(success=False, message='Not authenticated')
        
        # Only admins can update subjects
        if info.context.user.role != 'admin':
            return UpdateSubjectMutation(success=False, message='Only admins can update subjects')
        
        try:
            subject = Subject.objects.get(id=subject_id)
            subject.name = name
            subject.description = description
            subject.save()
            return UpdateSubjectMutation(success=True, subject=subject, message='Subject updated successfully')
        except Subject.DoesNotExist:
            return UpdateSubjectMutation(success=False, message='Subject not found')
        except Exception as e:
            return UpdateSubjectMutation(success=False, message=str(e))

class DeleteSubjectMutation(graphene.Mutation):
    class Arguments:
        subject_id = graphene.String(required=True)
    
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, subject_id):
        if not info.context.user.is_authenticated:
            return DeleteSubjectMutation(success=False, message='Not authenticated')
        
        # Only admins can delete subjects
        if info.context.user.role != 'admin':
            return DeleteSubjectMutation(success=False, message='Only admins can delete subjects')
        
        try:
            subject = Subject.objects.get(id=subject_id)
            
            # Check if subject is being used by any quizzes
            if subject.quiz_set.exists():
                return DeleteSubjectMutation(success=False, message='Cannot delete subject that is being used by quizzes')
            
            subject.delete()
            return DeleteSubjectMutation(success=True, message='Subject deleted successfully')
        except Subject.DoesNotExist:
            return DeleteSubjectMutation(success=False, message='Subject not found')
        except Exception as e:
            return DeleteSubjectMutation(success=False, message=str(e))

class UpdateProfileMutation(graphene.Mutation):
    class Arguments:
        first_name = graphene.String(required=True)
        last_name = graphene.String(required=True)
        email = graphene.String(required=True)

    success = graphene.Boolean()
    message = graphene.String()
    user = graphene.Field(UserType)

    def mutate(self, info, first_name, last_name, email):
        if not info.context.user.is_authenticated:
            return UpdateProfileMutation(success=False, message='Authentication required')
        
        try:
            user = info.context.user
            
            # Check if email is already taken by another user
            if User.objects.filter(email=email).exclude(id=user.id).exists():
                return UpdateProfileMutation(success=False, message='Email already exists')
            
            # Update user profile
            user.first_name = first_name
            user.last_name = last_name
            user.email = email
            user.save()
            
            return UpdateProfileMutation(success=True, message='Profile updated successfully', user=user)
        except Exception as e:
            return UpdateProfileMutation(success=False, message=str(e))

class ChangePasswordMutation(graphene.Mutation):
    class Arguments:
        current_password = graphene.String(required=True)
        new_password = graphene.String(required=True)

    success = graphene.Boolean()
    message = graphene.String()

    def mutate(self, info, current_password, new_password):
        if not info.context.user.is_authenticated:
            return ChangePasswordMutation(success=False, message='Authentication required')
        
        try:
            user = info.context.user
            
            # Check current password
            if not user.check_password(current_password):
                return ChangePasswordMutation(success=False, message='Current password is incorrect')
            
            # Validate new password
            if len(new_password) < 6:
                return ChangePasswordMutation(success=False, message='New password must be at least 6 characters')
            
            # Set new password
            user.set_password(new_password)
            user.save()
            
            return ChangePasswordMutation(success=True, message='Password changed successfully')
        except Exception as e:
            return ChangePasswordMutation(success=False, message=str(e))

class Mutation(graphene.ObjectType):
    login = LoginMutation.Field()
    signup = SignupMutation.Field()
    logout = LogoutMutation.Field()
    google_auth = GoogleAuthMutation.Field()
    create_quiz = CreateQuizMutation.Field()
    update_quiz = UpdateQuizMutation.Field()
    create_question = CreateQuestionMutation.Field()
    update_question = UpdateQuestionMutation.Field()
    delete_quiz = DeleteQuizMutation.Field()
    delete_question = DeleteQuestionMutation.Field()
    submit_quiz = SubmitQuizMutation.Field()
    update_user_role = UpdateUserRoleMutation.Field()
    update_user_approval = UpdateUserApprovalMutation.Field()
    delete_user = DeleteUserMutation.Field()
    suspend_user = SuspendUserMutation.Field()
    create_subject = CreateSubjectMutation.Field()
    update_subject = UpdateSubjectMutation.Field()
    delete_subject = DeleteSubjectMutation.Field()
    update_profile = UpdateProfileMutation.Field()
    change_password = ChangePasswordMutation.Field()

class Query(graphene.ObjectType):
    all_quizzes = graphene.List(QuizType)
    all_users = graphene.List(UserType)
    quiz_detail = graphene.Field(QuizType, id=graphene.String())
    my_quizzes = graphene.List(QuizType)
    available_quizzes = graphene.List(QuizType)
    quiz_results = graphene.List(QuizAttemptType)
    all_subjects = graphene.List(SubjectType)
    user_profile = graphene.Field(UserType)
    
    # New teacher analytics queries
    quiz_attempts = graphene.List(QuizAttemptType, quiz_id=graphene.String(required=True))
    quiz_analytics = graphene.Field(QuizAnalyticsType, quiz_id=graphene.String(required=True))
    student_performance = graphene.Field(StudentPerformanceType, quiz_id=graphene.String(required=True), user_id=graphene.String(required=True))
    
    def resolve_all_quizzes(self, info):
        if not info.context.user.is_authenticated:
            return []
        # Allow admins to see all quizzes, others see only published ones
        if info.context.user.role == 'admin':
            return Quiz.objects.all()
        return Quiz.objects.filter(is_published=True)
    
    def resolve_quiz_detail(self, info, id):
        return Quiz.objects.get(id=id)
    
    def resolve_my_quizzes(self, info):
        if not info.context.user.is_authenticated:
            return []
        if info.context.user.role in ['teacher', 'admin']:
            return Quiz.objects.filter(created_by=info.context.user)
        return []
    
    def resolve_available_quizzes(self, info):
        quizzes = Quiz.objects.filter(is_published=True)
        return [q for q in quizzes if q.is_available_now()]
    
    def resolve_all_users(self, info):
        if not info.context.user.is_authenticated:
            return []
        # Only admins can see all users
        if info.context.user.role == 'admin':
            return User.objects.all()
        return []
    
    def resolve_quiz_results(self, info):
        if not info.context.user.is_authenticated:
            return []
        return QuizAttempt.objects.filter(user=info.context.user)
    
    def resolve_user_profile(self, info):
        if not info.context.user.is_authenticated:
            return None
        return info.context.user
    
    def resolve_all_subjects(self, info):
        return Subject.objects.all()
    
    # New teacher analytics resolvers
    def resolve_quiz_attempts(self, info, quiz_id):
        if not info.context.user.is_authenticated:
            return []
        
        # Only allow teachers to see attempts for their own quizzes, or admins to see all
        try:
            quiz = Quiz.objects.get(id=quiz_id)
            if info.context.user.role == 'admin' or quiz.created_by == info.context.user:
                return QuizAttempt.objects.filter(quiz=quiz).select_related('user', 'quiz')
            return []
        except Quiz.DoesNotExist:
            return []
    
    def resolve_quiz_analytics(self, info, quiz_id):
        if not info.context.user.is_authenticated:
            return None
        
        try:
            quiz = Quiz.objects.get(id=quiz_id)
            if info.context.user.role != 'admin' and quiz.created_by != info.context.user:
                return None
            
            attempts = QuizAttempt.objects.filter(quiz=quiz)
            if not attempts.exists():
                return QuizAnalyticsType(
                    quiz_id=quiz_id,
                    quiz_title=quiz.title,
                    total_attempts=0,
                    unique_students=0,
                    average_score=0,
                    highest_score=0,
                    lowest_score=0,
                    average_completion_time=0,
                    pass_rate=0,
                    question_analytics=[]
                )
            
            # Calculate basic stats
            scores = [attempt.score for attempt in attempts]
            completion_times = [attempt.time_taken for attempt in attempts if attempt.time_taken > 0]
            pass_count = attempts.filter(percentage__gte=60).count()
            
            # Question analytics
            question_analytics = []
            for question in quiz.questions.all():
                answers = Answer.objects.filter(question=question, attempt__quiz=quiz)
                total_answers = answers.count()
                correct_answers = answers.filter(is_correct=True).count()
                
                if total_answers > 0:
                    accuracy = (correct_answers / total_answers) * 100
                    difficulty = 'Easy' if accuracy >= 80 else 'Medium' if accuracy >= 60 else 'Hard'
                    
                    question_analytics.append(QuestionAnalyticsType(
                        question_id=str(question.id),
                        question_text=question.question_text,
                        total_attempts=total_answers,
                        correct_attempts=correct_answers,
                        accuracy_percentage=accuracy,
                        average_time_spent=0,  # Can be calculated if we track time per question
                        difficulty_level=difficulty
                    ))
            
            return QuizAnalyticsType(
                quiz_id=quiz_id,
                quiz_title=quiz.title,
                total_attempts=attempts.count(),
                unique_students=attempts.values('user').distinct().count(),
                average_score=sum(scores) / len(scores) if scores else 0,
                highest_score=max(scores) if scores else 0,
                lowest_score=min(scores) if scores else 0,
                average_completion_time=sum(completion_times) / len(completion_times) if completion_times else 0,
                pass_rate=(pass_count / attempts.count()) * 100 if attempts.count() > 0 else 0,
                question_analytics=question_analytics
            )
            
        except Quiz.DoesNotExist:
            return None
    
    def resolve_student_performance(self, info, quiz_id, user_id):
        if not info.context.user.is_authenticated:
            return None
        
        try:
            quiz = Quiz.objects.get(id=quiz_id)
            if info.context.user.role != 'admin' and quiz.created_by != info.context.user:
                return None
            
            attempt = QuizAttempt.objects.filter(quiz=quiz, user_id=user_id).first()
            if not attempt:
                return None
            
            answers = Answer.objects.filter(attempt=attempt).select_related('question', 'selected_choice')
            
            return StudentPerformanceType(
                student_id=user_id,
                student_name=f"{attempt.user.first_name} {attempt.user.last_name}".strip() or attempt.user.username,
                student_email=attempt.user.email,
                attempt=attempt,
                answers=list(answers),
                time_per_question=[]  # Can be implemented if we track time per question
            )
            
        except Quiz.DoesNotExist:
            return None

schema = graphene.Schema(query=Query, mutation=Mutation)