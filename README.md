SickleCare Mobile App
A production-ready Flutter mobile application designed to help patients manage Sickle Cell Disease (SCD) through daily health tracking, smart reminders, analytics, and support tools.

🚀 Evolved from a demo app into a full health management ecosystem powered by Firebase
📱 Features
🔐 Authentication System

Secure signup & login using Firebase Auth
Persistent user sessions
Protected routes per user
🏠 Smart Dashboard

Daily health overview
Quick access to all features
Real-time health summary

💧 Health Tracking
Log daily hydration (liters)
Track meals and nutrition
Record pain levels (0–10 scale)
Automatic timestamped entries
Cloud sync via Firestore

📊 Analytics & History
Visual charts using fl_chart
Pain trends over time
Hydration tracking insights
Daily logs history with filtering

⏰ Smart Reminder System
Medication, hydration, and meal reminders
Local notifications (alarm-style)
Mark reminders as completed
Firebase-synced scheduling

💬 Support Center
In-app chat support system
Basic AI auto-responses
Emergency one-tap call feature
FAQ system (admin-controlled content)
🧭 Navigation & UX
Global reusable drawer
Clean and responsive UI
Smooth screen transitions
🧱 Tech Stack
Flutter (Dart)
Firebase
Authentication
Cloud Firestore
Local Notifications
fl_chart (Analytics visualization)
Google Fonts
Material Design UI
📁 Project Structure

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
│   ├── app_drawer.dart
│
├── services/
│   ├── notification_service.dart
│
├── models/   (optional expansion)
├── main.dart
🔥 Firebase Database Structure

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
        ├── messages/
⚙️ Getting Started
1. Prerequisites
Flutter SDK (>= 3.0)
Dart (>= 3.0)
Android Studio / VS Code
Firebase project setup
2. Installation
Bash
git clone https://github.com/NgwinaQuinstarics/sicklecare-mobile.git
cd sicklecare-mobile
flutter pub get
3. Firebase Setup
Create a Firebase project
Add Android/iOS apps
Download google-services.json (Android)
Place it in:

android/app/
Enable:
Authentication (Email/Password)
Cloud Firestore
Firebase rules (secured mode recommended)
4. Run the App
Bash
flutter run
🧪 Current Status
✅ Completed
Authentication system
Health tracking module
Firebase integration
Notifications system
Analytics dashboard
Support center UI

🚧 In Progress / Planned
Admin dashboard (users & FAQs management)
Advanced AI assistant (health insights)
Cloud performance optimization
Production deployment (Play Store release)
🎯 Vision


SickleCare is designed to become a personal health companion for SCD patients, helping users:
Prevent crises through daily monitoring
Stay consistent with treatment
Access emergency support instantly
Understand long-term health patterns


🧠 Architecture Overview
Frontend: Flutter UI (modular screens + reusable widgets)
Backend: Firebase (Auth + Firestore)
Notifications: Local scheduling system
State Flow: Stateless + Firestore-driven updates
📸 Screenshots (Add Later)

/assets/screenshots/
👨‍💻 Author
Ngwina Quinstarics
Flutter Developer
Web & Mobile Systems Builder

📄 License
This project is currently for educational and development purposes.
A production license will be added in future releases.

🚀 Future Upgrade Ideas
AI-powered health predictions
Doctor/patient chat system
Wearable device integration
Offline-first mode
Multi-language support