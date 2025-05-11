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
phonesaver/
├── phonesaver-frontend/       # SwiftUI frontend code
│   ├── PhoneSaver.xcodeproj   # Xcode project file
│   ├── PhoneSaver/            # Main app code
│   │   ├── Models/            # Data models (e.g., Contact.swift)
│   │   ├── ViewModels/        # View models (e.g., AuthViewModel.swift)
│   │   ├── Views/             # UI views (e.g., ContactsListView.swift)
│   │   ├── Info.plist         # App configuration
│   │   └── ...
├── phonesaver-backend/        # Go backend code
│   ├── main.go                # Main backend application
│   ├── go.mod                 # Go module dependencies
│   ├── go.sum                 # Dependency checksums
│   └── serviceAccountKey.json # Firebase service account key (not included in repo)
├── README.md                  # This file
└── LICENSE                    # License file (MIT License)
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

### Backend:
- Go 1.20 or later
- MySQL 8.0 or later
- Firebase Admin SDK (`go get firebase.google.com/go`)

### General:
- Git
- A Firebase project (for cloud backups)

## Setup Instructions

### Backend Setup

1. Navigate to the Backend Directory:
   ```bash
   cd phonesaver-backend
   ```

2. Install Dependencies:
   Install the required Go packages:
   ```bash
   go mod tidy
   ```
   This will install dependencies like gin-gonic/gin, go-sql-driver/mysql, and firebase.google.com/go.

3. Set Up Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Go to Project Settings > Service Accounts and generate a new private key.
   - Download the `serviceAccountKey.json` file and place it in the `phonesaver-backend` directory.
   - Note: Do not commit this file to GitHub. It's already in .gitignore.

4. Start the Backend Server:
   Run the backend server:
   ```bash
   go run main.go
   ```
   The server will start on http://localhost:8080.

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
   cd phonesaver-frontend
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

## Usage

1. Start the Backend:
   - Ensure the backend server is running (`go run main.go` in the phonesaver-backend directory).
   - The server will be available at http://localhost:8080.

2. Run the App:
   - Launch the app in Xcode.
   - Sign up or log in using the `/signup` or `/login` endpoints.
   - Add contacts, manage tags, set reminders, and back up contacts to Firebase.

### Key Features:

- **Add a Contact**: Enter name, phone number, tags, last interaction, and birthday.
- **Tag Contacts**: Add or remove tags to organize contacts.
- **One-Tap Communication**: Call or message contacts directly.
- **Set Reminders**: Schedule follow-up reminders using local notifications.
- **Backup Contacts**: Back up contacts to Firebase for syncing.

## API Endpoints

The backend provides the following API endpoints:

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/signup` | Register a new user | `{ "email": "user@example.com", "password": "pass123" }` | `{ "message": "User created successfully" }` |
| POST | `/login` | Log in a user | `{ "email": "user@example.com", "password": "pass123" }` | `{ "token": "jwt_token" }` |
| POST | `/contacts` | Add a new contact | `{ "name": "John", "encrypted_phone": "encrypted_data", "tags": "Work", "last_interaction": "2025-05-11T10:00:00Z", "birthday": "1990-01-01" }` | `{ "message": "Contact added successfully" }` |
| GET | `/contacts` | Fetch all contacts for the user | None | Array of contacts |
| POST | `/contacts/:id/tags` | Update tags for a contact | `{ "tags": ["Work", "Friend"] }` | `{ "message": "Tags updated successfully" }` |
| POST | `/contacts/:id/last-interaction` | Update last interaction for a contact | `{ "last_interaction": "2025-05-11T10:00:00Z" }` | `{ "message": "Last interaction updated successfully" }` |
| POST | `/contacts/:id/birthday` | Update birthday for a contact | `{ "birthday": "1990-01-01" }` | `{ "message": "Birthday updated successfully" }` |
| POST | `/backup` | Back up contacts to Firebase | Array of contacts | `{ "message": "Backup successful" }` |

### Authentication

- All endpoints except `/signup` and `/login` require a JWT token.
- Pass the token in the Authorization header: `Bearer <token>`.

## Screenshots

(Add screenshots of your app here once available)

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Make your changes and commit (`git commit -m "Add your feature"`).
4. Push to your branch (`git push origin feature/your-feature`).
5. Open a Pull Request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. 