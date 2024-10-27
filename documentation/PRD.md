# Product Requirements Document (PRD)

**Project Name**: Decentralized Identity Management on Algorand  
**Project Overview**: This project enables decentralized identity (DID) creation, authentication, and management on the Algorand blockchain. Users can create, manage, and authenticate their identities using a DID, leveraging a backend API for blockchain interactions and a Flutter-based frontend for user interactions.

---

## 1. Goals and Objectives

- **Primary Goals**:
  - Create a decentralized identity solution on Algorand that allows users to manage their digital identities securely.
  - Allow users to register and authenticate their DIDs using a blockchain-based approach.
  - Enable DID updates to add or modify identity information as needed.
  
- **Secondary Goals**:
  - Facilitate DID resolution through a DID resolver, making DID documents retrievable for verification.
  - Provide a seamless, user-friendly interface through a Flutter-based frontend application.

---

## 2. File Tree Overview

my_app/
├── backend/
│   ├── config.py
│   ├── main.py
│   ├── registration.py
│   ├── authentication.py
│   ├── data_display.py
│   ├── did_update.py
│   ├── utils.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── contracts/
│       ├── approval.teal
│       ├── clear.teal
│       └── contract_abi.json
│
├── frontend/
│
├── resolver/
│   ├── Dockerfile
│   ├── config.yaml
│   └── resolver.py
├── README.md
├── .gitignore
└── docker-compose.yml


---

## 3. File-by-File Details

### Backend

1. **`config.py`**
   - **Purpose**: Configuration file for Algorand API access and app-specific settings.
   - **Details**:
     - `ALGOD_TOKEN`: The API token for Algorand node access.
     - `ALGOD_ADDRESS`: Algorand node address.
     - `HEADERS`: Header setup for Algorand API requests.
     - `APP_ID`: App ID used for DID management.

2. **`main.py`**
   - **Purpose**: Entry point for the backend API server (FastAPI).
   - **Details**:
     - Sets up API endpoints for each core feature: user registration, authentication, data display, and DID updates.
     - Routes correspond to registration (`/register`), authentication (`/authenticate`), data retrieval (`/display`), and DID updates (`/update`).

3. **`registration.py`**
   - **Purpose**: Handles user registration and DID creation.
   - **Details**:
     - `create_account()`: Generates an Algorand wallet and stores its address and passphrase.
     - `register_user()`: Uses `algoid` CLI to create a DID, associating it with the user’s Algorand wallet.

4. **`authentication.py`**
   - **Purpose**: Manages user authentication.
   - **Details**:
     - `retrieve_did()`: Fetches DID document from the resolver.
     - `authenticate_user()`: Verifies the user’s Algorand address against the DID document’s controller address.

5. **`data_display.py`**
   - **Purpose**: Displays user data stored in the DID document.
   - **Details**:
     - `display_user_data()`: Uses `retrieve_did()` to fetch and parse the DID document for the user's data, printing the verification method and authentication methods.

6. **`did_update.py`**
   - **Purpose**: Handles updates to the DID document.
   - **Details**:
     - `update_did()`: Updates DID by adding a new cryptographic key or service, using the `algoid` CLI command to modify the DID document.

7. **`utils.py`**
   - **Purpose**: Utility functions used across backend files.
   - **Details**:
     - Helper functions for error handling, API response formatting, and logging.

8. **`requirements.txt`**
   - **Purpose**: Lists backend dependencies for easy installation.
   - **Details**:
     - Key dependencies: `algosdk`, `fastapi`, `requests`.

9. **`Dockerfile`**
   - **Purpose**: Dockerfile for containerizing the backend.
   - **Details**:
     - Configures the Python environment, installs dependencies, and sets the entry point to `main.py`.

10. **`contracts/`**
    - **Files**: 
      - `approval.teal` - Approval program TEAL script for DID management.
      - `clear.teal` - Clear program TEAL script for DID removal.
      - `contract_abi.json` - Application Binary Interface (ABI) for DID smart contracts.
    - **Purpose**: Smart contract files to interact with Algorand for managing DIDs.

### Resolver

1. **`Dockerfile`**
   - **Purpose**: Docker configuration to containerize the DID resolver service.
   - **Details**:
     - Installs necessary dependencies and sets up the `resolver.py` service.

2. **`config.yaml`**
   - **Purpose**: Configuration file for DID resolver.
   - **Details**:
     - Stores resolver URL, network settings, and timeout configurations.

3. **`resolver.py`**
   - **Purpose**: Implements the DID resolver service, listening for DID requests and returning the appropriate DID document.
   - **Details**:
     - Parses incoming requests for DID documents and retrieves relevant data based on DID syntax.

### Project Root

1. **`README.md`**
   - **Purpose**: Provides project documentation, including setup instructions, API routes, and feature descriptions.

2. **`.gitignore`**
   - **Purpose**: Specifies files and directories to ignore in version control.

3. **`docker-compose.yml`**
   - **Purpose**: Orchestrates multi-container setup for backend, frontend, and resolver.
   - **Details**:
     - Defines services, links them, and sets network configurations to facilitate interactions between containers.

---

## 4. Features and Functional Requirements

### User Registration
   - **Goal**: Allow users to register by creating a DID.
   - **Backend**: `register_user` function in `registration.py`.

### User Authentication
   - **Goal**: Authenticate users against their DID.
   - **Backend**: `authenticate_user` in `authentication.py`.

### Data Display
   - **Goal**: Display user DID document data.
   - **Backend**: `display_user_data` in `data_display.py`.

### DID Updates
   - **Goal**: Allow users to add or modify fields in their DID.
   - **Backend**: `update_did` in `did_update.py`.

---

## 5. Non-Functional Requirements

- **Performance**: Efficient interaction with Algorand using TEAL smart contracts.
- **Security**: Secure storage and management of cryptographic keys.
- **Scalability**: Modular design to scale backend services as the user base grows.
- **Usability**: Clear API responses and error handling for smooth frontend integration.