# PhoneSaver

PhoneSaver is a modern contact management app built with SwiftUI for the frontend and Go (using the Gin framework) for the backend. It provides a seamless way to manage contacts with features like contact tagging, one-tap communication, scheduled reminders, encrypted contacts, and cloud backups via Firebase. The app uses a MySQL database to store contact data securely and integrates Firebase for backup functionality.

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [Backend Setup](#backend-setup)
  - [Database Setup](#database-setup)
  - [Frontend Setup](#frontend-setup)
- [Usage](#usage)
- [API Endpoints](#api-endpoints)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Contact Tagging**: Organize contacts with custom tags (e.g., "Work", "Family").
- **One-Tap Communication**: Call or message contacts directly from the app.
- **Scheduled Reminders**: Set follow-up reminders for contacts using local notifications.
- **Encrypted Contacts**: Securely store phone numbers using CryptoKit for encryption.
- **Cloud Backups**: Back up contacts to Firebase for easy syncing and recovery.
- **Insights**: View last interaction dates and birthdays for each contact.
- **Temporary Sharing**: Share contacts via temporary links (stored in the share_links table).
- **Dark Mode Support**: Fully responsive UI with dark mode support.

## Project Structure

```
phoneSaver/
├── ios-app/           # iOS frontend application (SwiftUI)
│   ├── Assets.xcassets/  # App assets
│   ├── Views/         # SwiftUI view components
│   └── Models/        # Data models
├── backend/           # Go backend server
│   ├── main.go        # Main server code
│   ├── phoneS/       # Backend services
│   └── config/       # Configuration files
└── android-app/      # Placeholder for Android version
│   ├── go.mod                 # Go module dependencies
│   ├── go.sum                 # Dependency checksums
│   └── serviceAccountKey.json # Firebase service account key (not included in repo)
├── README.md                  # This file
├── LICENSE                    # License file (MIT License)
└── .env.example              # Environment variables template
```

## Tech Stack

- **Frontend**: SwiftUI, CryptoKit, UserNotifications, Firebase SDK
- **Backend**: Go, Gin framework, MySQL, Firebase Admin SDK
- **Database**: MySQL
- **Cloud**: Firebase (Firestore for backups)

## Prerequisites

Before setting up the project, ensure you have the following installed:

### Frontend:
- Xcode 15.0 or later
- iOS 16.0 or later (for simulator/device)
- Firebase SDK (via Swift Package Manager)
- CocoaPods (for additional dependencies)

### Backend:
- Go 1.20 or later
- MySQL 8.0 or later
- Firebase Admin SDK (`go get firebase.google.com/go`)
- OpenSSL (for encryption)

### Security Requirements:
- Strong password policy (minimum 12 characters, including uppercase, lowercase, numbers, and special characters)
- Rate limiting configuration
- SSL/TLS certificates
- Environment variables for sensitive data

### General:
- Git
- A Firebase project (for cloud backups)
- A MySQL database instance
- A domain name for production deployment

## Setup Instructions

### Security Configuration

1. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

2. Configure environment variables:
```bash
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_db_user
DB_PASSWORD=your_secure_password
DB_NAME=phonesaver
JWT_SECRET=your_secure_jwt_secret
SERVER_PORT=8080
FIREBASE_CONFIG=./firebase-credentials.json
RATE_LIMIT=100
RATE_LIMIT_PERIOD=100
```

3. Set up security headers:
- Enable CORS only for trusted domains
- Set up proper Content Security Policy
- Enable HSTS
- Configure security headers in Nginx/Apache

### Backend Setup

1. Navigate to the Backend Directory:
```bash
cd phonesaver-backend
```

2. Install Dependencies:
```bash
go mod tidy
```

3. Set Up Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Go to Project Settings > Service Accounts and generate a new private key.
   - Download the `serviceAccountKey.json` file and place it in the `phonesaver-backend` directory.
   - Note: Do not commit this file to GitHub. It's already in .gitignore.

4. Configure Database:
```bash
# Create database
mysql -u root -p
CREATE DATABASE phonesaver;
USE phonesaver;

# Create tables
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    encrypted_phone VARCHAR(255) NOT NULL,
    tags VARCHAR(255) DEFAULT '',
    last_interaction DATETIME DEFAULT NULL,
    birthday DATE DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE share_links (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(36) NOT NULL,
    contact_id INT NOT NULL,
    user_id INT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (contact_id) REFERENCES contacts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

# Create indexes
CREATE INDEX idx_user_id ON contacts(user_id);
CREATE INDEX idx_tags ON contacts(tags);
CREATE INDEX idx_last_interaction ON contacts(user_id, last_interaction);
CREATE INDEX idx_share_links ON share_links(token);
```

5. Start the Backend Server:
```bash
# Run with environment variables
export $(cat .env | xargs)
go run main.go
```

### Frontend Setup

1. Navigate to the Frontend Directory:
```bash
cd phoneS/phoneS
```

2. Open the Project in Xcode:
```bash
open PhoneSaver.xcodeproj
```

3. Install Firebase SDK:
   - In Xcode, go to File > Add Packages.
   - Add the Firebase SDK by entering the URL: https://github.com/firebase/firebase-ios-sdk.
   - Select the FirebaseFirestore and FirebaseAuth packages.

4. Configure Firebase:
   - Download the `GoogleService-Info.plist` file from your Firebase project (Project Settings > General).
   - Add it to the PhoneSaver target in Xcode.
   - Initialize Firebase in your AppDelegate or App struct.

5. Build and Run:
   - Select an iOS simulator or device in Xcode.
   - Press Cmd + R to build and run the app.

### Security Best Practices

1. Environment Variables:
   - Never commit sensitive data to version control
   - Use environment variables for configuration
   - Rotate secrets regularly

2. Input Validation:
   - Validate all user inputs
   - Use prepared statements for database queries
   - Implement rate limiting
   - Sanitize user input

3. Error Handling:
   - Never expose sensitive information in error messages
   - Log errors securely
   - Implement proper error boundaries

4. Authentication:
   - Use JWT for authentication
   - Implement proper session management
   - Use secure password hashing
   - Implement password reset functionality

5. Data Protection:
   - Encrypt sensitive data
   - Use secure key management
   - Implement proper backup procedures
   - Use secure communication channels

### Database Setup

1. Install MySQL (if not already installed):
   - On macOS (using Homebrew):
```bash
brew install mysql
```

2. Start the MySQL server:
```bash
brew services start mysql
```

3. Log in to MySQL:
```bash
mysql -u root -p
```
   Enter your password (e.g., MySecurePass123).

4. Create the Database:
```sql
CREATE DATABASE phonesaver;
USE phonesaver;
```

5. Create the users Table:
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);
```

6. Create the contacts Table:
```sql
CREATE TABLE contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    encrypted_phone VARCHAR(255) NOT NULL,
    tags VARCHAR(255) DEFAULT '',
    last_interaction DATETIME DEFAULT NULL,
    birthday DATE DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

7. Create the share_links Table:
```sql
CREATE TABLE share_links (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(36) NOT NULL,
    contact_id INT NOT NULL,
    user_id INT NOT NULL,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (contact_id) REFERENCES contacts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

8. Add Indexes:
```sql
CREATE INDEX idx_user_id ON contacts(user_id);
CREATE INDEX idx_tags ON contacts(tags);
CREATE INDEX idx_last_interaction ON contacts(user_id, last_interaction);
```

### Frontend Setup

1. Navigate to the Frontend Directory:
```bash
```

#### Update Last Interaction
```http
PUT /api/contacts/:id/last-interaction
Authorization: Bearer <token>
Content-Type: application/json

{
  "last_interaction": "2024-01-01T00:00:00Z"
}
```

#### Update Birthday
```http
PUT /api/contacts/:id/birthday
Authorization: Bearer <token>
Content-Type: application/json

{
  "birthday": "1990-01-01"
}
```

#### Backup Contacts
```http
POST /api/backup
Authorization: Bearer <token>
Content-Type: application/json

{
  "contacts": [
    {
      "name": "John Doe",
      "phone": "+1234567890",
      "tags": ["friend", "work"]
    }
  ]
}
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
## Contact

Abhinav Anand - [@AbhinavAnand241201](https://github.com/AbhinavAnand241201)

Project Link: [https://github.com/AbhinavAnand241201/phoneSaver](https://github.com/AbhinavAnand241201/phoneSaver) 