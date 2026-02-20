from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AuthViewSet, SubjectViewSet, QuizViewSet, 
    QuestionViewSet, UserViewSet
)

router = DefaultRouter()
router.register(r'auth', AuthViewSet, basename='auth')
router.register(r'subjects', SubjectViewSet)
router.register(r'quiz', QuizViewSet)
router.register(r'questions', QuestionViewSet, basename= 'question')
router.register(r'users', UserViewSet, basename= 'user')

urlpatterns = [
    path('', include(router.urls)),
]