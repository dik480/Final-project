# Pawtner Dynamic QR Code System

This is a standalone Node.js and Express application designed to serve the dynamic QR Code logic for the Pawtner app, without requiring any modifications to the existing Flutter application.

## Overview
This backend connects directly to your existing Firebase Firestore database securely via the Firebase Admin SDK. It serves the web fallbacks for QR scans and provides an API for reading/writing.

## Getting Started

### Prerequisites
- Node.js installed on your server or local machine (v16+. npm is required)
- Firebase Service Account Key JSON file from the Firebase console

### Installation

1. Copy this folder to your server.
2. Run to install dependencies:
   ```bash
   npm install
   ```
3. Copy your `serviceAccountKey.json` into this directory or root path.
4. Update `config/firebase_config.js` to point to your `serviceAccountKey.json` to authenticate the Admin SDK.

### Usage

**Starting the Server:**
```bash
npm start
```
By default, the server runs on port `3000`. You can change this using the `PORT` environment variable.

**Generating QR Codes:**
To generate a new batch of unassigned pet tags:
```bash
npm run generate-qr 5
```
This generates 5 new QR tags and saves them as `.png` images in the `output_qrs/` folder while initializing them in Firestore.

## Endpoints

### APIs
- `GET /api/pet/:qr_id` - Get registration status
- `POST /api/register_pet` - Link pet data and owner info to a QR ID
- `POST /api/share-location` - Share finder's GPS coordinates with the owner

### Web
- `GET /pet/:qr_id` - The public web UI when someone scans the URL. Handles both unassigned (redirecting to download the app) and assigned cases.

## Deep Linking
The `.well-known` directory inside `public/` contains standard App Links (`assetlinks.json`) and Universal Links (`apple-app-site-association`) configurations. Replace the placeholders with your actual app package name, team ID, and signing fingerprints to enable the app to automatically open when scanning `https://pawtner.app/pet/...` URLs.
