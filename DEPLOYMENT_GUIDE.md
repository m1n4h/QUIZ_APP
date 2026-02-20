# 🚀 Quiz Application Deployment Guide

## 📋 Prerequisites

### System Requirements
- **Python**: 3.8+ with pip
- **Flutter**: 3.0+ with web support enabled
- **Node.js**: 16+ (for build tools)
- **Git**: For version control
- **Web Browser**: Chrome, Firefox, Safari, or Edge

### Development Environment Setup
```bash
# Python virtual environment
python -m venv quiz_env
source quiz_env/bin/activate  # Linux/Mac
# or
quiz_env\Scripts\activate     # Windows

# Install Python dependencies
cd quiz_backend
pip install -r requirements.txt

# Flutter setup
flutter doctor
flutter config --enable-web
cd ../quiz_mobile
flutter pub get
```

## 🏗️ Local Development Deployment

### 1. Backend Setup (Django)
```bash
cd quiz_backend

# Database setup
python manage.py makemigrations
python manage.py migrate

# Create test data
python create_test_users.py
python setup_test_quiz.py

# Start development server
python manage.py runserver 0.0.0.0:8000
```

**Backend will be available at**: `http://localhost:8000`
- GraphQL Playground: `http://localhost:8000/graphql/`
- Admin Panel: `http://localhost:8000/admin/`

### 2. Frontend Setup (Flutter Web)
```bash
cd quiz_mobile

# Build and serve
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

**Frontend will be available at**: `http://localhost:8080`

### 3. Test Accounts
```
Admin:
- Email: admin@test.com
- Password: admin123

Teacher:
- Email: teacher@test.com  
- Password: teacher123

Student:
- Email: student@test.com
- Password: student123
```

## 🌐 Production Deployment

### Option 1: Traditional Server Deployment

#### Backend (Django + Gunicorn + Nginx)
```bash
# Install production dependencies
pip install gunicorn psycopg2-binary

# Update settings for production
# quiz_backend/quiz_backend/settings_prod.py
DEBUG = False
ALLOWED_HOSTS = ['your-domain.com', 'www.your-domain.com']

# Database (PostgreSQL)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'quiz_db',
        'USER': 'quiz_user',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# Static files
STATIC_ROOT = '/var/www/quiz_backend/static/'
MEDIA_ROOT = '/var/www/quiz_backend/media/'

# Start with Gunicorn
gunicorn --bind 0.0.0.0:8000 quiz_backend.wsgi:application
```

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location /static/ {
        alias /var/www/quiz_backend/static/;
    }

    location /media/ {
        alias /var/www/quiz_backend/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Frontend (Flutter Web Build)
```bash
cd quiz_mobile

# Build for production
flutter build web --release

# Deploy to web server
cp -r build/web/* /var/www/quiz_frontend/
```

### Option 2: Docker Deployment

#### Dockerfile (Backend)
```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "quiz_backend.wsgi:application"]
```

#### Dockerfile (Frontend)
```dockerfile
FROM nginx:alpine

COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
```

#### Docker Compose
```yaml
version: '3.8'

services:
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: quiz_db
      POSTGRES_USER: quiz_user
      POSTGRES_PASSWORD: quiz_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backend:
    build: ./quiz_backend
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgresql://quiz_user:quiz_password@db:5432/quiz_db

  frontend:
    build: ./quiz_mobile
    ports:
      - "80:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

### Option 3: Cloud Deployment (AWS/GCP/Azure)

#### AWS Deployment
```bash
# Using AWS Elastic Beanstalk
eb init quiz-app
eb create quiz-production
eb deploy

# Using AWS ECS with Fargate
aws ecs create-cluster --cluster-name quiz-cluster
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs create-service --cluster quiz-cluster --service-name quiz-service
```

#### Heroku Deployment
```bash
# Backend
heroku create quiz-backend-app
heroku addons:create heroku-postgresql:hobby-dev
git push heroku main

# Frontend (Netlify/Vercel)
flutter build web
# Upload build/web to Netlify or Vercel
```

## 🔧 Environment Configuration

### Backend Environment Variables
```bash
# .env file
SECRET_KEY=your-secret-key-here
DEBUG=False
DATABASE_URL=postgresql://user:password@host:port/dbname
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com

# JWT Settings
JWT_SECRET_KEY=your-jwt-secret
JWT_ACCESS_TOKEN_LIFETIME=7  # days
JWT_REFRESH_TOKEN_LIFETIME=30  # days

# Email Settings (for notifications)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### Frontend Environment Configuration
```dart
// lib/config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const String graphqlEndpoint = '$apiBaseUrl/graphql/';
  static const bool isProduction = bool.fromEnvironment('PRODUCTION');
}
```

## 📊 Monitoring & Analytics

### Backend Monitoring
```python
# settings.py - Add logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'quiz_app.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
        'quiz_api': {
            'handlers': ['file', 'console'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}

# Add Django Debug Toolbar for development
if DEBUG:
    INSTALLED_APPS += ['debug_toolbar']
    MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']
```

### Performance Monitoring
```python
# Install and configure
pip install django-silk sentry-sdk

# Add to settings.py
INSTALLED_APPS += ['silk']
MIDDLEWARE += ['silk.middleware.SilkyMiddleware']

# Sentry for error tracking
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[DjangoIntegration()],
    traces_sample_rate=1.0,
)
```

## 🔒 Security Hardening

### Backend Security
```python
# settings.py - Security settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# HTTPS redirect
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Rate limiting
INSTALLED_APPS += ['django_ratelimit']
```

### Frontend Security
```dart
// lib/services/security_service.dart
class SecurityService {
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>&"\'`]'), ''); // Remove dangerous chars
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

## 📈 Performance Optimization

### Database Optimization
```python
# models.py - Add indexes
class Quiz(models.Model):
    title = models.CharField(max_length=200, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['is_published', 'created_at']),
            models.Index(fields=['created_by', 'is_published']),
        ]

# Use select_related and prefetch_related
Quiz.objects.select_related('created_by', 'subject').prefetch_related('questions__choices')
```

### Frontend Optimization
```dart
// Use lazy loading and caching
class ApiService extends GetxService {
  final Map<String, dynamic> _cache = {};
  
  Future<List<Quiz>> getQuizzesWithCache() async {
    const cacheKey = 'available_quizzes';
    
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      if (DateTime.now().difference(cached['timestamp']).inMinutes < 5) {
        return cached['data'];
      }
    }
    
    final quizzes = await getStudentQuizzes();
    _cache[cacheKey] = {
      'data': quizzes,
      'timestamp': DateTime.now(),
    };
    
    return quizzes;
  }
}
```

## 🧪 Testing Strategy

### Backend Testing
```python
# tests/test_quiz_api.py
from django.test import TestCase
from graphene.test import Client
from quiz_api.schema import schema

class QuizAPITestCase(TestCase):
    def setUp(self):
        self.client = Client(schema)
        
    def test_quiz_creation(self):
        query = '''
            mutation {
                createQuiz(title: "Test Quiz", description: "Test") {
                    success
                    quiz { id title }
                }
            }
        '''
        result = self.client.execute(query)
        self.assertTrue(result['data']['createQuiz']['success'])
```

### Frontend Testing
```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/screens/quiz_list_screen.dart';

void main() {
  testWidgets('Quiz list displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    expect(find.text('Available Quizzes'), findsOneWidget);
    expect(find.byType(QuizListItem), findsWidgets);
  });
}
```

## 🔄 CI/CD Pipeline

### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy Quiz App

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.9
      - name: Install dependencies
        run: |
          cd quiz_backend
          pip install -r requirements.txt
      - name: Run tests
        run: |
          cd quiz_backend
          python manage.py test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: |
          # Your deployment commands here
          echo "Deploying to production..."
```

## 📱 Mobile App Extension

### Flutter Mobile Build
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🎯 Success Metrics & KPIs

### Technical Metrics
- **Response Time**: < 200ms average
- **Uptime**: 99.9% availability
- **Error Rate**: < 0.1%
- **Database Performance**: < 50ms query time
- **Memory Usage**: < 512MB per instance

### Business Metrics
- **User Engagement**: Daily active users
- **Quiz Completion Rate**: % of started quizzes completed
- **User Satisfaction**: Rating and feedback scores
- **Performance Improvement**: Student score trends
- **System Adoption**: New user registration rate

This deployment guide ensures your quiz application can scale from development to production with proper monitoring, security, and performance optimization.