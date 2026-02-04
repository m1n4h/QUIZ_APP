# quiz_api/middleware.py
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.utils.deprecation import MiddlewareMixin

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
            auth_header = request.META.get('HTTP_AUTHORIZATION')
            print(f"Incoming GraphQL request Authorization header: {auth_header is not None}")
            user_auth_tuple = self.auth.authenticate(request)
            if user_auth_tuple is not None:
                user, validated_token = user_auth_tuple
                request.user = user
                print(f"JWT auth successful for user: {getattr(user, 'email', '<no-email>')}")
            else:
                print("JWT auth: no valid token found or authentication failed")
        except Exception as e:
            # don't raise — leave request.user as-is (AnonymousUser)
            print(f"JWT auth error: {e}")
        response = self.get_response(request)
        return self.get_response(request)