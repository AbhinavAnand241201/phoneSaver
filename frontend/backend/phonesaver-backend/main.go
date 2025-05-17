package main

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"golang.org/x/crypto/bcrypt"
	"google.golang.org/api/option"
)

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

var db *sql.DB
var jwtKey = []byte("your_secret_key")
var firestoreClient *firestore.Client

func initFirebase() error {
	ctx := context.Background()
	opt := option.WithCredentialsFile("./firebase-credentials.json")
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

func main() {
	var err error
	db, err = sql.Open("mysql", "root:2844abhi@tcp(127.0.0.1:3306)/phonesaver")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	// Initialize Firebase
	if err := initFirebase(); err != nil {
		panic(err)
	}
	defer firestoreClient.Close()

	r := gin.Default()

	r.POST("/signup", signup)
	r.POST("/login", login)
	r.POST("/contacts", authMiddleware, addContact)
	r.GET("/contacts", authMiddleware, getContacts)
	r.POST("/contacts/:id/tags", authMiddleware, updateContactTags)
	r.POST("/contacts/:id/last-interaction", authMiddleware, updateLastInteraction)
	r.POST("/contacts/:id/birthday", authMiddleware, updateBirthday)
	r.POST("/backup", authMiddleware, backupContacts)

	r.Run(":8080")
}

func signup(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	_, err = db.Exec("INSERT INTO users (email, password) VALUES (?, ?)", user.Email, string(hashedPassword))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email already exists"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User created successfully"})
}

func login(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var storedUser User
	err := db.QueryRow("SELECT id, email, password FROM users WHERE email = ?", user.Email).Scan(&storedUser.ID, &storedUser.Email, &storedUser.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(storedUser.Password), []byte(user.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		UserID: storedUser.ID,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": tokenString})
}

func authMiddleware(c *gin.Context) {
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
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, _ := c.Get("user_id")
	_, err := db.Exec(
		"INSERT INTO contacts (user_id, name, phone, encrypted_phone, tags, last_interaction, birthday) VALUES (?, ?, ?, ?, ?, ?, ?)",
		userID, contact.Name, contact.Phone, contact.EncryptedPhone, contact.Tags, contact.LastInteraction, contact.Birthday,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add contact"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Contact added successfully"})
}

func getContacts(c *gin.Context) {
	userID, _ := c.Get("user_id")
	rows, err := db.Query(
		"SELECT id, name, phone, encrypted_phone, tags, last_interaction, birthday FROM contacts WHERE user_id = ?",
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch contacts"})
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
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan contacts"})
			return
		}
		contacts = append(contacts, contact)
	}

	c.JSON(http.StatusOK, contacts)
}

func updateContactTags(c *gin.Context) {
	contactID := c.Param("id")
	userID, _ := c.Get("user_id")

	var update ContactUpdate
	if err := c.ShouldBindJSON(&update); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify contact ownership
	var exists bool
	err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM contacts WHERE id = ? AND user_id = ?)", contactID, userID).Scan(&exists)
	if err != nil || !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contact not found"})
		return
	}

	// Update tags
	tags := strings.Join(update.Tags, ",")
	_, err = db.Exec("UPDATE contacts SET tags = ? WHERE id = ? AND user_id = ?", tags, contactID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update tags"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tags updated successfully"})
}

func updateLastInteraction(c *gin.Context) {
	contactID := c.Param("id")
	userID, _ := c.Get("user_id")

	var update ContactUpdate
	if err := c.ShouldBindJSON(&update); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify contact ownership
	var exists bool
	err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM contacts WHERE id = ? AND user_id = ?)", contactID, userID).Scan(&exists)
	if err != nil || !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contact not found"})
		return
	}

	// Update last interaction
	_, err = db.Exec("UPDATE contacts SET last_interaction = ? WHERE id = ? AND user_id = ?", update.LastInteraction, contactID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update last interaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Last interaction updated successfully"})
}

func updateBirthday(c *gin.Context) {
	contactID := c.Param("id")
	userID, _ := c.Get("user_id")

	var update ContactUpdate
	if err := c.ShouldBindJSON(&update); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify contact ownership
	var exists bool
	err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM contacts WHERE id = ? AND user_id = ?)", contactID, userID).Scan(&exists)
	if err != nil || !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contact not found"})
		return
	}

	// Update birthday
	_, err = db.Exec("UPDATE contacts SET birthday = ? WHERE id = ? AND user_id = ?", update.Birthday, contactID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update birthday"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Birthday updated successfully"})
}

func backupContacts(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var backupReq BackupRequest
	if err := c.ShouldBindJSON(&backupReq); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := context.Background()
	batch := firestoreClient.Batch()
	userRef := firestoreClient.Collection("users").Doc(fmt.Sprintf("%d", userID))
	contactsRef := userRef.Collection("contacts")

	// Delete existing contacts
	existingContacts, err := contactsRef.Documents(ctx).GetAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("Failed to fetch existing contacts: %v", err),
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
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("Failed to backup contacts: %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        "Backup completed successfully",
		"contacts_count": len(backupReq.Contacts),
		"timestamp":      time.Now(),
	})
}
