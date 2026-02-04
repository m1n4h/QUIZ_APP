
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
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'role', 'profile_image']

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
       # ADD THIS METHOD
    def resolve_choices(self, info):
        """Ensures the choices field always returns a QuerySet (an iterable), 
           even if empty, preventing the 'Expected Iterable' error."""
        # The related_name in your models.py is 'choices'
        return self.choices.all()
    
    
class QuizType(DjangoObjectType):
    questions = graphene.List(QuestionType)
    is_available = graphene.Boolean()
    time_until_start = graphene.Int()
    time_until_end = graphene.Int()
    question_count = graphene.Int()
    
    class Meta:
        model = Quiz
        fields = [
            'id', 'title', 'description', 'time_limit', 'is_published',
            'scheduled_start', 'scheduled_end', 'allow_review', 'show_score',
            'randomize_questions', 'randomize_choices', 'created_by', 'questions'
        ]
    # ADD THIS METHOD
    def resolve_questions(self, info):
        """Ensures the questions field always returns a QuerySet (an iterable), 
           even if empty, preventing the 'Expected Iterable' error."""
        # The related_name in your models.py is 'questions'
        return self.questions.all() 
    
    def resolve_is_available(self, info):
        return self.is_available_now()
# ... (rest of QuizType)

    def resolve_is_available(self, info):
        return self.is_available_now()
    
    def resolve_time_until_start(self, info):
        return self.time_until_start()
    
    def resolve_time_until_end(self, info):
        return self.time_until_end()
    
    def resolve_question_count(self, info):
        return self.questions.count()

class QuizAttemptType(DjangoObjectType):
    quiz_title = graphene.String()
    
    class Meta:
        model = QuizAttempt
        fields = ['id', 'quiz', 'user', 'score', 'total_questions', 'correct_answers', 'percentage', 'status', 'time_taken', 'completed_at']
    
    def resolve_quiz_title(self, info):
        return self.quiz.title

class AnswerType(DjangoObjectType):
    class Meta:
        model = Answer
        fields = ['id', 'question', 'selected_choice', 'answer_text', 'is_correct', 'points_earned']


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
                user=user
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
        user = authenticate(username=email, password=password)
        if user is None:
            return LoginMutation(success=False, message='Invalid credentials')
        
        refresh = RefreshToken.for_user(user)
        return LoginMutation(
            success=True,
            token=str(refresh.access_token),
            refresh=str(refresh),
            user=user
        )

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
        subject_id = graphene.String()  # optional now
        time_limit = graphene.Int()
        scheduled_start = graphene.DateTime()
        scheduled_end = graphene.DateTime()
        allow_review = graphene.Boolean()
        show_score = graphene.Boolean()
    
    quiz = graphene.Field(QuizType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, title, subject_id=None, description='', time_limit=30, 
               scheduled_start=None, scheduled_end=None, allow_review=True, show_score=True):
        # Debug log for incoming mutation
        print(f"CreateQuiz called by user={getattr(info.context.user, 'email', None)} subject_id={subject_id} title={title}")

        if not info.context.user.is_authenticated:
            return CreateQuizMutation(success=False, message='Not authenticated')
        
        if info.context.user.role not in ['teacher', 'admin']:
            return CreateQuizMutation(success=False, message='Only teachers can create quizzes')
        
        try:
            if subject_id:
                try:
                    subject = Subject.objects.get(id=subject_id)
                except Subject.DoesNotExist:
                    return CreateQuizMutation(success=False, message='Subject not found')
            else:
                # Fallback: try to find a subject created by the user, then any subject, else create a default one
                subject = Subject.objects.filter(created_by=info.context.user).first() or Subject.objects.first()
                if subject is None:
                    subject = Subject.objects.create(
                        name='General',
                        description='Auto-created default subject',
                        created_by=info.context.user
                    )
                    print(f"Auto-created default subject with id={subject.id}")

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
            print(f"Quiz created id={quiz.id} title={quiz.title}")
            return CreateQuizMutation(success=True, quiz=quiz)
        except Exception as e:
            print(f"CreateQuiz error: {e}")
            return CreateQuizMutation(success=False, message=str(e))

class UpdateQuizMutation(graphene.Mutation):
    class Arguments:
        quiz_id = graphene.String(required=True)
        title = graphene.String()
        description = graphene.String()
        time_limit = graphene.Int()
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
                    setattr(quiz, key, value)
            
            quiz.save()
            return UpdateQuizMutation(success=True, quiz=quiz)
        except Quiz.DoesNotExist:
            return UpdateQuizMutation(success=False, message='Quiz not found')
        except Exception as e:
            return UpdateQuizMutation(success=False, message=str(e))

class CreateQuestionMutation(graphene.Mutation):
    class Arguments:
        quiz_id = graphene.String(required=True)
        question_text = graphene.String(required=True)
        question_type = graphene.String(required=True)
        points = graphene.Int()
        order = graphene.Int()
        choices = graphene.List(graphene.JSONString)
    
    question = graphene.Field(QuestionType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, quiz_id, question_text, question_type, choices, points=1, order=0):
        if not info.context.user.is_authenticated:
            return CreateQuestionMutation(success=False, message='Not authenticated')
        
        # Check if the user is a teacher or admin
        if info.context.user.role not in ['teacher', 'admin']:
            return CreateQuestionMutation(success=False, message='Only teachers and admins can create questions')
        
        try:
            quiz = Quiz.objects.get(id=quiz_id)
        except Quiz.DoesNotExist:
            return CreateQuestionMutation(success=False, message='Quiz not found')
        
        # If the user is not an admin, check if they are the creator of the quiz
        if info.context.user.role != 'admin' and quiz.created_by != info.context.user:
            return CreateQuestionMutation(success=False, message='You are not the creator of this quiz')
        
        try:
            question = Question.objects.create(
                quiz=quiz,
                question_text=question_text,
                question_type=question_type,
                points=points,
                order=order
            )
            
            for idx, choice_data in enumerate(choices):
                if isinstance(choice_data, str):
                    import json
                    choice_data = json.loads(choice_data)
                Choice.objects.create(
                    question=question,
                    choice_text=choice_data.get('choice_text', ''),
                    is_correct=choice_data.get('is_correct', False),
                    order=choice_data.get('order', idx)
                )
            
            return CreateQuestionMutation(success=True, question=question)
        except Exception as e:
            return CreateQuestionMutation(success=False, message=str(e))

class SubmitQuizMutation(graphene.Mutation):
    class Arguments:
        quiz_id = graphene.String(required=True)
        answers = graphene.List(graphene.JSONString)
        time_taken = graphene.Int()
    
    attempt = graphene.Field(QuizAttemptType)
    success = graphene.Boolean()
    message = graphene.String()
    
    def mutate(self, info, quiz_id, answers, time_taken=0):
        if not info.context.user.is_authenticated:
            return SubmitQuizMutation(success=False, message='Not authenticated')
        
        try:
            from django.db import transaction
            
            quiz = Quiz.objects.get(id=quiz_id)
            
            if not quiz.is_available_now():
                return SubmitQuizMutation(success=False, message='Quiz is not available')
            
            with transaction.atomic():
                attempt = QuizAttempt.objects.create(
                    user=info.context.user,
                    quiz=quiz,
                    total_questions=quiz.questions.count(),
                    time_taken=time_taken
                )
                
                total_score = 0
                correct_answers = 0
                
                for answer_data in answers:
                    if isinstance(answer_data, str):
                        import json
                        answer_data = json.loads(answer_data)
                    
                    question_id = answer_data.get('question_id')
                    selected_choice_id = answer_data.get('selected_choice_id')
                    answer_text = answer_data.get('answer_text', '')
                    
                    try:
                        question = Question.objects.get(id=question_id, quiz=quiz)
                        selected_choice = None
                        is_correct = False
                        points_earned = 0
                        
                        if selected_choice_id:
                            selected_choice = Choice.objects.get(id=selected_choice_id, question=question)
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
                    except (Question.DoesNotExist, Choice.DoesNotExist):
                        continue
                
                attempt.score = total_score
                attempt.correct_answers = correct_answers
                attempt.save()
            
            return SubmitQuizMutation(success=True, attempt=attempt)
        except Exception as e:
            print(f"SubmitQuiz error: {e}")
            return SubmitQuizMutation(success=False, message=str(e))

class Mutation(graphene.ObjectType):
    login = LoginMutation.Field()
    signup = SignupMutation.Field()
    logout = LogoutMutation.Field()
    google_auth = GoogleAuthMutation.Field()   # <-- ADD THIS
    create_quiz = CreateQuizMutation.Field()
    update_quiz = UpdateQuizMutation.Field()
    create_question = CreateQuestionMutation.Field()
    submit_quiz = SubmitQuizMutation.Field()

class Query(graphene.ObjectType):
    all_quizzes = graphene.List(QuizType)
    quiz_detail = graphene.Field(QuizType, id=graphene.String())
    my_quizzes = graphene.List(QuizType)
    available_quizzes = graphene.List(QuizType)
    quiz_results = graphene.List(QuizAttemptType)
    
    def resolve_all_quizzes(self, info):
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
    
    def resolve_quiz_results(self, info):
        if not info.context.user.is_authenticated:
            return []
        return QuizAttempt.objects.filter(user=info.context.user)

schema = graphene.Schema(query=Query, mutation=Mutation)