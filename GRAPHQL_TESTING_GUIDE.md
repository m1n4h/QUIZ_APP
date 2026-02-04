# GraphQL Testing Guide for Quiz App

## Endpoint
- URL: `http://localhost:8000/graphql/`
- Method: POST
- You can test directly in GraphiQL (browser interface) at the same URL

---

## 1. Authentication Mutations

### Signup
```graphql
mutation {
  signup(
    email: "teacher@example.com"
    username: "teacher_user"
    password: "SecurePass123"
    role: "teacher"
    firstName: "John"
    lastName: "Doe"
  ) {
    success
    message
    user {
      id
      email
      username
      role
    }
  }
}
```

### Login
```graphql
mutation {
  login(
    email: "teacher@example.com"
    password: "SecurePass123"
  ) {
    success
    token
    refresh
    user {
      id
      email
      username
      role
    }
  }
}
```

**Important:** After login, copy the `token` value and use it in the GraphQL request headers:
```json
{
  "Authorization": "Bearer <your-token-here>"
}
```

---

## 2. Create Quiz Mutation

```graphql
mutation {
  createQuiz(
    title: "Python Fundamentals"
    description: "Test your knowledge of Python basics"
    subjectId: null
    timeLimit: 30
    allowReview: true
    showScore: true
  ) {
    success
    message
    quiz {
      id
      title
      description
      timeLimit
      isPublished
    }
  }
}
```

**Response Example:**
```json
{
  "data": {
    "createQuiz": {
      "success": true,
      "message": null,
      "quiz": {
        "id": "73112341-9b63-4958-a418-2575b2e7d7c1",
        "title": "Python Fundamentals",
        "description": "Test your knowledge of Python basics",
        "timeLimit": 30,
        "isPublished": false
      }
    }
  }
}
```

---

## 3. Create Question Mutation

**Important:** Replace `quiz_id` with the quiz ID from step 2.

```graphql
mutation {
  createQuestion(
    quizId: "73112341-9b63-4958-a418-2575b2e7d7c1"
    questionText: "Which of the following is the correct full meaning of WWW?"
    questionType: "mcq"
    order: 1
    points: 10
    choices: [
      "{\"choiceText\":\"World Web Wide\",\"isCorrect\":false,\"order\":1}"
      "{\"choiceText\":\"Web World Wide\",\"isCorrect\":false,\"order\":2}"
      "{\"choiceText\":\"World Wide Web\",\"isCorrect\":true,\"order\":3}"
      "{\"choiceText\":\"Web Wide World\",\"isCorrect\":false,\"order\":4}"
    ]
  ) {
    success
    message
    question {
      id
      questionText
      order
      points
      questionType
      choices {
        id
        choiceText
        isCorrect
        order
      }
    }
  }
}
```

---

## 4. Get Quiz Details Query

```graphql
query {
  quizDetail(id: "73112341-9b63-4958-a418-2575b2e7d7c1") {
    id
    title
    description
    timeLimit
    isPublished
    allowReview
    showScore
    questionCount
    questions {
      id
      questionText
      questionType
      points
      order
      choices {
        id
        choiceText
        isCorrect
        order
      }
    }
  }
}
```

---

## 5. Get Available Quizzes Query

```graphql
query {
  availableQuizzes {
    id
    title
    description
    timeLimit
    isAvailable
    questionCount
    createdBy {
      id
      username
      firstName
      lastName
    }
  }
}
```

---

## 6. Submit Quiz Mutation

**Important:** Use `question_id` and `selected_choice_id` from the quiz you created.

```graphql
mutation {
  submitQuiz(
    quizId: "73112341-9b63-4958-a418-2575b2e7d7c1"
    timeTaken: 120
    answers: [
      "{\"questionId\":\"question-id-1\",\"selectedChoiceId\":\"choice-id-3\",\"answerText\":\"\"}"
      "{\"questionId\":\"question-id-2\",\"selectedChoiceId\":\"choice-id-1\",\"answerText\":\"\"}"
    ]
  ) {
    success
    message
    attempt {
      id
      score
      totalQuestions
      correctAnswers
      percentage
      status
      timeTaken
      completedAt
    }
  }
}
```

---

## 7. Get Quiz Results Query

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
    timeTaken
    completedAt
  }
}
```

---

## Common Issues and Fixes

### Issue: "Failed to fetch"
- Check if Django server is running: `python manage.py runserver`
- Verify CORS is enabled in settings
- Check if token is valid and included in headers

### Issue: "Not authenticated"
- Make sure to include the Authorization header with your token
- Check token hasn't expired (7 days)

### Issue: "Quiz not found" or "Question not found"
- Verify the IDs are correct UUIDs
- Make sure you copied the ID correctly from the previous response

### Issue: JSON parsing error in choices
- Ensure choice objects are properly formatted as strings with escaped quotes
- Example: `"{\"choiceText\":\"Option 1\",\"isCorrect\":true,\"order\":1}"`

---

## Testing with cURL

### Example: Get GraphQL Schema
```bash
curl -X POST http://localhost:8000/graphql/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'
```

### Example: Signup with cURL
```bash
curl -X POST http://localhost:8000/graphql/ \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { signup(email: \"test@example.com\", username: \"testuser\", password: \"Pass123\", role: \"student\") { success token user { id email } } }"
  }'
```

---

## Testing with Postman

1. Create a new GraphQL request
2. Set URL: `http://localhost:8000/graphql/`
3. Set method to POST
4. Add headers:
   - `Content-Type: application/json`
   - `Authorization: Bearer <your-token>`
5. In the body (GraphQL tab), paste your mutation/query
6. Click Send

---

## Next Steps

1. **Start Django server:**
   ```bash
   cd quiz_backend
   python manage.py runserver
   ```

2. **Test in GraphiQL:**
   - Open browser to `http://localhost:8000/graphql/`
   - Run mutations/queries directly

3. **Verify database:**
   - Quiz and Question records should appear in Django admin
   - Check: `http://localhost:8000/admin/`

4. **Debug issues:**
   - Check Django console for error messages
   - Enable DEBUG = True in settings.py to see detailed errors
