# 🔥 Firebase Setup Guide for Orion App

## What You Need to Do

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `orion-trading-app` (or your preferred name)
4. **Disable** Google Analytics (optional, you can enable later)
5. Click **"Create project"**
6. Wait for project to be created, then click **"Continue"**

### Step 2: Add Web App to Firebase

1. In Firebase Console, click the **Web icon** (`</>`) or **"Add app"** → **Web**
2. Register app:
   - App nickname: `Orion Web App`
   - **DO NOT** check "Also set up Firebase Hosting" (unless you want it)
3. Click **"Register app"**
4. **Copy the Firebase configuration** - you'll see something like:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSy...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc123"
   };
   ```
5. **Save this config** - you'll need it in Step 4

### Step 3: Enable Authentication

1. In Firebase Console, go to **"Authentication"** (left sidebar)
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable these providers:
   - **Email/Password**: Click → Enable → Save
   - **Google**: Click → Enable → Add your support email → Save

### Step 4: Enable Firestore Database

1. In Firebase Console, go to **"Firestore Database"** (left sidebar)
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select a location (choose closest to your users)
5. Click **"Enable"**

### Step 5: Install FlutterFire CLI

Open terminal and run:

```bash
dart pub global activate flutterfire_cli
```

### Step 6: Configure Flutter App

1. **Navigate to your project root**:
   ```bash
   cd "/Users/akulnehra/Desktop/Orion Cursor/OrionScreens-master"
   ```

2. **Run FlutterFire configure**:
   ```bash
   flutterfire configure
   ```

3. **Select your Firebase project** from the list
4. **Select platforms**: Choose `web` (and `ios`/`android` if needed)
5. This will create `lib/firebase_options.dart` automatically

### Step 7: Update main.dart

The `firebase_options.dart` file will be created automatically. Now uncomment the Firebase initialization in `lib/main.dart`:

```dart
// In lib/main.dart, replace the commented section with:
try {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  }
} catch (e) {
  print('⚠️ Firebase not configured (using local storage only): $e');
}
```

And add the import at the top:
```dart
import 'firebase_options.dart';
```

### Step 8: Set Firestore Security Rules (IMPORTANT!)

1. In Firebase Console, go to **"Firestore Database"** → **"Rules"** tab
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Leaderboard - users can read all, write only their own
    match /leaderboards/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
    
    // Stock cache - read only for authenticated users
    match /stock_cache/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **"Publish"**

### Step 9: Test It!

Run your app:
```bash
flutter run -d chrome
```

You should see: `✅ Firebase initialized successfully` in the console.

---

## What You DON'T Need from Supabase

**You don't need Supabase!** We're using:
- **Firebase Firestore** for database (not Supabase)
- **Firebase Auth** for authentication (not Supabase Auth)
- **SharedPreferences** as local fallback

---

## Summary Checklist

- [ ] Created Firebase project
- [ ] Added Web app to Firebase
- [ ] Copied Firebase config
- [ ] Enabled Email/Password authentication
- [ ] Enabled Google Sign-In
- [ ] Created Firestore database
- [ ] Installed FlutterFire CLI
- [ ] Ran `flutterfire configure`
- [ ] Updated `main.dart` with Firebase initialization
- [ ] Set Firestore security rules
- [ ] Tested the app

---

## Need Help?

- Firebase Docs: https://firebase.google.com/docs
- FlutterFire Docs: https://firebase.flutter.dev/
- If you get errors, check the console output for specific error messages

---

## Current Status

✅ **App works WITHOUT Firebase** - uses local storage (SharedPreferences)
✅ **All features work offline**
✅ **When Firebase is configured**, data will sync to cloud automatically






