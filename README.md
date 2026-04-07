# 🩸 SickleCare Mobile App

A **production-ready Flutter mobile application** designed to help patients manage **Sickle Cell Disease (SCD)** through daily health tracking, smart reminders, and support tools.

This project has evolved from a simple demo into a **full health management system** with real-time Firebase integration.

---

## 🚀 Features

### 🔐 Authentication

* Secure user signup & login (Firebase Auth)
* Persistent sessions

### 🏠 Dashboard

* Daily health overview
* Hydration tracking
* Pain level monitoring
* Meals tracking

### 💧 Health Tracking

* Log hydration (liters)
* Track meals (nutrition)
* Record pain levels (0–10 scale)
* Real-time sync with Firestore

### 📊 Analytics (History Screen)

* Visual charts (Pain & Hydration trends)
* Daily logs history
* Data-driven insights

### ⏰ Smart Reminders

* Schedule reminders (medication, food, water)
* Works like real alarm notifications
* Mark reminders as completed (habit tracking)
* Stored in Firebase

### 💬 Support Center

* In-app chat system
* Basic AI assistant (auto responses)
* Emergency contact (one-tap call)
* Dynamic FAQs (admin-controlled)

### 🧭 Navigation

* Reusable global drawer across all screens
* Smooth navigation between features

---

## 🧱 Tech Stack

* **Flutter (Dart)**
* **Firebase**

  * Authentication
  * Cloud Firestore (Database)
* **Flutter Local Notifications**
* **fl_chart (Analytics)**
* **Google Fonts**

---

## 📁 Project Structure

```
lib/
├── screens/
│   ├── home_screen.dart
│   ├── hydration_nutrition_screen.dart
│   ├── tracker_screen.dart
│   ├── reminders_screen.dart
│   ├── history_screen.dart
│   ├── support_screen.dart
│
├── widgets/
│   └── app_drawer.dart
│
├── services/
│   └── notification_service.dart
│
├── main.dart
```

---

## 🔥 Firebase Structure

```
users/{uid}/
  ├── daily/{date}
  │     ├── hydration
  │     ├── painLevel
  │     ├── meals[]
  │     ├── updatedAt
  │
  ├── reminders/{reminderId}
  │     ├── title
  │     ├── hour
  │     ├── minute
  │     ├── completed
  │
  ├── support_messages/
        └── messages/
```

---

## ⚙️ Getting Started

### Prerequisites

* Flutter SDK >= 3.0
* Dart >= 3.0
* Android Studio / VS Code
* Firebase project setup

---

### Installation

```bash
git clone https://github.com/NgwinaQuinstarics/sicklecare-mobile.git
cd sicklecare-mobile
flutter pub get
```

---

### Run the App

```bash
flutter run
```

---

## 🧪 Current Status

✅ Core features implemented
✅ Firebase fully integrated
✅ Notifications working
✅ Analytics dashboard active

🚧 Upcoming:

* Admin Panel (manage users, FAQs, support)
* Advanced AI assistant
* Cloud sync optimization
* Production deployment

---

## 🎯 Vision

SickleCare aims to become a **complete digital companion for SCD patients**, helping them:

* Prevent crises through monitoring
* Stay consistent with medication
* Access support instantly
* Track long-term health trends

---

## 👨‍💻 Author

**Ngwina Quinstarics**

---

## 📄 License

This project is for educational and development purposes. Licensing will be updated for production release.
