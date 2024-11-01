DID Registration System on Algorand with User Information Hash
Product Requirements Document (PRD)
1. Project Overview
This project builds a decentralized identity (DID) registration and management system on the Algorand blockchain. Based on the did_registration_for_existing_account.py script, this system registers each DID with a unique hash representing user information, enhancing privacy and security by linking the DID to a hashed representation of the user's data.

2. Goals and Objectives
Primary Goals:

Implement DID registration and management on the Algorand blockchain.
Include a hash of the user information in the DID document during registration to securely represent the user’s identity.
Secondary Goals:

Allow easy retrieval and verification of DID documents stored on the Algorand blockchain.
Provide sample transactions with links to explore the DID document on Algorand’s Pera TestNet Explorer.
3. High-Level Workflow
Generate User Information Hash: Create a unique SHA-256 hash from simulated user information before DID registration.
Create DID Document: Include the generated hash in the DID document, alongside other identification details.
Register DID Document: Store the DID document as a JSON note in a transaction on the Algorand blockchain.
Retrieve and Verify DID Document: Provide endpoints for retrieving and verifying DID documents.
4. Feature Details
4.1 Generate User Information Hash
Description: Generate a SHA-256 hash representing the user information to uniquely represent the user's identity without exposing sensitive data.

Implementation Details:

Function generate_user_info_hash() generates a random SHA-256 hash for each user, simulating user information.
python
Copy code
import hashlib
import uuid

def generate_user_info_hash():
    random_string = str(uuid.uuid4())
    return hashlib.sha256(random_string.encode()).hexdigest()
4.2 Modify create_did_from_address to Include User Information Hash
Description: Update the create_did_from_address function to accept a user information hash as an argument and embed it into the DID document.

New Parameters:

user_info_hash: The generated hash representing user information.
Modified DID Document Structure:

json
Copy code
{
    "@context": ["https://www.w3.org/ns/did/v1"],
    "id": "did:algo:<base58_encoded_address>",
    "verificationMethod": [
        {
            "id": "did:algo:<base58_encoded_address>#key-1",
            "type": "Ed25519VerificationKey2018",
            "controller": "did:algo:<base58_encoded_address>",
            "publicKeyBase58": "<Algorand_address>"
        }
    ],
    "authentication": ["did:algo:<base58_encoded_address>#key-1"],
    "userInfoHash": "<generated_user_info_hash>"
}
Code Update:

python
Copy code
def create_did_from_address(address: str, user_info_hash: str) -> str:
    try:
        address_bytes = address.encode('utf-8')
        address_hash = hashlib.sha256(address_bytes).digest()
        truncated_hash = address_hash[:16]
        did_suffix = b58encode(truncated_hash).decode('utf-8')
        did = f"did:algo:{did_suffix}"
        logger.info(f"Created DID {did} for address {address}")

        # DID Document
        did_document = {
            "@context": ["https://www.w3.org/ns/did/v1"],
            "id": did,
            "verificationMethod": [
                {
                    "id": f"{did}#key-1",
                    "type": "Ed25519VerificationKey2018",
                    "controller": did,
                    "publicKeyBase58": address
                }
            ],
            "authentication": [f"{did}#key-1"],
            "userInfoHash": user_info_hash
        }
        
        return did, did_document
    except Exception as e:
        logger.error(f"Error creating DID: {e}")
        raise
4.3 Register DID for an Existing Account
Description: Update the register_did_for_account function to incorporate the user information hash in the DID document during registration.

Process:

Generate the user information hash using generate_user_info_hash.
Call create_did_from_address with the address and the generated hash to create the DID document.
Encode the DID document as a JSON note and attach it to the Algorand blockchain transaction.
Updated register_did_for_account Code:

python
Copy code
def register_did_for_account(address: str, private_key: str = None, m_phrase: str = None):
    try:
        client = get_algod_client()

        # Obtain private key from mnemonic if not directly provided
        if private_key is None and m_phrase is not None:
            private_key = mnemonic.to_private_key(m_phrase)
        elif private_key is None:
            raise ValueError("Either private_key or m_phrase must be provided")

        # Check account balance
        account_info = client.account_info(address)
        balance = account_info.get('amount', 0)
        logger.info(f"Account balance: {balance} microAlgos")

        # Generate unique user info hash
        user_info_hash = generate_user_info_hash()

        # Create DID with user info hash
        did, did_document = create_did_from_address(address, user_info_hash)

        # Create note with DID document
        note = json.dumps(did_document).encode()

        # Prepare transaction with DID document in the note
        params = client.suggested_params()
        unsigned_txn = transaction.PaymentTxn(
            sender=address,
            sp=params,
            receiver=address,  # Self-transaction to embed data
            amt=0,
            note=note
        )

        signed_txn = unsigned_txn.sign(private_key)
        tx_id = client.send_transaction(signed_txn)
        logger.info(f"Transaction sent with ID: {tx_id}")

        # Wait for confirmation
        confirmed_txn = transaction.wait_for_confirmation(client, tx_id, 4)
        logger.info(f"Transaction confirmed in round: {confirmed_txn['confirmed-round']}")

        result = {
            "did": did,
            "address": address,
            "transaction_id": tx_id,
            "confirmation_round": confirmed_txn['confirmed-round'],
            "did_document": did_document,
            "explorer_links": {
                "transaction": f"{PERA_EXPLORER_TESTNET}/tx/{tx_id}",
                "address": f"{PERA_EXPLORER_TESTNET}/address/{address}"
            }
        }

        return result

    except Exception as e:
        logger.error(f"Failed to register DID: {e}")
        raise
4.4 Retrieve and Verify DID Document
Description: Implement a retrieval function to fetch the DID document from the Algorand blockchain using the transaction ID. This can be used to verify the user information hash and other data within the DID document.

Sample Code for Retrieval:

python
Copy code
def retrieve_did_document(client, tx_id):
    tx_info = client.pending_transaction_info(tx_id)
    note = tx_info["txn"]["txn"]["note"]
    did_document = json.loads(base64.b64decode(note).decode())
    return did_document
5. Endpoints
Register DID: /register

Method: POST
Request Body:
json
Copy code
{
  "address": "<Algorand_address>",
  "private_key": "<Private_key_for_signing>"
}
Response:
json
Copy code
{
  "status": "success",
  "did": "<DID_identifier>",
  "transaction_id": "<Algorand_tx_id>",
  "confirmed_round": "<confirmed_round_number>",
  "did_document": "<DID_document_JSON>"
}
Resolve DID: /resolve

Method: GET
Request Parameters: did=<DID_identifier>
Response:
json
Copy code
{
  "status": "success",
  "did_document": "<DID_document_JSON>",
  "transaction_id": "<Algorand_tx_id>"
}
6. Testing
Unit Tests:

Validate DID creation and the inclusion of the user information hash.
Verify Algorand transaction creation and confirmation.
Test DID document retrieval and verification.
Integration Tests:

Conduct end-to-end tests for registration, storage, and retrieval on Algorand TestNet.
7. Technical Considerations
Transaction Size: Ensure the note field can accommodate the DID document. Consider splitting if the document grows.
Privacy: Hashes should represent user information without exposing actual data.
Scalability: Design the DID document structure to allow future fields if needed.
8. Conclusion
This PRD defines a DID registration system on Algorand that includes user information hashes in the DID document. It builds on did_registration_for_existing_account.py with enhanced