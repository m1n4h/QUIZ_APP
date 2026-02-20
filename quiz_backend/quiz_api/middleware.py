# quiz_api/middleware.py
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.utils.deprecation import MiddlewareMixin
from django.contrib.auth.models import AnonymousUser
import logging

logger = logging.getLogger(__name__)

class JWTAuthenticationMiddleware(MiddlewareMixin):
    """
    Try to authenticate the incoming request using SimpleJWT.
    If successful, put the user on request.user so GraphQL resolvers (info.context.user)
    see the authenticated user.
    """
    def __init__(self, get_response=None):
        super().__init__(get_response)
        self.auth = JWTAuthentication()

    def __call__(self, request):
        try:
            # Log the authorization header for debugging
            auth_header = request.META.get('HTTP_AUTHORIZATION', '')
            if auth_header:
                logger.info(f"Authorization header found: {auth_header[:20]}...")
            
            user_auth_tuple = self.auth.authenticate(request)
            if user_auth_tuple is not None:
                user, validated_token = user_auth_tuple
                request.user = user
                logger.info(f"User authenticated: {user.email} (role: {user.role})")
            else:
                logger.info("No authentication tuple returned")
                if not hasattr(request, 'user'):
                    request.user = AnonymousUser()
        except Exception as e:
            # Log the exception for debugging
            logger.error(f"JWT Authentication failed: {str(e)}")
            if not hasattr(request, 'user'):
                request.user = AnonymousUser()
        
        response = self.get_response(request)
        return response