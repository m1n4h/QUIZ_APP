# Quiz App - Complete Setup Guide

## 📱 Quiz Management System
**Developer:** Benny Tech Design  
**Email:** bennytechdesign@gmail.com  
**Phone:** +255 690 388 447  
**Location:** SUA, Mazimbu, Morogoro, Tanzania  

---

## 🎯 Project Overview

This is a complete Quiz Management System with:
- **Flutter Web/Mobile App** (Frontend)
- **Django + GraphQL API** (Backend)
- **SQLite Database** (Local storage)
- **Three User Dashboards:** Admin, Teacher, Student

---

## 🚀 Quick Start (One-Command Setup)

### Windows Users:
```bash
setup.bat
```

### Linux/Mac Users:
```bash
chmod +x setup.sh
./setup.sh
```

---

## 📋 Manual Setup Instructions

### Prerequisites

1. **Python 3.8+**
   - Download: https://www.python.org/downloads/
   - ✅ Check: `python --version`

2. **Flutter SDK**
   - Download: https://flutter.dev/docs/get-started/install
   - ✅ Check: `flutter --version`

3. **Git** (Optional)
   - Download: https://git-scm.com/downloads

---

## 🔧 Step-by-Step Setup

### Step 1: Backend Setup (Django)

1. **Navigate to backend folder:**
   ```bash
   cd quiz_backend
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Setup database:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

4. **Create test users:**
   ```bash
   python create_test_users.py
   ```

5. **Start backend server:**
   ```bash
   python manage.py runserver
   ```
   ✅ **Backend running at:** http://127.0.0.1:8000

### Step 2: Frontend Setup (Flutter)

1. **Open new terminal/command prompt**

2. **Navigate to frontend folder:**
   ```bash
   cd quiz_mobile
   ```

3. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run -d chrome --web-port 8080 --release
   ```
   ✅ **Frontend running at:** http://localhost:8080

---

## 👥 Test Credentials

### Admin Account
- **Email:** admin@test.com
- **Password:** admin123
- **Access:** Full system control

### Teacher Account
- **Email:** 4@gmail.com
- **Password:** password123
- **Access:** Create/manage quizzes

### Student Account
- **Email:** student@test.com
- **Password:** student123
- **Access:** Take quizzes, view results

---

## 🎛️ Dashboard Features

### 🔴 Admin Dashboard
- **User Management:** Approve/suspend/delete users
- **Quiz Oversight:** View all quizzes
- **Subject Management:** Create/edit/delete subjects
- **Analytics:** System overview and user statistics
- **Profile Management:** Edit personal information

### 🔵 Teacher Dashboard
- **Quiz Creation:** Create and manage quizzes
- **Question Management:** Add multiple choice, true/false, short answer
- **Student Results:** View quiz attempts and analytics
- **Profile Management:** Edit personal information

### 🟢 Student Dashboard
- **Available Quizzes:** Browse and take published quizzes
- **Results History:** View past quiz results with detailed answers
- **Profile Management:** Edit personal information

---

## 🔄 Application Flow

### 1. User Registration/Login
- Users register with email and password
- Students: Auto-approved
- Teachers: Require admin approval
- Admins: Auto-approved

### 2. Quiz Creation (Teachers)
- Create quiz with title, description, time limit
- Add questions (MCQ, True/False, Short Answer)
- Publish when ready

### 3. Quiz Taking (Students)
- Browse available quizzes
- Take quiz within time limit
- Submit and view results immediately
- Review correct/incorrect answers

### 4. Management (Admins)
- Approve pending teachers
- Manage all users and quizzes
- Create/edit subjects
- View system analytics

---

## 🛠️ Troubleshooting

### Common Issues:

#### Backend Issues:
```bash
# If port 8000 is busy
python manage.py runserver 8001

# If database errors
python manage.py makemigrations --empty quiz_api
python manage.py migrate

# If permission errors
pip install --user -r requirements.txt
```

#### Frontend Issues:
```bash
# If Flutter not found
flutter doctor

# If dependencies fail
flutter clean
flutter pub get

# If Chrome not found
flutter run -d web-server --web-port 8080
```

#### Network Issues:
- **Backend:** Check http://127.0.0.1:8000/graphql/
- **Frontend:** Check http://localhost:8080
- **Firewall:** Allow ports 8000 and 8080

### Error Messages:
- **"Connection refused"** → Backend not running
- **"GraphQL errors"** → Check backend logs
- **"Flutter build failed"** → Run `flutter clean`

---

## 📱 Mobile App Building

### For Android APK:
```bash
cd quiz_mobile
flutter build apk --release
```
**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### For iOS (Mac only):
```bash
flutter build ios --release
```

### For Web Deployment:
```bash
flutter build web --release
```
**Output:** `build/web/` folder

---

## 🔧 Configuration

### Backend Configuration:
- **File:** `quiz_backend/quiz_backend/settings.py`
- **Database:** SQLite (default) or PostgreSQL/MySQL
- **CORS:** Configured for localhost

### Frontend Configuration:
- **File:** `quiz_mobile/lib/services/api_service.dart`
- **API URL:** http://127.0.0.1:8000 (change for production)

---

## 📊 Database Schema

### Main Tables:
- **Users:** Authentication and profiles
- **Quizzes:** Quiz information
- **Questions:** Quiz questions
- **Choices:** Answer options
- **QuizAttempts:** Student submissions
- **Subjects:** Quiz categories

### Sample Data:
- 9 test users (3 admins, 3 teachers, 3 students)
- Sample subjects (Mathematics, Science, etc.)
- Demo quizzes with questions

---

## 🔒 Security Features

- **JWT Authentication:** Secure token-based auth
- **Role-based Access:** Admin/Teacher/Student permissions
- **Password Hashing:** Secure password storage
- **CORS Protection:** Cross-origin request security
- **Input Validation:** GraphQL schema validation

---

## 📈 Performance Features

- **Optimized Queries:** Efficient database operations
- **Caching:** Flutter widget caching
- **Lazy Loading:** Load data on demand
- **Responsive Design:** Works on all screen sizes

---

## 🎨 UI/UX Features

- **Modern Design:** Clean, professional interface
- **Mobile Responsive:** Works on phones, tablets, desktop
- **Dark/Light Theme:** Consistent color scheme
- **Intuitive Navigation:** Easy-to-use interface
- **Real-time Feedback:** Instant success/error messages

---

## 📞 Support & Contact

### Developer Information:
**Benny Tech Design**
- 📧 **Email:** bennytechdesign@gmail.com
- 📱 **Phone:** +255 690 388 447
- 📍 **Location:** SUA, Mazimbu, Morogoro, Tanzania

### For Technical Support:
1. Check this guide first
2. Try the troubleshooting section
3. Contact developer with:
   - Error screenshots
   - System information
   - Steps to reproduce issue

---

## 📝 Version Information

- **Flutter Version:** 3.x
- **Django Version:** 4.x
- **Python Version:** 3.8+
- **Database:** SQLite 3
- **Last Updated:** December 2024

---

## 🎉 Success Indicators

✅ Backend server running on port 8000  
✅ Frontend app running on port 8080  
✅ Can login with test credentials  
✅ All three dashboards accessible  
✅ Quiz creation and taking works  
✅ Profile management functional  

**🎊 Congratulations! Your Quiz App is ready to use!**

---

*This guide was created by Benny Tech Design for easy deployment and testing of the Quiz Management System.*