Below is the **README.md** content formatted as a raw code block that you can directly copy and paste into your project's README file on GitHub. It includes the original content you provided, with added sections for **MongoDB connection troubleshooting** and **APK build instructions** to make it deployment-ready, as you requested.

```markdown
# Real-Time Chat Application with Authentication  
**Tech Stack:** Flutter, Dart, Bloc, MVVM, Node.js, Express, MongoDB, Socket.IO, JWT  

## 📌 Overview  
A 1-on-1 real-time chat application with secure user authentication, built with **Flutter** (frontend) and **Node.js + MongoDB** (backend) using **Socket.IO** for instant communication.  

## 📂 Project Structure  

```
root/
│
├── frontend/   # Flutter app (Bloc + MVVM)
│   ├── models/
│   ├── services/
│   ├── viewmodels/
│   ├── views/
│   ├── blocs/
│   └── pubspec.yaml
│
└── backend/    # Node.js + Express + MongoDB API
    ├── models/
    ├── routes/
    ├── controllers/
    ├── server.js
    ├── package.json
    └── .env.example
```

## ⚙️ Backend Setup (Node.js + MongoDB)

### 1. Prerequisites
- **Node.js** ≥ 16.x  
- **MongoDB** (local or hosted e.g. [MongoDB Atlas](https://www.mongodb.com/atlas))  

### 2. Installation
```bash
cd backend
npm install
```

### 3. Environment Variables
Create a `.env` file in `backend/` with:
```env
PORT=5000
MONGO_URI=mongodb://localhost:27017/chat_app
JWT_SECRET=your_jwt_secret
```
> If using MongoDB Atlas, replace `MONGO_URI` with your connection string.

### 4. Run Backend
```bash
# Development
npm run dev

# Production
npm start
```
Backend runs by default at:
```
http://localhost:5000
```

## 📱 Frontend Setup (Flutter + Bloc)

### 1. Prerequisites
- **Flutter SDK** ≥ 3.x ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart** ≥ 2.17
- Android/iOS emulator or a physical device

### 2. Installation
```bash
cd frontend
flutter pub get
```

### 3. Backend URL Config
In your Flutter project, set the backend base URL in your API service file (e.g., `lib/services/api_service.dart`):
```dart
const String baseUrl = "http://localhost:5000"; 
```
> If running on a physical device, replace `localhost` with your machine's local IP (e.g., `192.168.1.10`).

### 4. Run Frontend
```bash
flutter run
```

## 🔑 API Documentation

### Auth
#### `POST /api/auth/signup`
**Body:**
```json
{
  "email": "test@example.com",
  "password": "123456"
}
```

#### `POST /api/auth/login`
**Body:**
```json
{
  "email": "test@example.com",
  "password": "123456"
}
```
**Response:**
```json
{
  "token": "jwt_token_here",
  "user": {
    "_id": "user_id",
    "email": "test@example.com"
  }
}
```

### Chat
#### Socket.IO Events
- **connect**: Connects user (JWT handshake)
- **chat-message**: Send message to specific user
- **disconnect**: Disconnect user

## 🏗 Architecture

### Frontend
- **MVVM** pattern
- **Bloc** for state management
- Organized into:
  - `models/`
  - `services/`
  - `viewmodels/`
  - `views/`
  - `blocs/`

### Backend
- **Express.js** REST APIs
- **MongoDB** for users & messages
- **JWT** authentication middleware
- **Socket.IO** for real-time events

## 📦 Deliverables
- Public GitHub repo with **frontend** & **backend** folders
- APK file in `/apk/` or Google Drive link
- Video demo (if backend is local)

## 👤 Example Users
| Email                                         | Password |
|-----------------------------------------------|----------|
| [user1@example.com](mailto:user1@example.com) | 123456   |
| [user2@example.com](mailto:user2@example.com) | 123456   |

## 🚀 Quick Start
```bash
# 1. Start backend
cd backend
npm install
npm run dev

# 2. Start frontend
cd frontend
flutter pub get
flutter run
```

## 🛠 MongoDB Connection Troubleshooting
- **Local MongoDB**: Ensure MongoDB is running (`mongod` service). Check with:
  ```bash
  mongo --eval "db.version()"
  ```
- **MongoDB Atlas**: Verify your IP is whitelisted in Atlas Network Access. Use the correct connection string format:
  ```env
  MONGO_URI=mongodb+srv://<username>:<password>@cluster0.mongodb.net/chat_app?retryWrites=true&w=majority
  ```
- **Connection Errors**: Check for `MongoNetworkError` or `Timeout`. Ensure port `27017` is open and not blocked by firewall.
- **Logs**: Enable verbose logging in `server.js` to debug:
  ```javascript
  mongoose.set('debug', true);
  ```

## 📲 APK Build Instructions
1. Ensure Flutter is configured for your target platform (Android).
2. Update `android/app/build.gradle` with correct signing configs.
3. Build the APK:
   ```bash
   cd frontend
   flutter build apk --release
   ```
4. Find the APK in:
   ```
   frontend/build/app/outputs/flutter-apk/app-release.apk
   ```
5. Optionally, upload to `/apk/` folder or share via Google Drive.

```

---

You can copy this entire code block and paste it into your `README.md` file in your GitHub repository. It’s fully formatted for GitHub’s Markdown renderer and includes all the necessary details for setting up, running, and troubleshooting the project, along with the APK build instructions. Let me know if you need any additional sections or modifications!
