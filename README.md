# Pawtner App

A Flutter-based Animal Welfare Application.
This project helps locate lost pets using QR codes and image recognition, and connects users with nearby NGOs and veterinary services.

## Features
- QR-based pet identification
- Lost pet reporting system
- Nearby NGO and vet search
- Emergency first aid guidance
- AI-based pet image recognition

## Installation and setup
 1. Clone the Repository

```bash
git clone https://github.com/dik480/Final-project.git

### 2. Navigate to Project Folder
cd pawtner_app

3. Install Flutter Dependencies

4. Configure Firebase
-Create a Firebase project
-Add Android app in Firebase Console
-Download google-services.json
-Place it inside:android/app/

5. Enable Firebase Services
  Enable:
    -Authentication
    -Cloud Firestore
    -Firebase Storage
6. Add Google Maps API Key
Open:
android/app/src/main/AndroidManifest.xml
Add your API key inside:
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>

7. Run the Application

## Author
Dikshant Shrestha
Final year project
Pawtner-An animal welfare application

