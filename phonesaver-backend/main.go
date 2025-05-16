package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"github.com/dgrijalva/jwt-go"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"golang.org/x/crypto/bcrypt"
	"golang.org/x/time/rate"
	"google.golang.org/api/option"
)

// Config holds all configuration for the application
type Config struct {
	DBHost         string
	DBPort         string
	DBUser         string
	DBPassword     string
	DBName         string
	JWTSecret      string
	ServerPort     string
	FirebaseConfig string
}

// LoadConfig loads configuration from environment variables
func LoadConfig() *Config {
	config := &Config{
		DBHost:         getEnv("DB_HOST", ""),
		DBPort:         getEnv("DB_PORT", ""),
		DBUser:         getEnv("DB_USER", ""),
		DBPassword:     getEnv("DB_PASSWORD", ""),
		DBName:         getEnv("DB_NAME", ""),
		JWTSecret:      getEnv("JWT_SECRET", ""),
		ServerPort:     getEnv("SERVER_PORT", "8080"),
		FirebaseConfig: getEnv("FIREBASE_CONFIG", ""),
	}
	
	if config.DBHost == "" || config.DBPort == "" || config.DBUser == "" || config.DBPassword == "" || config.DBName == "" {
		log.Fatal("Missing required database configuration")
	}
	
	if config.JWTSecret == "" {
		log.Fatal("JWT_SECRET must be set")
	}
	
	jwtKey = []byte(config.JWTSecret)
	return config
}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

type User struct {
	ID       int    `json:"id"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type Contact struct {
	ID              int       `json:"id"`
	UserID          int       `json:"user_id"`
	Name            string    `json:"name"`
	Phone           string    `json:"phone"`
	EncryptedPhone  string    `json:"encrypted_phone"`
	Tags            string    `json:"tags"`
	LastInteraction time.Time `json:"last_interaction"`
	Birthday        string    `json:"birthday"`
}

type ContactUpdate struct {
	Tags            []string  `json:"tags"`
	LastInteraction time.Time `json:"last_interaction"`
	Birthday        string    `json:"birthday"`
}

type BackupRequest struct {
	Contacts []Contact `json:"contacts"`
}

type Claims struct {
	UserID int `json:"user_id"`
	jwt.StandardClaims
}

var (
	db              *sql.DB
	firestoreClient *firestore.Client
	config          *Config
)

// JWT key will be loaded from environment variables
var jwtKey []byte

// RateLimiter represents a rate limiter for API endpoints
type RateLimiter struct {
	limiter *rate.Limiter
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(r rate.Limit, b int) *RateLimiter {
	return &RateLimiter{
		limiter: rate.NewLimiter(r, b),
	}
}

// RateLimit middleware limits the number of requests
func (rl *RateLimiter) RateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !rl.limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, Response{
				Success: false,
				Error:   "Rate limit exceeded",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// Logger represents a custom logger
type Logger struct {
	*log.Logger
}

// NewLogger creates a new logger
func NewLogger() *Logger {
	return &Logger{
		Logger: log.New(os.Stdout, "[PhoneSaver] ", log.LstdFlags|log.Lshortfile),
	}
}

var logger = NewLogger()

// LoggerMiddleware returns a gin middleware for logging
func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		// Process request
		c.Next()

		// Log details
		latency := time.Since(start)
		clientIP := c.ClientIP()
		method := c.Request.Method
		statusCode := c.Writer.Status()

		if raw != "" {
			path = path + "?" + raw
		}

		logger.Printf("[GIN] %v | %3d | %13v | %15s | %-7s %#v",
			time.Now().Format("2006/01/02 - 15:04:05"),
			statusCode,
			latency,
			clientIP,
			method,
			path,
		)
	}
}

func initFirebase(config string) error {
	ctx := context.Background()
	opt := option.WithCredentialsFile(config)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return fmt.Errorf("error initializing firebase app: %v", err)
	}

	firestoreClient, err = app.Firestore(ctx)
	if err != nil {
		return fmt.Errorf("error initializing firestore client: %v", err)
	}
	return nil
}

// CustomError represents an application error
type CustomError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (e *CustomError) Error() string {
	return e.Message
}

// ValidationError represents a validation error
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// Response represents a standard API response
type Response struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   interface{} `json:"error,omitempty"`
}

// validateEmail checks if the email is valid
func validateEmail(email string) bool {
	if email == "" {
		return false
	}
	
	// Basic email format validation
	if !strings.Contains(email, "@") || !strings.Contains(email, ".") {
		return false
	}
	
	// Check for common email patterns
	if strings.HasPrefix(email, "@") || strings.HasSuffix(email, "@") {
		return false
	}
	
	// Check for multiple @ symbols
	if strings.Count(email, "@") != 1 {
		return false
	}
	
	return true
}

// validatePassword checks if the password meets minimum requirements
func validatePassword(password string) bool {
	if password == "" {
		return false
	}
	
	// Password must be between 8-100 characters
	if len(password) < 8 || len(password) > 100 {
		return false
	}
	
	// Must contain at least one uppercase letter
	hasUpper := false
	for _, c := range password {
		if c >= 'A' && c <= 'Z' {
			hasUpper = true
			break
		}
	}
	if !hasUpper {
		return false
	}
	
	// Must contain at least one lowercase letter
	hasLower := false
	for _, c := range password {
		if c >= 'a' && c <= 'z' {
			hasLower = true
			break
		}
	}
	if !hasLower {
		return false
	}
	
	// Must contain at least one number
	hasNumber := false
	for _, c := range password {
		if c >= '0' && c <= '9' {
			hasNumber = true
			break
		}
	}
	if !hasNumber {
		return false
	}
	
	return true
}

// initDatabase initializes the database schema and indexes
func initDatabase() error {
	// Create users table
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id INT AUTO_INCREMENT PRIMARY KEY,
			email VARCHAR(255) NOT NULL UNIQUE,
			password VARCHAR(255) NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX idx_email (email)
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create users table: %v", err)
	}

	// Create contacts table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS contacts (
			id INT AUTO_INCREMENT PRIMARY KEY,
			user_id INT NOT NULL,
			name VARCHAR(255) NOT NULL,
			phone VARCHAR(255) NOT NULL,
			encrypted_phone VARCHAR(255) NOT NULL,
			tags VARCHAR(255) DEFAULT '',
			last_interaction DATETIME DEFAULT NULL,
			birthday DATE DEFAULT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
			INDEX idx_user_id (user_id),
			INDEX idx_tags (tags),
			INDEX idx_last_interaction (last_interaction),
			INDEX idx_birthday (birthday)
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create contacts table: %v", err)
	}

	// Create share_links table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS share_links (
			id INT AUTO_INCREMENT PRIMARY KEY,
			token VARCHAR(36) NOT NULL UNIQUE,
			contact_id INT NOT NULL,
			user_id INT NOT NULL,
			expires_at DATETIME NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE,
			FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
			INDEX idx_token (token),
			INDEX idx_expires_at (expires_at)
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create share_links table: %v", err)
	}

	return nil
}

func main() {
	config = LoadConfig()

	// Validate required configuration
	if config.JWTSecret == "" {
		logger.Fatal("JWT_SECRET environment variable is required")
	}
	if config.DBPassword == "" {
		logger.Fatal("DB_PASSWORD environment variable is required")
	}

	// Initialize database with connection pooling
	var err error
	db, err = sql.Open("mysql", fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
		config.DBUser, config.DBPassword, config.DBHost, config.DBPort, config.DBName))
	if err != nil {
		logger.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Initialize Firebase
	if err := initFirebase(config.FirebaseConfig); err != nil {
		log.Fatal(err)
	}

	// Initialize database schema
	if err := initDatabase(); err != nil {
		log.Fatal(err)
	}

	// Create and configure router
	r := gin.Default()

	// Security Headers Middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("X-Frame-Options", "DENY")
		c.Writer.Header().Set("X-Content-Type-Options", "nosniff")
		c.Writer.Header().Set("X-XSS-Protection", "1; mode=block")
		c.Writer.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Writer.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		c.Next()
	})

	// CORS configuration
	corsConfig := cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}

	// Rate limiting configuration
	rateLimiter := NewRateLimiter(rate.Limit(100), 100) // 100 requests per second

	// API Routes
	r.Use(LoggerMiddleware())
	r.Use(cors.New(corsConfig))
	r.Use(rateLimiter.RateLimit())
	r.POST("/signup", signup)
	r.POST("/login", login)

	// Protected routes
	auth := r.Group("/")
	auth.Use(authMiddleware)
	{
		auth.POST("/contacts", addContact)
		auth.GET("/contacts", getContacts)
		auth.PUT("/contacts/:id/tags", updateContactTags)
		auth.PUT("/contacts/:id/last-interaction", updateLastInteraction)
		auth.PUT("/contacts/:id/birthday", updateBirthday)
		auth.POST("/backup", backupContacts)
			protected.POST("/contacts/:id/last-interaction", updateLastInteraction)
			protected.POST("/contacts/:id/birthday", updateBirthday)
			protected.POST("/backup", backupContacts)
		}
	}

	// Start server
	logger.Printf("Server starting on port %s", config.ServerPort)
	if err := r.Run(":" + config.ServerPort); err != nil {
		logger.Fatal("Failed to start server:", err)
	}
}

func signup(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "Invalid request format",
		})
		return
	}

	// Validate email and password
	if !validateEmail(user.Email) {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: ValidationError{
				Field:   "email",
				Message: "Invalid email format",
			},
		})
		return
	}

	if !validatePassword(user.Password) {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: ValidationError{
				Field:   "password",
				Message: "Password must be at least 8 characters long",
			},
		})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to process password",
		})
		return
	}

	_, err = db.Exec("INSERT INTO users (email, password) VALUES (?, ?)", user.Email, string(hashedPassword))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "Email already exists",
		})
		return
	}

	c.JSON(http.StatusOK, Response{
	})
}

func login(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
		})
		return
	}

	// Validate required fields
	if user.Email == "" || user.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Email and password are required",
		})
		return
	}

	// Check if user exists
	var storedUser User
	if err := db.Get(&storedUser, "SELECT * FROM users WHERE email = ?", user.Email); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Invalid credentials",
		})
		return
	}

	// Compare passwords
	if err := bcrypt.CompareHashAndPassword([]byte(storedUser.Password), []byte(user.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Invalid credentials",
		})
		return
	}

	// Generate JWT token
	claims := &Claims{
		UserID: storedUser.ID,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().Add(time.Hour * 24).Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to generate token",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"token":   tokenString,
		"message": "Logged in successfully",
	})
	tokenString := c.GetHeader("Authorization")
	if tokenString == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
		c.Abort()
		return
	}

	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})

	if err != nil || !token.Valid {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
		c.Abort()
		return
	}

	c.Set("user_id", claims.UserID)
	c.Next()
}

func addContact(c *gin.Context) {
	var contact Contact
	if err := c.ShouldBindJSON(&contact); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "Invalid request format",
		})
		return
	}

	// Validate contact data
	if contact.Name == "" {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: ValidationError{
				Field:   "name",
				Message: "Name is required",
			},
		})
		return
	}

	if contact.Phone == "" {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: ValidationError{
				Field:   "phone",
				Message: "Phone number is required",
			},
		})
		return
	}

	if contact.EncryptedPhone == "" {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: ValidationError{
				Field:   "encrypted_phone",
				Message: "Encrypted phone number is required",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	result, err := db.Exec(
		"INSERT INTO contacts (user_id, name, phone, encrypted_phone, tags, last_interaction, birthday) VALUES (?, ?, ?, ?, ?, ?, ?)",
		userID, contact.Name, contact.Phone, contact.EncryptedPhone, contact.Tags, contact.LastInteraction, contact.Birthday,
	)
	if err != nil {
		logger.Printf("Failed to add contact: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to add contact",
		})
		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		logger.Printf("Failed to get last insert ID: %v", err)
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: map[string]interface{}{
			"message": "Contact added successfully",
			"id":      id,
		},
	})
}

func getContacts(c *gin.Context) {
	userID, _ := c.Get("user_id")

	// Get query parameters
	query := c.Query("query")
	tag := c.Query("tag")
	sortBy := c.Query("sort_by")
	order := c.Query("order")

	// Build the query
	sqlQuery := "SELECT id, name, phone, encrypted_phone, tags, last_interaction, birthday FROM contacts WHERE user_id = ?"
	args := []interface{}{userID}

	if query != "" {
		sqlQuery += " AND (name LIKE ? OR phone LIKE ?)"
		args = append(args, "%"+query+"%", "%"+query+"%")
	}

	if tag != "" {
		sqlQuery += " AND tags LIKE ?"
		args = append(args, "%"+tag+"%")
	}

	// Add sorting
	if sortBy != "" {
		validSortFields := map[string]string{
			"name":             "name",
			"last_interaction": "last_interaction",
			"birthday":         "birthday",
		}
		if sortField, ok := validSortFields[sortBy]; ok {
			sqlQuery += " ORDER BY " + sortField
			if order == "desc" {
				sqlQuery += " DESC"
			}
		}
	}

	rows, err := db.Query(sqlQuery, args...)
	if err != nil {
		logger.Printf("Failed to fetch contacts: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to fetch contacts",
		})
		return
	}
	defer rows.Close()

	var contacts []Contact
	for rows.Next() {
		var contact Contact
		if err := rows.Scan(
			&contact.ID, &contact.Name, &contact.Phone, &contact.EncryptedPhone,
			&contact.Tags, &contact.LastInteraction, &contact.Birthday,
		); err != nil {
			logger.Printf("Failed to scan contact: %v", err)
			c.JSON(http.StatusInternalServerError, Response{
				Success: false,
				Error:   "Failed to process contacts",
			})
			return
		}
		contacts = append(contacts, contact)
	}

	if err := rows.Err(); err != nil {
		logger.Printf("Error iterating contacts: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to process contacts",
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    contacts,
	})
}

func updateContactTags(c *gin.Context) {
	contactID := c.Param("id")
	userID, _ := c.Get("user_id")

	var update ContactUpdate
	if err := c.ShouldBindJSON(&update); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "Invalid request format",
		})
		return
	}

	// Verify contact ownership
	var exists bool
	err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM contacts WHERE id = ? AND user_id = ?)", contactID, userID).Scan(&exists)
	if err != nil {
		logger.Printf("Failed to verify contact ownership: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to verify contact",
		})
		return
	}

	if !exists {
		c.JSON(http.StatusNotFound, Response{
			Success: false,
			Error:   "Contact not found",
		})
		return
	}

	// Update tags
	tags := strings.Join(update.Tags, ",")
	_, err = db.Exec("UPDATE contacts SET tags = ? WHERE id = ? AND user_id = ?", tags, contactID, userID)
	if err != nil {
		logger.Printf("Failed to update tags: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to update tags",
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    "Tags updated successfully",
	})
}

func updateLastInteraction(c *gin.Context) {
	contactID := c.Param("id")
	userID, _ := c.Get("user_id")

	var update ContactUpdate
	if err := c.ShouldBindJSON(&update); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "Invalid request format",
		})
		return
	}

	// Verify contact ownership
	var exists bool
	err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM contacts WHERE id = ? AND user_id = ?)", contactID, userID).Scan(&exists)
	if err != nil {
		logger.Printf("Failed to verify contact ownership: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to verify contact",
		})
		return
	}

	if !exists {
		c.JSON(http.StatusNotFound, Response{
			Success: false,
			Error:   "Contact not found",
		})
		return
	}

	// Update last interaction
	_, err = db.Exec("UPDATE contacts SET last_interaction = ? WHERE id = ? AND user_id = ?", update.LastInteraction, contactID, userID)
	if err != nil {
		logger.Printf("Failed to update last interaction: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to update last interaction",
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    "Last interaction updated successfully",
	})
}

func updateBirthday(c *gin.Context) {
	contactID := c.Param("id")
	userID, _ := c.Get("user_id")

	var update ContactUpdate
	if err := c.ShouldBindJSON(&update); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "Invalid request format",
		})
		return
	}

	// Validate birthday format
	if update.Birthday != "" {
		if _, err := time.Parse("2006-01-02", update.Birthday); err != nil {
			c.JSON(http.StatusBadRequest, Response{
				Success: false,
				Error: ValidationError{
					Field:   "birthday",
					Message: "Invalid birthday format. Use YYYY-MM-DD",
				},
			})
			return
		}
	}

	// Verify contact ownership
	var exists bool
	err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM contacts WHERE id = ? AND user_id = ?)", contactID, userID).Scan(&exists)
	if err != nil {
		logger.Printf("Failed to verify contact ownership: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to verify contact",
		})
		return
	}

	if !exists {
		c.JSON(http.StatusNotFound, Response{
			Success: false,
			Error:   "Contact not found",
		})
		return
	}

	// Update birthday
	_, err = db.Exec("UPDATE contacts SET birthday = ? WHERE id = ? AND user_id = ?", update.Birthday, contactID, userID)
	if err != nil {
		logger.Printf("Failed to update birthday: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to update birthday",
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    "Birthday updated successfully",
	})
}

func backupContacts(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var backupReq BackupRequest
	if err := c.ShouldBindJSON(&backupReq); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "Invalid request format",
		})
		return
	}

	// Validate contacts
	if len(backupReq.Contacts) == 0 {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error:   "No contacts to backup",
		})
		return
	}

	ctx := context.Background()
	batch := firestoreClient.Batch()
	userRef := firestoreClient.Collection("users").Doc(fmt.Sprintf("%d", userID))
	contactsRef := userRef.Collection("contacts")

	// Delete existing contacts
	existingContacts, err := contactsRef.Documents(ctx).GetAll()
	if err != nil {
		logger.Printf("Failed to fetch existing contacts: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to fetch existing contacts",
		})
		return
	}

	for _, doc := range existingContacts {
		batch.Delete(doc.Ref)
	}

	// Add new contacts
	for _, contact := range backupReq.Contacts {
		contactData := map[string]interface{}{
			"name":             contact.Name,
			"phone":            contact.Phone,
			"encrypted_phone":  contact.EncryptedPhone,
			"tags":             contact.Tags,
			"last_interaction": contact.LastInteraction,
			"birthday":         contact.Birthday,
			"backup_timestamp": time.Now(),
		}
		docRef := contactsRef.NewDoc()
		batch.Set(docRef, contactData)
	}

	// Commit the batch
	_, err = batch.Commit(ctx)
	if err != nil {
		logger.Printf("Failed to backup contacts: %v", err)
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error:   "Failed to backup contacts",
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: map[string]interface{}{
			"message":        "Backup completed successfully",
			"contacts_count": len(backupReq.Contacts),
			"timestamp":      time.Now(),
		},
	})
}
