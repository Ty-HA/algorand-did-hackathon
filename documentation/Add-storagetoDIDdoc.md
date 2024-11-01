Product Requirements Document (PRD): On-chain DID Document and Credential Storage Using Metadata and Data Boxes
Project Overview
Objective: Update did_management.py and did_registration_for_existing_account.py to:

Store DID documents and associated user info hashes on-chain using Algorand’s Metadata and Data Boxes.
Add functionality for issuing and storing verifiable credentials, linked to the DID, using Data Boxes.
Scope:

Implement Metadata Box for DID document and credential metadata.
Store the DID document, user info hash, and credentials in Data Boxes.
Update DID resolution and credential retrieval functions to access data from Metadata and Data Boxes.
Introduce a credential issuance function to allow issuers to store credentials for DIDs.
Functional Requirements
1. Store DID Document Metadata in Metadata Box
The Metadata Box will store metadata about the DID document, including:

Data Box Range (start_box_key and end_box_key): Range of Data Boxes where the DID document is stored.
Status: Indicating if the DID document is ready (1), being uploaded (0), or being deleted (2).
Document Size: Total size in bytes of the DID document.
Data Structure
metadata[0]: uint64 - Starting Data Box key for DID document.
metadata[1]: uint64 - Ending Data Box key for DID document.
metadata[2]: uint8 - Status.
metadata[3]: uint64 - Document size in bytes.
2. Store DID Document in Data Boxes
Each Data Box can hold up to 4KB of data. For DID documents exceeding this size, they will be split across multiple Data Boxes.

Implementation Steps:
Encode the DID document as JSON and split it into 4KB chunks.
Store each chunk in sequential Data Boxes using the ApplicationCallTxn.
Link the Data Boxes sequentially in the Metadata Box.
Example DID Document Structure
json
Copy code
{
    "@context": ["https://www.w3.org/ns/did/v1"],
    "id": "did:algo:{address}",
    "verificationMethod": [
        {
            "id": "did:algo:{address}#key-1",
            "type": "Ed25519VerificationKey2018",
            "controller": "did:algo:{address}",
            "publicKeyBase58": "{public_key_base58}"
        }
    ],
    "authentication": ["did:algo:{address}#key-1"],
    "userInfoHash": "{user_info_hash}"
}
3. Credential Storage and Issuance in Data Boxes
Introduce functionality to issue and store verifiable credentials associated with a DID. Each credential will be stored in separate Data Boxes and referenced by a unique key within the Metadata Box.

Credential Metadata Structure
Add fields to the Metadata Box for managing credentials:

Credential Range (cred_start_box_key and cred_end_box_key): Range of Data Boxes used for credentials.
Credential Status: Status of the credential data (e.g., ready or deleted).
Example Credential Structure
Each credential will be stored as a JSON object:

json
Copy code
{
    "id": "credential:{uuid}",
    "type": ["VerifiableCredential"],
    "issuer": "did:algo:{issuer_address}",
    "credentialSubject": {
        "id": "did:algo:{holder_address}",
        "name": "Sample User",
        "degree": "Bachelor of Science in Computer Science"
    },
    "issuanceDate": "{date}",
    "credentialStatus": "active"
}
4. DID Registration and Credential Issuance Methods in did_management.py
Update register_did Function:

Modify to store the DID document in Data Boxes and update Metadata Box accordingly.
New issue_credential Function:

Allows an authorized issuer (e.g., a school) to store a verifiable credential associated with a DID in Data Boxes.
Update Metadata Box to reflect the credential’s Data Box range and status.
Technical Specifications
1. TEAL Smart Contract Changes
Metadata Box: Define additional fields in Metadata Box to store credential Data Box ranges and statuses.
Data Boxes: Modify contract logic to handle multiple credential issuance and storage operations across Data Boxes.
2. Function Implementations
store_did_document
Splits the DID document into 4KB chunks and stores each chunk in Data Boxes.

update_metadata_box
Updates the Metadata Box to include information on the Data Box ranges for DID documents and credentials.

store_credential
Takes a credential as input, splits it into 4KB chunks, and stores it in Data Boxes.
Updates Metadata Box with Data Box range and status for the credential.
reconstruct_did_document and reconstruct_credential
Retrieve and reconstruct the DID document or credential by reading from the appropriate Data Boxes as specified in the Metadata Box.
Code Updates
did_management.py
register_did Function
Update register_did to store DID document in Data Boxes.

python
Copy code
async def register_did(account_info: Dict[str, str]) -> Dict[str, Any]:
    user_info_hash = generate_user_info_hash(account_info.get("user_info"))
    did_document = {
        "@context": ["https://www.w3.org/ns/did/v1"],
        "id": f"{DID_PREFIX}{account_info['address']}",
        "verificationMethod": [{
            "id": f"{DID_PREFIX}{account_info['address']}#key-1",
            "type": "Ed25519VerificationKey2018",
            "controller": f"{DID_PREFIX}{account_info['address']}",
            "publicKeyBase58": account_info["address"]
        }],
        "authentication": [f"{DID_PREFIX}{account_info['address']}#key-1"],
        "userInfoHash": user_info_hash
    }

    # Store DID Document in Data Boxes
    start_box_key, end_box_key = store_did_document(client, APP_ID, did_document)
    
    # Update Metadata Box
    update_metadata_box(client, APP_ID, start_box_key=start_box_key, end_box_key=end_box_key, status=1, size=len(json.dumps(did_document)))
New issue_credential Function
This function allows an issuer to issue and store credentials for a holder DID.

python
Copy code
async def issue_credential(issuer_address: str, holder_address: str, credential_data: Dict[str, Any]) -> Dict[str, Any]:
    credential = {
        "id": f"credential:{uuid.uuid4()}",
        "type": ["VerifiableCredential"],
        "issuer": f"{DID_PREFIX}{issuer_address}",
        "credentialSubject": credential_data,
        "issuanceDate": datetime.utcnow().isoformat() + "Z",
        "credentialStatus": "active"
    }

    # Store Credential in Data Boxes
    cred_start_box_key, cred_end_box_key = store_credential(client, APP_ID, credential)
    
    # Update Metadata Box with Credential Information
    update_metadata_box(client, APP_ID, cred_start_box_key=cred_start_box_key, cred_end_box_key=cred_end_box_key, cred_status=1, cred_size=len(json.dumps(credential)))
    
    return {
        "status": "success",
        "credential": credential
    }
did_registration_for_existing_account.py
Update register_did_for_account to call register_did with Metadata and Data Box updates.

python
Copy code
def register_did_for_account(address: str, private_key: str = None, m_phrase: str = None):
    client = get_algod_client()
    
    # Set private key or mnemonic phrase
    if private_key is None and m_phrase:
        private_key = mnemonic.to_private_key(m_phrase)
    
    # Call register_did to store DID document on-chain
    result = asyncio.run(register_did({"address": address, "user_info": {"name": "Sample User"}}))
    
    logger.info(f"DID registered with metadata: {result}")
Credential Retrieval in resolve_did
Add logic to retrieve credentials associated with the DID.

python
Copy code
async def resolve_did(did: str) -> Dict[str, Any]:
    metadata = get_metadata(client, APP_ID)
    
    # Retrieve DID document
    did_document = reconstruct_did_document(client, APP_ID, metadata['start_box_key'], metadata['end_box_key'])
    
    # Retrieve credentials if available
    credentials = []
    if metadata.get('cred_start_box_key') and metadata.get('cred_end_box_key'):
        credentials = reconstruct_credential(client, APP_ID, metadata['cred_start_box_key'], metadata['cred_end_box_key'])

    return {
        "did": did,
        "didDocument": did_document,
        "credentials": credentials,
        "metadata": {
            "chain": "algorand-testnet",
            "recovered": True
        }
    }
Testing and Validation
Test Cases
DID Registration and Storage:
Confirm Metadata and Data Boxes are correctly populated with DID document information.
Credential Issuance and Storage:
Verify that credentials are stored across Data Boxes and that Metadata Box is updated with the credential range and status.
DID and Credential Resolution:
Confirm that resolve_did reconstructs both the DID document and





