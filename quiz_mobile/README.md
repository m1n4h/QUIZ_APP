# quiz_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.




=====backend comand=====
# create and Activate virtual environment
python3 -m venv venv
source venv/bin/activate


# install dependencies
pip3 install -r requirements.txt

# Create new migrations
python3 manage.py makemigrations
python3 manage.py migrate


# Run development server
python3 manage.py runserver
python manage.py runserver 0.0.0.0:8000


# Backend API Endpoints:

Admin Panel: http://127.0.0.1:8000/admin

API Root: http://127.0.0.1:8000/api/

Authentication: http://127.0.0.1:8000/api/auth/login/




# Apply migrations
python3 manage.py migrate

# Create superuser
python3 manage.py createsuperuser

# Run tests
python3 manage.py test

# Check for issues
python3 manage.py check



========frontend command===============

===install flutter dependencies===
# Install google_fonts package
flutter pub add google_fonts

# Install riverpod for state management
flutter pub add flutter_riverpod

# Install http for API calls
flutter pub add http

# Install get for navigation
flutter pub add get



==run flutter==

# Get packages
flutter pub get

==Run app==
# for androids
flutter run

# For iOS (if on Mac)
flutter run -d ios

# For web
flutter run -d chrome
 === build for production =====
 # Build APK for Android
flutter build apk

# Build App Bundle for Play Store
flutter build appbundle

# Build for iOS
flutter build ios

# Build for web
flutter build web

=====================================

# Run on specific device
flutter run -d <device_id>

# Check for issues
flutter analyze

# Format code
flutter format .

# Clean project
flutter clean

# Upgrade packages
flutter pub upgrade

# Build release APK
flutter build apk --release









