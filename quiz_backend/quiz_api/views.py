from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404
from django.db import transaction
from rest_framework.permissions import AllowAny, IsAuthenticated
from .models import User, Subject, Quiz, Question, Choice, QuizAttempt, Answer
from .serializers import (
    UserSerializer, LoginSerializer, SignupSerializer,
    SubjectSerializer, QuizSerializer, QuizListSerializer, QuestionSerializer,
    QuizAttemptSerializer, SubmitQuizSerializer, ResultSerializer
)
import uuid
from datetime import datetime

class AuthViewSet(viewsets.ViewSet):
    @action(detail=False, methods=['post'])
    def login(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'success': True,
                'token': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserSerializer(user).data
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'])
    def signup(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                'success': True,
                'message': 'User created successfully',
                'user': UserSerializer(user).data
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class QuizViewSet(viewsets.ModelViewSet):
    queryset = Quiz.objects.all()  # Changed from filter(is_published=True)
    serializer_class = QuizSerializer
    permission_classes = [AllowAny]  # Changed for testing]
    def get_serializer_class(self):
        if self.action == 'list':
            return QuizListSerializer
        return QuizSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.role in ['teacher', 'admin']:
            return Quiz.objects.filter(created_by=user)
        return Quiz.objects.filter(is_published=True)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['get'])
    def questions(self, request, pk=None):
        quiz = self.get_object()
        questions = quiz.questions.all()
        serializer = QuestionSerializer(questions, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def submit(self, request, pk=None):
        quiz = get_object_or_404(Quiz, id=pk)
        user = request.user
        serializer = SubmitQuizSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        with transaction.atomic():
            # Create quiz attempt
            attempt = QuizAttempt.objects.create(
                user=user,
                quiz=quiz,
                total_questions=quiz.questions.count()
            )
            
            total_score = 0
            correct_answers = 0
            
            # Process each answer
            for answer_data in serializer.validated_data['answers']:
                question_id = answer_data.get('question_id')
                selected_choice_id = answer_data.get('selected_choice_id')
                answer_text = answer_data.get('answer_text', '')
                
                try:
                    question = Question.objects.get(id=question_id, quiz=quiz)
                    selected_choice = None
                    
                    if selected_choice_id:
                        selected_choice = Choice.objects.get(id=selected_choice_id, question=question)
                    
                    # Check if answer is correct
                    is_correct = False
                    points_earned = 0
                    
                    if question.question_type == 'mcq' and selected_choice:
                        is_correct = selected_choice.is_correct
                    elif question.question_type == 'true_false' and selected_choice:
                        is_correct = selected_choice.is_correct
                    elif question.question_type == 'short_answer':
                        # For short answer, we'll consider it correct if it's not empty
                        is_correct = bool(answer_text.strip())
                    
                    if is_correct:
                        points_earned = question.points
                        total_score += points_earned
                        correct_answers += 1
                    
                    # Create answer record
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
            
            # Update attempt with final score
            attempt.score = total_score
            attempt.correct_answers = correct_answers
            attempt.save()
            
            # Get result with status
            result_serializer = ResultSerializer(attempt)
            
            return Response({
                'success': True,
                'message': 'Quiz submitted successfully',
                'attempt_id': str(attempt.id),
                **result_serializer.data
            })
    
    @action(detail=False, methods=['get'])
    def results(self, request):
        user = request.user
        attempts = QuizAttempt.objects.filter(user=user).order_by('-completed_at')
        serializer = QuizAttemptSerializer(attempts, many=True)
        return Response({
            'success': True,
            'results': serializer.data
        })

class QuestionViewSet(viewsets.ModelViewSet):
    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role in ['teacher', 'admin']:
            return Question.objects.filter(quiz__created_by=user)
        return Question.objects.filter(quiz__is_published=True)
    
    def perform_create(self, serializer):
        quiz_id = self.request.data.get('quiz')
        quiz = get_object_or_404(Quiz, id=quiz_id, created_by=self.request.user)
        serializer.save()

class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]

class SubjectViewSet(viewsets.ModelViewSet):
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)