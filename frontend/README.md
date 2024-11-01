# Using the Flutter DApp Frontend

This decentralized application (DApp) has been developed using Flutter framework to implement a Self-Sovereign Identity (SSI) system using DIDs on Algorand blockchain.

## Prerequisites

- Flutter SDK version 3.3.0 or higher
- A Flutter-compatible IDE (Android Studio, VS Code, etc.)
- An Android device in developer mode or an Android emulator in Android Studio
- Pera Wallet installed for Algorand interaction

## Installation and Launching

```bash
1. Clone the DApp Git repository:
git clone https://github.com/Ty-HA/algorand-did-hackathon.git

2. Navigate to the project directory:
cd algorand-did-hackathon/frontend

3. Install the Flutter dependencies:
flutter pub get

4. Launch the app in development mode:
flutter run
```

You should see the application launch on your Android emulator or your Android device in developer mode.

## Features

### Identity Management
- Create and manage Decentralized Identifiers (DIDs) on Algorand
- Connect with Pera Wallet for secure blockchain interactions
- View your DID information and status
- Track your identity verification score

### Credential Management
- Store and manage verifiable credentials
- University degree verification
- View credential details including:
  - Issuer information
  - Issue date
  - Verification status
  - Blockchain transaction verification on Pera Explorer

### Verification System
- QR code scanning for credential verification
- Secure verification process for educational credentials
- Real-time verification status updates
- Transaction tracking on Algorand network

## Usage

### Initial Setup
1. Launch the application
2. Connect your Pera Wallet when prompted
3. Complete the initial verification process

### Managing Credentials
1. Navigate to the Credentials tab
2. View your existing credentials and their status
3. Add new credentials using the "+" button
4. Verify credentials by scanning QR codes

### Viewing Credential Details
1. Tap on any credential to view details
2. Check verification status and issuer information
3. View blockchain transaction details through Pera Explorer
4. Share credentials when needed

### Identity Score
- Track your identity verification progress
- View detailed breakdown of verification status
- Monitor active credentials and their validity

## Security Features
- Secure connection with Pera Wallet
- Encrypted credential storage
- Blockchain-based verification
- Privacy-preserving identity management

## Technical Stack
- Flutter Frontend Framework
- Algorand Blockchain
- Pera Wallet Integration
- Mobile Scanner for QR verification

## Support and Updates
For support or feature requests, please create an issue in the GitHub repository.