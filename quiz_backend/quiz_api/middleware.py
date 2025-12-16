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
            user_auth_tuple = self.auth.authenticate(request)
            if user_auth_tuple is not None:
                user, validated_token = user_auth_tuple
                request.user = user
        except Exception:
            # don't raise — leave request.user as-is (AnonymousUser)
            pass
        response = self.get_response(request)
        return response