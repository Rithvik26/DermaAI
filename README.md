# DermaAI

DermaAI is a secure and intelligent iOS application designed for dermatology professionals to manage patient records, analyze skin conditions, and get AI-powered treatment recommendations.

## UI

<img width="351" alt="Screenshot 2024-12-17 at 7 32 35 PM" src="https://github.com/user-attachments/assets/767d4cbd-00ba-43df-9fe7-d59c0598bc65" />
<img width="351" alt="Screenshot 2024-12-17 at 7 32 45 PM" src="https://github.com/user-attachments/assets/b94d2223-cb9a-4ef7-b94d-45271d756a97" />
<img width="351" alt="Screenshot 2024-12-17 at 7 32 52 PM" src="https://github.com/user-attachments/assets/4250748a-c690-4886-8395-12901605c9f2" />
<img width="351" alt="Screenshot 2024-12-18 at 7 25 34 AM" src="https://github.com/user-attachments/assets/e7cb6454-89d2-4aa9-937d-fcb453d41c1c" />
<img width="351" alt="Screenshot 2024-12-18 at 7 25 44 AM" src="https://github.com/user-attachments/assets/453fec81-2258-473c-bc01-ce4921c84181" />
<img width="351" alt="Screenshot 2024-12-18 at 7 26 02 AM" src="https://github.com/user-attachments/assets/4b5a9401-6757-4d5e-b1ec-89b345d00e8d" />


## Core Features

### Patient Management
- Secure patient record creation and management
- Real-time synchronization across devices
- Offline support for data access

### Authentication Options
- Multiple sign-in options:
  - Email/Password
  - Google Sign-In
  - Apple Sign-In
- Biometric authentication (Face ID/Touch ID)
- Secure password reset functionality

### Diagnosis & Analysis
- AI-powered analysis of skin conditions
- Patient grouping by common conditions
- Treatment recommendations
- Batch analysis capabilities for multiple patients

### Medication Tracking
- Detailed medication management
- Dosage and frequency tracking
- Secure storage of prescription information

## Technical Architecture

### Frontend
- SwiftUI-based user interface
- MVVM architecture
- Responsive design with offline support
- Real-time data updates

### Backend & Services
- Firebase Authentication
- Cloud Firestore for data storage
- Claude API integration for AI analysis
- End-to-end encryption using CryptoKit


## Privacy & Security Features

### End-to-End Encryption
- AES-GCM encryption for all patient data
- Secure key storage in device keychain
- No plaintext data storage
- Encrypted data synchronization across devices

### Access Control
- Multi-factor authentication support
- Biometric authentication (Face ID/Touch ID)
- Role-based access control
- Automatic session timeout
- Secure password policies

### Data Protection
- Local encryption of all patient records
- Encrypted cloud backups
- No third-party access to patient information
- Offline data access with maintained encryption
- Secure data deletion capabilities

### Compliance & Auditing
- Comprehensive audit logging
- Network security monitoring
- Medical data privacy standards compliance
- Regular security audits
- Activity tracking and monitoring

### Network Security
- Secure data transmission
- Real-time network monitoring
- Offline mode support
- Certificate pinning
- Encrypted API communications

  
## Requirements

- Xcode 15.0 or later
- iOS 15.0 or later
- Active internet connection for synchronization
- Firebase project setup
- Claude API key
- Apple Developer account (for Apple Sign In capability)

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd DermaAI
   ```

2. Firebase Setup:
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Create a new Firebase project
   - Add an iOS app to your Firebase project:
     - Register your app with your bundle identifier
     - Download the `GoogleService-Info.plist` file
     - Add the file to your Xcode project (drag and drop into the project navigator)
   - Enable Authentication methods in Firebase Console:
     - Email/Password
     - Google Sign In
     - Apple Sign In

3. Configure Firebase Authentication:
   - In the Firebase Console, go to Authentication > Sign-in method
   - Enable the required authentication providers:
     - Email/Password
     - Google
     - Apple
   - Configure OAuth consent screen if required for Google Sign In

4. Set up API Keys:
   - Create a `.xcconfig` file named `Config.xcconfig`
   - Add your Claude API key:
     ```
     ANTHROPIC_API_KEY=your_api_key_here
     ```
   - Add your Firebase API key:
     ```
     FIREBASE_API_KEY=your_firebase_key_here
     ```
   - In Xcode, link this configuration file to your target

5. Enable Capabilities:
   - In Xcode, select your target and go to the Signing & Capabilities tab
   - Add the following capabilities:
     - Sign in with Apple
     - Keychain Sharing
     - Face ID usage (if required)

6. Update Bundle Identifier:
   - Change the bundle identifier to match your Firebase configuration
   - Update the team and signing settings in Xcode

7. Build and run:
   - Select your target device/simulator
   - Build and run the project in Xcode
   - Verify Firebase initialization in the console output

## Common Setup Issues

1. Firebase initialization fails:
   - Check if `GoogleService-Info.plist` is properly added to the project
   - Verify bundle identifier matches Firebase configuration

2. Authentication fails:
   - Verify OAuth consent screen is properly configured
   - Check if all required authentication methods are enabled in Firebase Console

3. API calls fail:
   - Verify API keys are correctly set in configuration
   - Check network connectivity

## Support

For technical support or feature requests, please create an issue in the repository or contact the development team.

## License

Copyright © 2024 Rithvik Golthi. All rights reserved.


Rithvik Golthi

## Project Status

Active development - Contributions welcome
