# Algorand DID Backend

A decentralized identity (DID) management system built on Algorand TestNet.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Create necessary directories:
```bash
mkdir -p logs/accounts
mkdir -p logs/deployments
```

## 1. Deploy Contract

The deployment process involves:
1. Creating a deployer account
2. Funding it from TestNet faucet
3. Deploying the DID management contract

```bash
# Deploy the contract
python scripts/deploy_contract.py
```

This will:
- Create a new Algorand account
- Show you the address to fund
- Wait for you to fund it at https://bank.testnet.algorand.network/
- Deploy the contract
- Save deployment info to logs/deployments/deployment_info.json
- Show you the APP_ID to update in config.py

After deployment:
1. Copy the APP_ID from the output
2. Update config.py with your APP_ID:
```python
# config.py
APP_ID = YOUR_APP_ID  # Replace with the deployed app ID
```

## 2. Create Algorand Account

You can create new accounts using the account generator:

```bash
python scripts/generate_account.py
```

This interactive script allows you to:
1. Create new accounts
2. List existing accounts
3. Get account details
4. Save account info to logs/accounts/accounts_record.json

The generated accounts can be used for DID registration.

## 3. Register DID

Once you have an account, you can register a DID. The registration fees are paid by the deployer account.

Using curl:
```bash
curl -X POST http://localhost:8000/register \
  -H "Content-Type: application/json" \
  -d '{
    "address": "YOUR_ACCOUNT_ADDRESS"
  }'
```

Using Python:
```python
import requests

response = requests.post(
    "http://localhost:8000/register",
    json={
        "address": "YOUR_ACCOUNT_ADDRESS"
    }
)
print(response.json())
```

## Directory Structure

```
backend/
├── logs/
│   ├── accounts/
│   │   └── accounts_record.json
│   └── deployments/
│       └── deployment_info.json
├── contracts/
│   ├── approval.teal
│   └── clear.teal
├── scripts/
│   ├── deploy_contract.py
│   └── generate_account.py
└── config.py
```

## Security Notes

Sensitive files are stored in the logs directory and are not committed to git:
- deployment_info.json: Contains deployer account credentials
- accounts_record.json: Contains generated account information

Never share or commit:
- Private keys
- Mnemonics
- Account credentials
- deployment_info.json
- accounts_record.json

## API Endpoints

- POST /register - Register a new DID
- GET /resolve/{did} - Resolve a DID
- PUT /update - Update a DID
- GET /health - Health check

## Development

Start the server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Run tests:
```bash
pytest -v
```

## Example Flow

1. Deploy contract:
```bash
python scripts/deploy_contract.py
# Fund the displayed address at https://bank.testnet.algorand.network/
# Note the APP_ID and update config.py
```

2. Create an account:
```bash
python scripts/generate_account.py
# Choose option 1 to create new account
# Note the generated address
```

3. Register DID:
```bash
curl -X POST http://localhost:8000/register \
  -H "Content-Type: application/json" \
  -d '{
    "address": "YOUR_GENERATED_ADDRESS"
  }'
```

4. Verify DID:
```bash
curl http://localhost:8000/resolve/did:algo:YOUR_GENERATED_ADDRESS
```