# DID API 

## 1. Backend Logic

The backend is built using FastAPI Python web framework. It uses the Algorand SDK for blockchain interactions. 
The main components are:

1. `main.py`: Contains the API endpoints and routing logic.
2. `registration.py`: Handles user registration and DID creation.
3. `authentication.py`: Manages user authentication.
4. `data_display.py`: Retrieves and formats user data.
5. `did_update.py`: Handles updates to the DID document.

## 2. Backend Setup

To set up and run the backend locally, follow these steps:

1. Ensure you have Python 3.7+ installed on your system.

2. Clone the repository and navigate to the backend directory:
   ```
   cd my-app/backend
   ```

3. Create a virtual environment:
   ```
   python3 -m venv venv
   ```

4. Activate the virtual environment:
   - On macOS and Linux:
     ```
     source venv/bin/activate
     ```
   - On Windows:
     ```
     venv\Scripts\activate
     ```

5. Install the required dependencies:
   ```
   pip install -r requirements.txt
   ```

6. Run the FastAPI server:
   ```
   python run.py
   ```

The server should now be running at `http://localhost:8000`.

You can verify the server is running by opening a web browser and navigating to `http://localhost:8000/docs`. This will show you the FastAPI automatic interactive API documentation.

## 3. Backend Testing

After setting up, you can run the tests to ensure everything is working correctly:

1. Ensure you're in the backend directory and your virtual environment is activated.

2. Run the tests using pytest:
   ```
   pytest test_main.py
   ```

If all tests pass, your backend is set up correctly and ready for integration with the Flutter frontend.

## 4. API Endpoints

### 4.1 Register a new user

- **URL**: `/register`
- **Method**: POST
- **Response**: 
  ```json
  {
    "address": "user_algorand_address",
    "passphrase": "user_passphrase"
  }
  ```

### 4.2 Authenticate a user

- **URL**: `/authenticate`
- **Method**: POST
- **Request Body**:
  ```json
  {
    "did": "user_did",
    "address": "user_algorand_address"
  }
  ```
- **Response**: 
  - Success (200 OK): `{"status": "Authenticated"}`
  - Failure (401 Unauthorized): `{"detail": "Authentication failed"}`

### 4.3 Display user data

- **URL**: `/display/{did}`
- **Method**: GET
- **Response**: 
  ```json
  {
    "id": "user_did",
    "verificationMethod": [...],
    "authentication": [...]
  }
  ```

### 4.4 Update DID

- **URL**: `/update`
- **Method**: POST
- **Request Body**:
  ```json
  {
    "did": "user_did",
    "new_key": "new_key_value",
    "new_service": "new_service_value"
  }
  ```
- **Response**:
  - Success (200 OK): `{"status": "DID updated successfully"}`
  - Failure (400 Bad Request): `{"detail": "Error message"}`

## 5. Integrating with Flutter

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

### Error Handling

The API uses standard HTTP status codes. In your Flutter app, you should handle these appropriately:

- 200: Successful operation
- 400: Bad request (e.g., invalid input)
- 401: Unauthorized (for authentication failures)
- 404: Not found (e.g., DID not found)
- 500: Internal server error

Always wrap your API calls in try-catch blocks to handle potential exceptions.

### Next Steps



