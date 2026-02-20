from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, Subject, Quiz, Question, Choice, QuizAttempt, Answer
import uuid

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'role', 'profile_image']
        read_only_fields = ['id']
        
class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = ['id', 'name', 'description']  # OR use '__all__'


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, data):
        user = authenticate(username=data['email'], password=data['password'])
        if not user:
            raise serializers.ValidationError("Invalid credentials")
        return {'user': user}

class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    
    class Meta:
        model = User
        fields = ['email', 'username', 'password', 'role', 'first_name', 'last_name']
    
    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            username=validated_data['email'],
            password=validated_data['password'],
            role=validated_data.get('role', 'student'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user

class ChoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Choice
        fields = ['id', 'choice_text', 'order']

class QuestionSerializer(serializers.ModelSerializer):
    choices = ChoiceSerializer(many=True, read_only=True)
    
    class Meta:
        model = Question
        fields = ['id', 'question_text', 'question_type', 'points', 'order', 'choices']

class QuizSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True, read_only=True)
    created_by = UserSerializer(read_only=True)
    
    class Meta:
        model = Quiz
        fields = ['id', 'title', 'description', 'time_limit', 'is_published', 'created_at', 'created_by', 'questions']

class QuizListSerializer(serializers.ModelSerializer):
    question_count = serializers.IntegerField(source='questions.count', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    
    class Meta:
        model = Quiz
        fields = ['id', 'title', 'description', 'question_count', 'time_limit', 'is_published', 'created_at', 'created_by_name']

class QuizAttemptSerializer(serializers.ModelSerializer):
    quiz_title = serializers.CharField(source='quiz.title', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    
    class Meta:
        model = QuizAttempt
        fields = ['id', 'quiz', 'quiz_title', 'user', 'user_name', 'score', 'total_questions', 
                  'correct_answers', 'percentage', 'status', 'time_taken', 'completed_at']

class SubmitAnswerSerializer(serializers.Serializer):
    question_id = serializers.UUIDField()
    selected_choice_id = serializers.UUIDField(required=False, allow_null=True)
    answer_text = serializers.CharField(required=False, allow_blank=True)

class SubmitQuizSerializer(serializers.Serializer):
    answers = SubmitAnswerSerializer(many=True)

class ResultSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizAttempt
        fields = ['score', 'total_questions', 'correct_answers', 'percentage', 'status', 'time_taken', 'completed_at']