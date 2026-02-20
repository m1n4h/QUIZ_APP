#!/bin/bash

echo "========================================"
echo "   Quiz App - Automated Setup Script"
echo "   Developer: Benny Tech Design"
echo "   Email: bennytechdesign@gmail.com"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Python is installed
echo -e "${BLUE}[1/8] Checking Python installation...${NC}"
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo -e "${RED}❌ Python not found! Please install Python 3.8+${NC}"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi
echo -e "${GREEN}✅ Python found${NC}"

# Check if Flutter is installed
echo -e "${BLUE}[2/8] Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found! Please install Flutter from https://flutter.dev${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter found${NC}"

# Setup Backend
echo -e "${BLUE}[3/8] Setting up Django backend...${NC}"
cd quiz_backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    $PYTHON_CMD -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Setup database
echo "Setting up database..."
$PYTHON_CMD manage.py makemigrations
$PYTHON_CMD manage.py migrate

# Create test users
echo "Creating test users..."
$PYTHON_CMD create_test_users.py

# Start backend server in background
echo -e "${BLUE}[4/8] Starting Django backend server...${NC}"
$PYTHON_CMD manage.py runserver &
BACKEND_PID=$!

# Wait for backend to start
echo "Waiting for backend to start..."
sleep 5

# Setup Frontend
echo -e "${BLUE}[5/8] Setting up Flutter frontend...${NC}"
cd ../quiz_mobile

# Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# Check Flutter doctor
echo -e "${BLUE}[6/8] Checking Flutter doctor...${NC}"
flutter doctor

# Start Flutter web app
echo -e "${BLUE}[7/8] Starting Flutter web app...${NC}"
flutter run -d chrome --web-port 8080 --release &
FRONTEND_PID=$!

echo -e "${BLUE}[8/8] Setup complete!${NC}"
echo
echo "========================================"
echo -e "          ${GREEN}🎉 SETUP COMPLETE! 🎉${NC}"
echo "========================================"
echo
echo -e "${YELLOW}Backend:${NC} http://127.0.0.1:8000"
echo -e "${YELLOW}Frontend:${NC} http://localhost:8080"
echo
echo -e "${YELLOW}Test Credentials:${NC}"
echo "Admin: admin@test.com / admin123"
echo "Teacher: 4@gmail.com / password123"
echo "Student: student@test.com / student123"
echo
echo -e "${YELLOW}Developer:${NC} Benny Tech Design"
echo -e "${YELLOW}Email:${NC} bennytechdesign@gmail.com"
echo -e "${YELLOW}Phone:${NC} +255 690 388 447"
echo -e "${YELLOW}Location:${NC} SUA, Mazimbu, Morogoro, Tanzania"
echo
echo "Press Ctrl+C to stop both servers"
echo "Happy testing! 🚀"

# Wait for user to stop
wait