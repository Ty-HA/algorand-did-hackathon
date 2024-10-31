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
<<<<<<< HEAD
python registration.py
```

## You can check the logs file to get your Algo wallet address and Passphrase
\backend\logs

## Get Faucets before create Onchain DID with the wallet and Mnemonic
https://bank.testnet.algorand.network/

### 4.3 Test On-chain Verification
```python
python verification_existing_account.py
=======
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
>>>>>>> buildonchainyue
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

<<<<<<< HEAD
### 7.2 Flutter Integration

To interact with these APIs from your Flutter application, you can use the `http` package. Here's how to implement each API call:

1. First, add the `http` package to your `pubspec.yaml`:

   ```yaml
   dependencies:
     http: ^0.13.3
   ```

2. Import the package in your Dart file:

   ```dart
   import 'package:http/http.dart' as http;
   import 'dart:convert';
   ```

3. Implement the API calls:

   ```dart
   class ApiService {
     final String baseUrl = 'http://localhost:8000';  // Replace with your actual API URL

     Future<Map<String, dynamic>> registerUser() async {
       final response = await http.post(Uri.parse('$baseUrl/register'));
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('Failed to register user');
       }
     }

     Future<bool> authenticateUser(String did, String address) async {
       final response = await http.post(
         Uri.parse('$baseUrl/authenticate'),
         headers: {'Content-Type': 'application/json'},
         body: json.encode({'did': did, 'address': address}),
       );
       if (response.statusCode == 200) {
         return true;
       } else if (response.statusCode == 401) {
         return false;
       } else {
         throw Exception('Failed to authenticate user');
       }
     }

     Future<Map<String, dynamic>> displayUserData(String did) async {
       final response = await http.get(Uri.parse('$baseUrl/display/$did'));
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('Failed to fetch user data');
       }
     }

     Future<void> updateDid(String did, {String? newKey, String? newService}) async {
       final response = await http.post(
         Uri.parse('$baseUrl/update'),
         headers: {'Content-Type': 'application/json'},
         body: json.encode({
           'did': did,
           if (newKey != null) 'new_key': newKey,
           if (newService != null) 'new_service': newService,
         }),
       );
       if (response.statusCode != 200) {
         throw Exception('Failed to update DID');
       }
     }
   }
   ```

4. Using the API in your Flutter app:

   ```dart
   final apiService = ApiService();

   // Register a new user
   try {
     final userData = await apiService.registerUser();
     print('New user registered: ${userData['address']}');
   } catch (e) {
     print('Error registering user: $e');
   }

   // Authenticate a user
   try {
     final isAuthenticated = await apiService.authenticateUser('did:algo:123', 'user_address');
     print('User authenticated: $isAuthenticated');
   } catch (e) {
     print('Error authenticating user: $e');
   }

   // Display user data
   try {
     final userData = await apiService.displayUserData('did:algo:123');
     print('User data: $userData');
   } catch (e) {
     print('Error fetching user data: $e');
   }

   // Update DID
   try {
     await apiService.updateDid('did:algo:123', newKey: 'new_key_value');
     print('DID updated successfully');
   } catch (e) {
     print('Error updating DID: $e');
   }
   ```

=======
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
>>>>>>> buildonchainyue

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

