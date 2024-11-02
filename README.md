# Nexus ID: Self-Sovereign Identity Solution on Algorand

## Project Description
Nexus ID is a self-sovereign identity (SSI) solution that empowers individuals worldwide by providing secure, verifiable identities on the Algorand blockchain. The platform addresses the global identity crisis affecting those currently or potentially excluded from financial services, education, and basic rights. By creating Decentralized Identifiers (DIDs) and building a network of trusted third parties (TTPs) to issue verifiable credentials, Nexus ID helps users build real-world credibility through a DID scoring model, unlocking opportunities and financial inclusion.

## Quick Links
- [Pitch Deck](https://www.canva.com/design/DAGVRrGmpfw/q6hW9iEC5Z53eMtbbnI_cA/edit)
- [Demo Video](https://youtu.be/NGqYQVheOsE)

## Team

| Name | Role | LinkedIn |
|------|------|----------|
| Emilie Thebault | SSI Expert | [Profile](https://www.linkedin.com/in/emilie-thebault-33a7a512a/) |
| Ty Ha | Web3 Full Stack Developer | [Profile](https://www.linkedin.com/in/ty-ha/) |
| Yue | Full Stack Programmer | [Profile](https://www.linkedin.com/in/yueculture/) |

## Project Structure
```
.
├── backend/                 # Backend API and smart contracts
│   ├── contracts/          # Algorand smart contracts
│   ├── src/               # Core backend functionality
│   │   ├── api/          # FastAPI endpoints
│   │   ├── auth/         # Authentication
│   │   ├── did/          # DID management
│   │   └── credentials/  # Credential management
│   └── tests/            # Backend tests
└── frontend/              # Flutter mobile application
    ├── lib/              # Application source code
    │   ├── models/       # Data models
    │   ├── screens/      # UI screens
    │   ├── services/     # Backend services
    │   └── widgets/      # Reusable UI components
    └── test/             # Frontend tests
```

## Technical Stack

### Backend
- Python FastAPI
- Algorand SDK
- PyTEAL for smart contracts
- JWT Authentication
- PostgreSQL Database

### Frontend
- Flutter Framework
- Pera Wallet Integration
- Mobile Scanner for QR verification
- Material Design UI

### Infrastructure
- Docker containerization
- GitHub Actions CI/CD
- Algorand TestNet

## Deployed Contracts (TestNet)

| Contract Type | Transaction ID | Explorer Link |
|--------------|----------------|---------------|
| DID Creation | 7H3BDT6JMZBX4JU5CLE7GWRRK7R7V4OB6YCG7INY6TDH4VCN4MHA | [View](https://testnet.explorer.perawallet.app/tx/7H3BDT6JMZBX4JU5CLE7GWRRK7R7V4OB6YCG7INY6TDH4VCN4MHA/) |
| Credential Creation | 232C55242AQRRNFVE6QVBXQPGUZYVL5BMY6PWKKBYSBD22Z3U6BA | [View](https://testnet.explorer.perawallet.app/tx/232C55242AQRRNFVE6QVBXQPGUZYVL5BMY6PWKKBYSBD22Z3U6BA/) |

## Installation and Setup

### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn src.api.main:app --reload
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

## Features

### Identity Management
- DID Creation and Registration
- DID Resolution and Updates
- Identity Score System
- Secure Document Storage

### Credential System
- Verifiable Credential Issuance
- QR-based Verification
- Credential Revocation
- Multi-party Trust Framework

## Authors

- [@cduchinois](https://github.com/cduchinois)
- [@Ty-HA](https://github.com/Ty-HA/)
- Emilie Thebault

---
All rights reserved to Nexus ID © 2024
