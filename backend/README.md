# Algorand DID Management System

A decentralized identity management system built on the Algorand blockchain.

## Features

- DID Creation and Registration
- DID Resolution
- DID Document Management
- Verifiable Credentials Issuance and Verification
- Box Storage for DID Documents and Credentials

## Prerequisites

- Python 3.8+
- Algorand TestNet account
- Node.js and npm (for frontend)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/algorand-did-hackathon.git
cd algorand-did-hackathon
```

2. Create and activate a virtual environment:
```bash
python -m venv myenv
source myenv/bin/activate  # On Windows: myenv\Scripts\activate
```

3. Install dependencies:
```bash
cd backend
pip install -r requirements.txt
```

## Smart Contract Deployment

1. Deploy the smart contract:
```bash
python scripts/deploy_contract.py
```

2. Update the APP_ID in src/core/config.py with the deployed contract ID.

## Running the Backend

Start the FastAPI server:
```bash
uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000
```

## Usage

### DID Registration

Register a new DID:
```bash
curl -X POST http://localhost:8000/register \
  -H "Content-Type: application/json" \
  -d '{
    "address": "YOUR_ALGORAND_ADDRESS",
    "user_info": {
      "name": "John Doe",
      "email": "john@example.com",
      "age": 30,
      "created_at": "2024-11-01"
    }
  }'
```

### DID Resolution

Resolve a DID:
```bash
curl http://localhost:8000/resolve/did:algo:YOUR_DID_SUFFIX
```

### Credential Management

1. Issue a Verifiable Credential:
```bash
curl -X POST http://localhost:8000/issue_credential \
  -H "Content-Type: application/json" \
  -d '{
    "category": "Education",
    "subject": "Bachelor of Computer Science",
    "issuer_name": "University of Technology",
    "issuer_did": "did:algo:ISSUER_ADDRESS",
    "period": {
      "start": "2024-01-01",
      "end": "2024-12-31"
    },
    "destinator_did": "did:algo:RECIPIENT_ADDRESS",
    "metadata": {
      "grade": "A",
      "credits": 120,
      "institution": "University of Technology",
      "program": "Computer Science",
      "specialization": "Software Engineering"
    }
  }'
```

2. Verify a Credential:
```bash
curl http://localhost:8000/verify_credential/{credential_hash}
```

## Project Structure

```
backend/
├── src/
│   ├── core/            # Core configuration and utilities
│   ├── did/             # DID management functionality
│   ├── credentials/     # Credential management
│   ├── auth/           # Authentication
│   └── api/            # FastAPI application and routes
├── contracts/          # Smart contracts
├── scripts/           # Deployment scripts
└── logs/             # Deployment and account logs
```

## Features in Detail

### DID Management
- Create and register DIDs on Algorand TestNet
- Resolve DIDs to retrieve DID Documents
- Update DID Documents
- Box storage for DID Documents

### Credential Management
- Issue Verifiable Credentials
- Store credentials using box storage
- Verify credential authenticity
- Support for various credential types
- Metadata and custom attributes

### Storage
- On-chain storage using Algorand boxes
- Efficient storage management
- Secure and verifiable data storage

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
