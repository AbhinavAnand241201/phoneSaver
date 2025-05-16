# PhoneSaver Backend

A robust backend service for the PhoneSaver application, built with Go and Gin framework. This service provides a comprehensive RESTful API for managing contacts with advanced features like contact tagging, one-tap communication, scheduled reminders, encrypted contacts, and cloud backups via Firebase.

## 🌟 Features

### Core Functionality
- **User Authentication**
  - JWT-based secure authentication
  - Password hashing with bcrypt
  - Session management
  - Rate limiting for auth endpoints

### Contact Management
- **CRUD Operations**
  - Create, read, update, and delete contacts
  - Bulk operations support
  - Pagination and filtering
  - Search functionality

### Advanced Features
- **Contact Tagging System**
  - Multiple tags per contact
  - Tag-based filtering
  - Tag management API

- **Interaction Tracking**
  - Last interaction timestamp
  - Interaction history
  - Interaction type tracking

- **Birthday Management**
  - Birthday tracking
  - Upcoming birthday notifications
  - Age calculation

- **Cloud Integration**
  - Firebase Firestore backup
  - Real-time sync
  - Backup scheduling
  - Restore functionality

### Security Features
- JWT-based authentication
- Password hashing
- Input validation
- Rate limiting
- CORS configuration
- Secure headers
- Data encryption

## 🛠️ Technical Stack

- **Language**: Go 1.20+
- **Framework**: Gin Web Framework
- **Database**: MySQL 8.0+
- **Cloud**: Firebase Firestore
- **Authentication**: JWT
- **Validation**: Go Validator
- **Testing**: Go Testing Framework

## 📋 Prerequisites

- Go 1.20 or later
- MySQL 8.0 or later
- Firebase project with Firestore enabled
- Git

## 🔧 Environment Setup

1. Create a `.env` file in the root directory:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=phonesaver

# Server Configuration
SERVER_PORT=8080
JWT_SECRET=your_jwt_secret

# Firebase Configuration
FIREBASE_CONFIG=./firebase-credentials.json
```

2. Download your Firebase service account key from the Firebase Console and save it as `firebase-credentials.json` in the project root.

## 🚀 Getting Started

1. **Clone the Repository**
```bash
git clone https://github.com/AbhinavAnand241201/phoneSaver.git
cd phonesaver-backend
```

2. **Install Dependencies**
```bash
go mod tidy
```

3. **Database Setup**
```sql
CREATE DATABASE phonesaver;
```

4. **Run the Application**
```bash
go run main.go
```

## 📚 API Documentation

### Authentication Endpoints

- `POST /api/v1/signup`
  - Register a new user
  - Rate limit: 5 requests/second

- `POST /api/v1/login`
  - Login and get JWT token
  - Rate limit: 5 requests/second

### Contact Management Endpoints

- `POST /api/v1/contacts`
  - Add a new contact
  - Rate limit: 10 requests/second

- `GET /api/v1/contacts`
  - Get all contacts
  - Supports pagination and filtering
  - Rate limit: 10 requests/second

- `POST /api/v1/contacts/:id/tags`
  - Update contact tags
  - Rate limit: 10 requests/second

- `POST /api/v1/contacts/:id/last-interaction`
  - Update last interaction
  - Rate limit: 10 requests/second

- `POST /api/v1/contacts/:id/birthday`
  - Update birthday
  - Rate limit: 10 requests/second

### Backup Endpoints

- `POST /api/v1/backup`
  - Backup contacts to Firebase
  - Rate limit: 5 requests/second

## 🔒 Security

### Authentication
- JWT-based authentication
- Password hashing with bcrypt
- Token expiration and refresh

### Data Protection
- Input validation
- SQL injection prevention
- XSS protection
- CORS configuration
- Rate limiting
- Secure headers

## 📊 Error Handling

The API uses a standard response format:

```json
{
  "success": true|false,
  "data": {...},
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message"
  }
}
```

## 🧪 Testing

Run the test suite:
```bash
go test ./...
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Abhinav Anand** - *Initial work* - [AbhinavAnand241201](https://github.com/AbhinavAnand241201)

## 🙏 Acknowledgments

- Gin Web Framework
- Firebase
- MySQL
- Go Validator
- JWT-Go 