from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
import uuid

class User(AbstractUser):
    ROLE_CHOICES = (
        ('student', 'Student'),
        ('teacher', 'Teacher'),
        ('admin', 'Admin'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='student')
    is_approved = models.BooleanField(default=False)
    google_id = models.CharField(max_length=255, blank=True, null=True)
    profile_image = models.URLField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []
    
    class Meta:
        ordering = ['-created_at']

class Subject(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='subjects')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['name']

class Quiz(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE, related_name='quizzes')
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quizzes')
    time_limit = models.IntegerField(help_text="Time limit in minutes", default=30)
    is_published = models.BooleanField(default=False)
    
    # New scheduled fields
    scheduled_start = models.DateTimeField(null=True, blank=True, help_text="When quiz becomes available")
    scheduled_end = models.DateTimeField(null=True, blank=True, help_text="When quiz closes")
    allow_review = models.BooleanField(default=True, help_text="Allow students to review answers")
    show_score = models.BooleanField(default=True, help_text="Show score to students")
    randomize_questions = models.BooleanField(default=False)
    randomize_choices = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Quizzes'
    
    def is_available_now(self):
        """Check if quiz is available for students right now"""
        now = timezone.now()
        if self.scheduled_start and now < self.scheduled_start:
            return False
        if self.scheduled_end and now > self.scheduled_end:
            return False
        return self.is_published
    
    def time_until_start(self):
        """Returns minutes until quiz starts, or None if already started"""
        if self.scheduled_start:
            delta = self.scheduled_start - timezone.now()
            return max(0, int(delta.total_seconds() / 60))
        return None
    
    def time_until_end(self):
        """Returns minutes until quiz closes, or None if no end time"""
        if self.scheduled_end:
            delta = self.scheduled_end - timezone.now()
            return max(0, int(delta.total_seconds() / 60))
        return None

class Question(models.Model):
    QUESTION_TYPES = (
        ('mcq', 'Multiple Choice'),
        ('true_false', 'True/False'),
        ('short_answer', 'Short Answer'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='questions')
    question_text = models.TextField()
    question_type = models.CharField(max_length=20, choices=QUESTION_TYPES, default='mcq')
    points = models.IntegerField(default=1)
    order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['order']

class Choice(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='choices')
    choice_text = models.CharField(max_length=500)
    is_correct = models.BooleanField(default=False)
    order = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['order']

class QuizAttempt(models.Model):
    STATUS_CHOICES = (
        ('excellent', 'Excellent'),
        ('very_good', 'Very Good'),
        ('good', 'Good'),
        ('fair', 'Fair'),
        ('poor', 'Poor'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quiz_attempts')
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='attempts')
    score = models.FloatField(default=0)
    total_questions = models.IntegerField(default=0)
    correct_answers = models.IntegerField(default=0)
    percentage = models.FloatField(default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='fair')
    time_taken = models.IntegerField(help_text="Time taken in seconds", default=0)
    completed_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-completed_at']
    
    def calculate_percentage(self):
        if self.total_questions > 0:
            return (self.correct_answers / self.total_questions) * 100
        return 0
    
    def determine_status(self):
        percentage = self.calculate_percentage()
        if percentage >= 90:
            return 'excellent'
        elif percentage >= 80:
            return 'very_good'
        elif percentage >= 70:
            return 'good'
        elif percentage >= 60:
            return 'fair'
        else:
            return 'poor'
    
    def save(self, *args, **kwargs):
        self.percentage = self.calculate_percentage()
        self.status = self.determine_status()
        super().save(*args, **kwargs)

class Answer(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    attempt = models.ForeignKey(QuizAttempt, on_delete=models.CASCADE, related_name='answers')
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    selected_choice = models.ForeignKey(Choice, on_delete=models.SET_NULL, null=True, blank=True)
    answer_text = models.TextField(blank=True)
    is_correct = models.BooleanField(default=False)
    points_earned = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['question__order']