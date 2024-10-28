# DID API with Algorand On-chain Management

## 1. Backend Architecture

The backend is built using FastAPI and integrates directly with Algorand TestNet for DID management. 
Main components:

1. `main.py`: API endpoints and routing logic
2. `registration.py`: User registration and DID creation
3. `did_management.py`: DID Document management and on-chain verification
4. `authentication.py`: User authentication
5. `data_display.py`: Data retrieval and formatting
6. `did_update.py`: DID document updates

## 2. Backend Setup

### 2.1 Environment Setup

1. Python 3.7+ installation required
2. Clone and setup:
   ```bash
   cd my-app/backend
   python -m venv venv
   
   # Windows
   venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

### 2.2 Dependencies
Create a `requirements.txt` with:
```
fastapi>=0.68.0
uvicorn>=0.15.0
py-algorand-sdk>=2.5.0
python-multipart>=0.0.5
pytest>=6.2.5
pytest-asyncio>=0.16.0
base58>=2.1.1
typing-extensions>=4.0.0
```

### 2.3 Run the Server
```bash
uvicorn main:app --reload
```

## 3. DID Management Features

### 3.1 On-chain DID Registration

#### Register new DID
```python
POST /register-did
{
    "address": "algorand_address",
    "mnemonic": "25_word_mnemonic"  # Optional
}
```
Response:
```json
{
    "did": "did:algo:abc123...",
    "address": "algorand_address",
    "transaction_id": "TX_ID",
    "explorer_links": {
        "transaction": "https://testnet.explorer.perawallet.app/tx/TX_ID",
        "address": "https://testnet.explorer.perawallet.app/address/ADDRESS"
    }
}
```

#### Verify DID on-chain
```python
GET /verify-did/{did}
```
Response:
```json
{
    "status": "confirmed",
    "did": "did:algo:abc123...",
    "timestamp": 1635444444,
    "block": 12345678
}
```

### 3.2 DID Document Management

#### Create DID Document
```python
POST /create-did-document
{
    "did": "did:algo:abc123...",
    "controller": "optional_controller_did"
}
```
Response:
```json
{
    "@context": ["https://www.w3.org/ns/did/v1"],
    "id": "did:algo:abc123...",
    "controller": "did:algo:abc123...",
    "verificationMethod": [{
        "id": "did:algo:abc123...#key-1",
        "type": "Ed25519VerificationKey2018",
        "controller": "did:algo:abc123...",
        "publicKeyBase58": "algorand_address"
    }],
    "authentication": ["did:algo:abc123...#key-1"]
}
```

#### Update DID Document
```python
PUT /update-did-document
{
    "did": "did:algo:abc123...",
    "document": {
        // Updated DID Document fields
    }
}
```

### 3.3 DID Resolution
```python
GET /resolve-did/{did}
```
Response:
```json
{
    "did": "did:algo:abc123...",
    "didDocument": {
        // Full DID Document
    },
    "metadata": {
        "recovered": true,
        "network": "testnet"
    }
}
```

## 4. Testing

### 4.1 Unit Tests
```bash
pytest test_main.py
```

### 4.2 Test DID Registration
```bash
python test_registration.py
```

### 4.3 Test On-chain Verification
```python
python test_did_verification.py
```

## 5. Pera Explorer Integration

All transactions can be verified on Pera Explorer:
- Transactions: `https://testnet.explorer.perawallet.app/tx/{tx_id}`
- Addresses: `https://testnet.explorer.perawallet.app/address/{address}`

## 6. Security Considerations

1. Never share or commit mnemonics
2. Store DIDs securely
3. Verify transactions before confirmation
4. Implement rate limiting
5. Add error handling for failed transactions

## 7. Integration Examples

### 7.1 Python Example
```python
from did_management import register_did_for_account

result = register_did_for_account(
    address="YOUR_ADDRESS",
    m_phrase="YOUR_MNEMONIC"
)
print(f"DID Created: {result['did']}")
print(f"Verify at: {result['explorer_links']['transaction']}")
```

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


## 8. Next Steps

1. Implement DID Resolution caching
2. Add support for multiple verification methods
3. Implement DID service endpoints
4. Add revocation support
5. Create monitoring dashboard
6. Deploy smart contracts for advanced features

## 9. Resources

- [Algorand Documentation](https://developer.algorand.org/)
- [W3C DID Specification](https://www.w3.org/TR/did-core/)
- [Pera Explorer](https://explorer.perawallet.app/)
- [Project Repository](https://github.com/yourusername/project)