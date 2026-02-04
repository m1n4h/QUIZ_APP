# Quick Reference - GraphQL Mutations & Queries

## 🚀 Quick Start

### 1. Start the Server
```bash
cd quiz_backend
python manage.py runserver
```

### 2. Open GraphQL Interface
Visit: http://localhost:8000/graphql/

### 3. Get Authorization Token
Use the **Signup** or **Login** mutation, copy the token from response

### 4. Add Token to Headers
In GraphQL interface, add HTTP Headers (bottom section):
```json
{
  "Authorization": "Bearer YOUR_TOKEN_HERE"
}
```

---

## 📋 Essential Mutations

### Signup
```graphql
mutation {
  signup(email: "user@test.com", username: "user", password: "pass123", role: "teacher") {
    success
    user { id email role }
  }
}
```

### Login
```graphql
mutation {
  login(email: "user@test.com", password: "pass123") {
    success
    token
    refresh
  }
}
```

### Create Quiz ⭐
```graphql
mutation {
  createQuiz(
    title: "My Quiz"
    description: "Quiz description"
    timeLimit: 30
    allowReview: true
    showScore: true
  ) {
    success
    quiz { id title }
  }
}
```

### Create Question ⭐
```graphql
mutation {
  createQuestion(
    quizId: "PASTE_QUIZ_ID_HERE"
    questionText: "What is 2+2?"
    questionType: "mcq"
    points: 5
    order: 1
    choices: [
      "{\"choiceText\":\"3\",\"isCorrect\":false,\"order\":1}"
      "{\"choiceText\":\"4\",\"isCorrect\":true,\"order\":2}"
      "{\"choiceText\":\"5\",\"isCorrect\":false,\"order\":3}"
    ]
  ) {
    success
    question { id questionText }
  }
}
```

### Submit Quiz ⭐
```graphql
mutation {
  submitQuiz(
    quizId: "PASTE_QUIZ_ID_HERE"
    timeTaken: 300
    answers: [
      "{\"questionId\":\"PASTE_Q_ID\",\"selectedChoiceId\":\"PASTE_CHOICE_ID\"}"
    ]
  ) {
    success
    attempt { 
      id 
      score 
      correctAnswers 
      percentage 
      status 
    }
  }
}
```

---

## 📊 Essential Queries

### Get My Quizzes
```graphql
query {
  myQuizzes {
    id
    title
    description
    questionCount
    timeLimit
    isPublished
  }
}
```

### Get Quiz Details
```graphql
query {
  quizDetail(id: "PASTE_ID_HERE") {
    id
    title
    description
    timeLimit
    questions {
      id
      questionText
      points
      choices {
        id
        choiceText
        isCorrect
      }
    }
  }
}
```

### Get Quiz Results
```graphql
query {
  quizResults {
    id
    quizTitle
    score
    totalQuestions
    correctAnswers
    percentage
    status
    completedAt
  }
}
```

---

## 🔑 Key Points

| Item | Value |
|------|-------|
| Endpoint | http://localhost:8000/graphql/ |
| Method | POST |
| Interface | GraphiQL (automatic) |
| Auth Header | `Authorization: Bearer TOKEN` |
| Database | PostgreSQL (quiz_db) |
| Python Version | 3.10+ |

---

## ✅ Testing Checklist

- [ ] Server running (`python manage.py runserver`)
- [ ] Can access http://localhost:8000/graphql/
- [ ] Can signup a teacher account
- [ ] Can login and get token
- [ ] Can create a quiz
- [ ] Can add questions to quiz
- [ ] Can submit quiz answers
- [ ] Can view results

---

## 🐛 Troubleshooting

| Error | Solution |
|-------|----------|
| "Failed to fetch" | Check if server is running |
| "Not authenticated" | Add Authorization header with token |
| "Quiz not found" | Verify quiz ID is correct |
| "Database connection error" | Check PostgreSQL is running |
| "Invalid JWT" | Token expired? Login again |

---

## 📝 Example IDs Format

Quiz ID: `73112341-9b63-4958-a418-2575b2e7d7c1`
Question ID: `a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d`
Choice ID: `f5g6h7i8-j9k0-4l1m-2n3o-4p5q6r7s8t9u`

(These are UUIDs - copy actual IDs from your responses)

---

## 📚 More Resources

- See `GRAPHQL_TESTING_GUIDE.md` for detailed examples
- See `BACKEND_FIXES_SUMMARY.md` for what was fixed
- Django docs: https://docs.djangoproject.com/
- Graphene docs: https://docs.graphene-python.org/
