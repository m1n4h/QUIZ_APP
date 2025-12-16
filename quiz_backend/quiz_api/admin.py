from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import (
    User, Subject, Quiz, Question, Choice, QuizAttempt, Answer
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    model = User
    ordering = ('email',)
    list_display = ('email', 'username', 'first_name', 'last_name', 'role', 'is_staff', 'is_superuser')
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active')

    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        (_('Personal info'), {'fields': ('username', 'first_name', 'last_name', 'profile_image', 'google_id')}),
        (_('Permissions'), {'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        (_('Important dates'), {'fields': ('last_login', 'created_at', 'updated_at')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'password1', 'password2', 'role', 'is_staff', 'is_superuser'),
        }),
    )

    search_fields = ('email', 'username', 'first_name', 'last_name')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_by', 'created_at')
    search_fields = ('name', 'description')
    list_filter = ('created_by',)


class ChoiceInline(admin.TabularInline):
    model = Choice
    extra = 0


class QuestionInline(admin.TabularInline):
    model = Question
    extra = 0


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ('short_text', 'quiz', 'question_type', 'points', 'order', 'created_at')
    list_filter = ('question_type',)
    search_fields = ('question_text',)
    inlines = [ChoiceInline]

    def short_text(self, obj):
        return obj.question_text[:75]
    short_text.short_description = 'Question'


@admin.register(Choice)
class ChoiceAdmin(admin.ModelAdmin):
    list_display = ('choice_text_short', 'question', 'is_correct', 'order')
    search_fields = ('choice_text',)
    list_filter = ('is_correct',)

    def choice_text_short(self, obj):
        return obj.choice_text[:100]
    choice_text_short.short_description = 'Choice'


@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ('title', 'subject', 'created_by', 'is_published', 'time_limit', 'scheduled_start', 'scheduled_end', 'created_at')
    search_fields = ('title', 'description')
    list_filter = ('is_published', 'subject', 'created_by')
    inlines = [QuestionInline]
    readonly_fields = ('created_at', 'updated_at')


@admin.register(QuizAttempt)
class QuizAttemptAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'quiz', 'score', 'correct_answers', 'percentage', 'status', 'time_taken', 'completed_at')
    search_fields = ('user__email', 'quiz__title')
    list_filter = ('status', 'quiz')


@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    list_display = ('attempt', 'question', 'selected_choice', 'is_correct', 'points_earned')
    search_fields = ('question__question_text',)
    list_filter = ('is_correct',)