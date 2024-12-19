# DermaAI

DermaAI is a secure and intelligent iOS application designed for dermatology professionals to manage patient records, analyze skin conditions, and get AI-powered treatment recommendations.

## UI

<img width="351" alt="Screenshot 2024-12-19 at 3 58 15 PM" src="https://github.com/user-attachments/assets/80844b4f-c42b-4234-9a07-97c2c78270db" />
<img width="351" alt="Screenshot 2024-12-19 at 3 58 34 PM" src="https://github.com/user-attachments/assets/cca1237a-820e-49cd-ad78-2ade80054530" />
<img width="351" alt="Screenshot 2024-12-19 at 3 58 41 PM" src="https://github.com/user-attachments/assets/4d3e87df-0ad8-4f3e-b1e2-5d096722df7a" />
<img width="351" alt="Screenshot 2024-12-19 at 3 59 35 PM" src="https://github.com/user-attachments/assets/21c097e5-c75c-47c2-89cd-65db6ec29156" />
<img width="351" alt="Screenshot 2024-12-19 at 3 59 50 PM" src="https://github.com/user-attachments/assets/047e59b6-5416-4445-8353-c0d4833b7b1c" />
<img width="351" alt="Screenshot 2024-12-19 at 3 59 55 PM" src="https://github.com/user-attachments/assets/a4066a20-1663-4738-a4d6-ae2896324979" />
<img width="351" alt="Screenshot 2024-12-19 at 4 00 25 PM" src="https://github.com/user-attachments/assets/8f893d5b-d0c7-4bfc-9a8d-d9cf27132e38" />
<img width="351" alt="Screenshot 2024-12-19 at 4 00 30 PM" src="https://github.com/user-attachments/assets/e43b0d09-7630-4414-ae9e-46b13a34a5b4" />
<img width="351" alt="Screenshot 2024-12-19 at 4 00 40 PM" src="https://github.com/user-attachments/assets/7d5b39c3-b22e-470a-b931-16f301b3bd06" />
<img width="351" alt="Screenshot 2024-12-19 at 4 00 48 PM" src="https://github.com/user-attachments/assets/37bc968f-aca1-4697-938f-6d1421de1857" />
<img width="351" alt="Screenshot 2024-12-19 at 4 00 55 PM" src="https://github.com/user-attachments/assets/6d74042a-d0b0-4f55-9635-11899dc5e8a9" />
<img width="351" alt="Screenshot 2024-12-19 at 4 01 05 PM" src="https://github.com/user-attachments/assets/4e80cea6-80df-4710-9a71-339d95b5ab77" />
<img width="351" alt="Screenshot 2024-12-19 at 4 01 11 PM" src="https://github.com/user-attachments/assets/776854ba-9d13-4c06-ae9f-060b1a308a07" />


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
