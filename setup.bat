@echo on
cd /d "%~dp0"

echo ========================================
echo    Quiz App - Automated Setup Script
echo    Developer: Benny Tech Design
echo    Email: bennytechdesign@gmail.com
echo ========================================
echo.

:: Check if Python is installed
echo [1/8] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found! Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)
echo ✅ Python found

:: Check if Flutter is installed
echo [2/8] Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found! Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)
echo ✅ Flutter found

:: Setup Backend
echo [3/8] Setting up Django backend...
cd quiz_backend
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo Installing Python dependencies...
pip install -r requirements.txt

echo Setting up database...
python manage.py makemigrations
python manage.py migrate

echo Creating test users...
python create_test_users.py

echo [4/8] Starting Django backend server...
start "Django Backend" cmd /k "cd /d %cd% && venv\Scripts\activate.bat && python manage.py runserver"

:: Wait for backend to start
echo Waiting for backend to start...
timeout /t 5 /nobreak >nul

:: Setup Frontend
echo [5/8] Setting up Flutter frontend...
cd ..\quiz_mobile

echo Installing Flutter dependencies...
flutter pub get

echo [6/8] Checking Flutter doctor...
flutter doctor

echo [7/8] Starting Flutter web app...
start "Flutter Frontend" cmd /k "cd /d %cd% && flutter run -d chrome --web-port 8080 --release"

echo [8/8] Setup complete!
echo.
echo ========================================
echo           🎉 SETUP COMPLETE! 🎉
echo ========================================
echo.
echo Backend: http://127.0.0.1:8000
echo Frontend: http://localhost:8080
echo.
echo Test Credentials:
echo Admin: admin@test.com / admin123
echo Teacher: 4@gmail.com / password123
echo Student: student@test.com / student123
echo.
echo Developer: Benny Tech Design
echo Email: bennytechdesign@gmail.com
echo Phone: +255 690 388 447
echo Location: SUA, Mazimbu, Morogoro, Tanzania
echo.
echo Press any key to open the app...
pause >nul

:: Open the app in browser
start http://localhost:8080

echo.
echo Happy testing! 🚀
pause