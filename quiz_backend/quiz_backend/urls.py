"""
URL configuration for quiz_backend project.
"""
from django.contrib import admin
from django.urls import path, include
from django.views.decorators.csrf import csrf_exempt
from graphene_django.views import GraphQLView
from quiz_api.schema import schema
from quiz_api.views import CustomGraphQLView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('quiz_api.urls')),
    path('graphql/', csrf_exempt(CustomGraphQLView.as_view(schema=schema, graphiql=True))),
]