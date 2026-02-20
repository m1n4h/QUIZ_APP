from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from graphene_django.views import GraphQLView
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.contrib.auth.models import AnonymousUser
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User, Subject, Quiz, Question
from .serializers import UserSerializer, SubjectSerializer, QuizSerializer, QuestionSerializer
import logging

logger = logging.getLogger(__name__)

@method_decorator(csrf_exempt, name='dispatch')
class CustomGraphQLView(GraphQLView):
    """
    Custom GraphQL view that properly handles JWT authentication
    """
    
    def dispatch(self, request, *args, **kwargs):
        # Authenticate the request using JWT
        auth = JWTAuthentication()
        try:
            user_auth_tuple = auth.authenticate(request)
            if user_auth_tuple is not None:
                user, validated_token = user_auth_tuple
                request.user = user
                logger.info(f"GraphQL: User authenticated: {user.email} (role: {user.role})")
            else:
                request.user = AnonymousUser()
                logger.info("GraphQL: No authentication - anonymous user")
        except Exception as e:
            logger.error(f"GraphQL: Authentication failed: {str(e)}")
            request.user = AnonymousUser()
        
        return super().dispatch(request, *args, **kwargs)
    
    def get_context(self, request):
        """
        Override to ensure the authenticated user is available in GraphQL context
        """
        context = super().get_context(request)
        # Make sure the user is available in the context
        context.user = getattr(request, 'user', AnonymousUser())
        logger.info(f"GraphQL Context: User is {context.user} (authenticated: {context.user.is_authenticated})")
        return context

# REST API ViewSets (for backward compatibility)
class AuthViewSet(viewsets.ViewSet):
    """Authentication endpoints"""
    pass

class UserViewSet(viewsets.ModelViewSet):
    """User management endpoints"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

class SubjectViewSet(viewsets.ModelViewSet):
    """Subject management endpoints"""
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer
    permission_classes = [IsAuthenticated]

class QuizViewSet(viewsets.ModelViewSet):
    """Quiz management endpoints"""
    queryset = Quiz.objects.all()
    serializer_class = QuizSerializer
    permission_classes = [IsAuthenticated]

class QuestionViewSet(viewsets.ModelViewSet):
    """Question management endpoints"""
    queryset = Question.objects.all()
    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated]