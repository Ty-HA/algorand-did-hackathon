import logging
from algosdk import account, mnemonic
from algosdk.v2client import algod, indexer
from algosdk import transaction
import base64
import hashlib
import time
import json
from datetime import datetime
import os
from typing import List, Dict, Optional, Union, Any, Tuple
from base58 import b58encode, b58decode
from config import (
    ALGOD_ADDRESS, 
    ALGOD_TOKEN, 
    INDEXER_ADDRESS, 
    INDEXER_TOKEN,
    APP_ID,
    DID_PREFIX
)
import asyncio
import uuid
from algosdk.atomic_transaction_composer import AtomicTransactionComposer
from algosdk.abi import Contract, Method

# Configuration du logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_algod_client() -> algod.AlgodClient:
    """Retourne un client Algorand pour le TestNet."""
    return algod.AlgodClient(ALGOD_TOKEN, ALGOD_ADDRESS)

def get_indexer_client() -> indexer.IndexerClient:
    """Retourne un client Indexer pour le TestNet."""
    return indexer.IndexerClient(INDEXER_TOKEN, INDEXER_ADDRESS)

async def create_testnet_account() -> Dict[str, str]:
    """Create a new Algorand account on TestNet"""
    private_key, address = account.generate_account()
    passphrase = mnemonic.from_private_key(private_key)
    
    return {
        "address": address,
        "private_key": private_key,
        "passphrase": passphrase
    }

def get_deployer_account() -> Dict[str, str]:
    """Get the deployer account info from logs/deployments/contract_deployment.json"""
    try:
        # Get absolute path to the backend directory
        backend_dir = os.path.dirname(os.path.abspath(__file__))
        deployment_file = os.path.join(backend_dir, "logs", "deployments", "contract_deployment.json")
        
        logger.info(f"[get_deployer_account] Looking for deployment file at: {deployment_file}")
        
        if not os.path.exists(deployment_file):
            logger.error(f"[get_deployer_account] File not found at: {deployment_file}")
            # Try alternative path
            deployment_file = os.path.join("logs", "deployments", "contract_deployment.json")
            logger.info(f"[get_deployer_account] Trying alternative path: {deployment_file}")
            
            if not os.path.exists(deployment_file):
                raise Exception(f"Deployment info not found at {deployment_file}")
        
        with open(deployment_file, "r") as f:
            deployment_info = json.load(f)
            logger.info(f"[get_deployer_account] Loaded info: {json.dumps(deployment_info, indent=2)}")
            logger.info(f"[get_deployer_account] Using deployer address: {deployment_info['address']}")
            
            # Return deployer info without any address check
            return {
                "address": deployment_info["address"],
                "private_key": deployment_info["private_key"]
            }
    except Exception as e:
        logger.error(f"[get_deployer_account] Failed: {e}")
        raise

def generate_user_info_hash(user_info: Dict[str, Any] = None) -> str:
    """Generate a SHA-256 hash from user information"""
    try:
        if user_info:
            # Sort keys to ensure consistent hashing
            info_string = json.dumps(user_info, sort_keys=True)
        else:
            info_string = str(uuid.uuid4())  # Generate random hash if no user info provided
        
        # Create SHA-256 hash
        hash_object = hashlib.sha256(info_string.encode())
        return hash_object.hexdigest()
    except Exception as e:
        logger.error(f"Failed to generate user info hash: {e}")
        raise

def store_did_document(client: algod.AlgodClient, app_id: int, did_document: Dict) -> Tuple[int, int]:
    """Store DID document in Data Boxes"""
    try:
        # Convert document to JSON string
        doc_string = json.dumps(did_document)
        # Split into 4KB chunks
        chunk_size = 4096
        chunks = [doc_string[i:i + chunk_size] for i in range(0, len(doc_string), chunk_size)]
        
        # Store each chunk in a Data Box
        start_box_key = int(time.time())  # Use timestamp as starting key
        end_box_key = start_box_key + len(chunks) - 1
        
        for i, chunk in enumerate(chunks):
            box_key = start_box_key + i
            # Store chunk in box
            store_in_box(client, app_id, box_key, chunk.encode())
            
        return start_box_key, end_box_key
    except Exception as e:
        logger.error(f"Failed to store DID document: {e}")
        raise

def update_metadata_box(client: algod.AlgodClient, app_id: int, **kwargs):
    """Update Metadata Box with DID document info"""
    try:
        metadata = {
            "start_box_key": kwargs.get("start_box_key"),
            "end_box_key": kwargs.get("end_box_key"),
            "status": kwargs.get("status", 1),
            "size": kwargs.get("size", 0),
            "cred_start_box_key": kwargs.get("cred_start_box_key"),
            "cred_end_box_key": kwargs.get("cred_end_box_key"),
            "cred_status": kwargs.get("cred_status", 0)
        }
        
        # Store metadata in box
        store_in_box(client, app_id, "metadata", json.dumps(metadata).encode())
    except Exception as e:
        logger.error(f"Failed to update metadata box: {e}")
        raise

def verify_deployer_funds(client: algod.AlgodClient, deployer: Dict[str, str]) -> bool:
    """Verify deployer account has sufficient funds"""
    try:
        account_info = client.account_info(deployer["address"])
        balance = account_info.get("amount", 0)
        logger.info(f"Deployer balance: {balance} microAlgos")
        
        if balance < 1000000:  # 1 Algo minimum
            logger.error(f"Deployer account {deployer['address']} has insufficient funds")
            return False
        return True
    except Exception as e:
        logger.error(f"Failed to verify deployer funds: {e}")
        return False

async def register_did(account_info: Dict[str, str]) -> Dict[str, Any]:
    """Register a DID for an account on TestNet, with fees paid by deployer"""
    try:
        client = get_algod_client()
        
        # Get deployer account
        deployer = get_deployer_account()
        logger.info(f"Using deployer for DID registration: {deployer['address']}")
        logger.info(f"Full deployer info: {json.dumps(deployer, indent=2)}")
        
        # Verify deployer has funds
        if not verify_deployer_funds(client, deployer):
            raise Exception("Deployer account has insufficient funds")
        
        # Get deployer account info
        deployer_info = client.account_info(deployer["address"])
        logger.info(f"Deployer balance: {deployer_info.get('amount', 0)} microAlgos")
        
        params = client.suggested_params()
        
        # Generate user info hash if user_info is provided
        user_info_hash = None
        if "user_info" in account_info:
            user_info_hash = generate_user_info_hash(account_info["user_info"])
        
        # Create DID identifier
        did = f"{DID_PREFIX}{account_info['address']}"
        
        # Create DID Document
        did_document = {
            "@context": ["https://www.w3.org/ns/did/v1"],
            "id": did,
            "verificationMethod": [{
                "id": f"{did}#key-1",
                "type": "Ed25519VerificationKey2018",
                "controller": did,
                "publicKeyBase58": account_info["address"]
            }],
            "authentication": [f"{did}#key-1"],
            "userInfoHash": user_info_hash
        }
        
        # Store DID Document in Data Boxes
        start_box_key, end_box_key = store_did_document(client, APP_ID, did_document)
        
        # Update Metadata Box
        update_metadata_box(
            client, 
            APP_ID,
            start_box_key=start_box_key,
            end_box_key=end_box_key,
            status=1,
            size=len(json.dumps(did_document))
        )
        
        # Create transaction
        txn = transaction.ApplicationCallTxn(
            sender=deployer["address"],
            sp=params,
            index=APP_ID,
            on_complete=transaction.OnComplete.NoOpOC,
            app_args=[b"register"],
            accounts=[account_info["address"]],
            boxes=[(APP_ID, "metadata")],  # Add box reference
            note=json.dumps({"type": "DID_REGISTRATION", "did": did}).encode()
        )

        # Sign and send
        signed_txn = txn.sign(deployer["private_key"])
        tx_id = client.send_transaction(signed_txn)
        
        # Wait for confirmation
        confirmed_txn = await wait_for_confirmation(client, tx_id, timeout=15)
        
        return {
            "status": "success",
            "did": did,
            "didDocument": did_document,
            "transaction_id": tx_id,
            "confirmed_round": confirmed_txn["confirmed-round"],
            "paid_by": deployer["address"],
            "storage": {
                "start_box_key": start_box_key,
                "end_box_key": end_box_key
            }
        }
        
    except Exception as e:
        logger.error(f"Failed to register DID: {str(e)}")
        raise Exception(f"Failed to register DID: {str(e)}")

async def resolve_did(did: str) -> Dict[str, Any]:
    """Resolve a DID and its credentials"""
    try:
        client = get_algod_client()
        
        # Get metadata
        metadata_box = client.application_box_by_name(APP_ID, b"metadata")
        metadata = json.loads(metadata_box.decode())
        
        # Reconstruct DID document
        did_document = reconstruct_did_document(
            client,
            APP_ID,
            metadata["start_box_key"],
            metadata["end_box_key"]
        )
        
        # Get credentials if available
        credentials = []
        if metadata.get("cred_start_box_key") and metadata.get("cred_end_box_key"):
            credentials = reconstruct_did_document(
                client,
                APP_ID,
                metadata["cred_start_box_key"],
                metadata["cred_end_box_key"]
            )
        
        return {
            "did": did,
            "didDocument": did_document,
            "credentials": credentials,
            "metadata": {
                "chain": "algorand-testnet",
                "recovered": True,
                "storage": metadata
            }
        }
        
    except Exception as e:
        raise Exception(f"Failed to resolve DID: {str(e)}")

async def wait_for_confirmation(client: algod.AlgodClient, txid: str, timeout: int = 10) -> Dict[str, Any]:
    """Wait until the transaction is confirmed or rejected, or until timeout."""
    try:
        start_round = client.status()["last-round"] + 1
        current_round = start_round

        while current_round < start_round + timeout:
            try:
                pending_txn = client.pending_transaction_info(txid)
                
                # Check if transaction was confirmed
                if pending_txn.get("confirmed-round", 0) > 0:
                    logger.info(f"Transaction {txid} confirmed in round {pending_txn['confirmed-round']}")
                    return pending_txn
                
                # Check for transaction errors
                elif pending_txn.get("pool-error"):
                    raise Exception(f"Transaction pool error: {pending_txn['pool-error']}")
                
                # Transaction still pending, wait and check next round
                logger.debug(f"Waiting for confirmation... (Round {current_round})")
                await asyncio.sleep(2)  # Increased wait time between checks
                current_round += 1
                
            except Exception as e:
                logger.error(f"Error checking transaction status: {str(e)}")
                raise

        # If we get here, we've timed out
        raise Exception(f'Transaction {txid} not confirmed after {timeout} rounds')
        
    except Exception as e:
        logger.error(f"Error in wait_for_confirmation: {str(e)}")
        raise

def store_in_box(client: algod.AlgodClient, app_id: int, box_key: Union[str, int], value: bytes):
    """Store data in an application box"""
    try:
        # Get deployer account
        deployer = get_deployer_account()
        logger.info(f"[store_in_box] Using deployer address: {deployer['address']}")
        
        # Convert string box_key to bytes if needed
        if isinstance(box_key, str):
            box_name = box_key.encode()
        else:
            box_name = box_key.to_bytes(8, 'big')

        # Create box storage transaction
        params = client.suggested_params()
        
        # Calculate minimum balance requirement
        min_balance = 2500 + len(value) + 400
        params.fee = max(params.min_fee, min_balance)
        
        # Log transaction details before sending
        logger.info(f"[store_in_box] Creating transaction with sender: {deployer['address']}")

        try:
            # Create the store transaction
            store_txn = transaction.ApplicationCallTxn(
                sender=deployer["address"],
                sp=params,
                index=app_id,
                on_complete=transaction.OnComplete.NoOpOC,
                app_args=[b"store", box_name, value],
                boxes=[(app_id, box_name)],
                accounts=[deployer["address"]]
            )
            
            # Create signing key from private key
            try:
                # Convert private key to mnemonic first
                m = mnemonic.from_private_key(deployer["private_key"])
                # Get signing key from mnemonic
                signing_key = mnemonic.to_private_key(m)
                logger.debug(f"[store_in_box] Successfully created signing key")
            except Exception as e:
                logger.error(f"[store_in_box] Failed to create signing key: {e}")
                raise
            
            # Sign transaction
            signed_txn = store_txn.sign(signing_key)
            logger.info(f"[store_in_box] Transaction signed successfully")
            
            # Send transaction
            tx_id = client.send_transaction(signed_txn)
            logger.info(f"[store_in_box] Transaction sent with ID: {tx_id}")
            
            # Wait for confirmation
            result = transaction.wait_for_confirmation(client, tx_id, 4)
            logger.info(f"[store_in_box] Transaction confirmed: {tx_id}")
            
            return result

        except Exception as e:
            logger.error(f"[store_in_box] Failed to process transaction: {e}")
            raise

    except Exception as e:
        logger.error(f"[store_in_box] Failed with error: {e}")
        logger.error(f"[store_in_box] Attempted to use deployer: {deployer['address']}")
        raise

async def issue_credential(issuer_address: str, holder_address: str, credential_data: Dict[str, Any]) -> Dict[str, Any]:
    """Issue and store a verifiable credential"""
    try:
        client = get_algod_client()
        
        # Create credential
        credential = {
            "id": f"credential:{uuid.uuid4()}",
            "type": ["VerifiableCredential"],
            "issuer": f"{DID_PREFIX}{issuer_address}",
            "credentialSubject": {
                "id": f"{DID_PREFIX}{holder_address}",
                **credential_data
            },
            "issuanceDate": datetime.utcnow().isoformat() + "Z",
            "credentialStatus": "active"
        }

        # Store credential in Data Boxes
        cred_start_box_key = int(time.time())
        doc_string = json.dumps(credential)
        chunk_size = 4096
        chunks = [doc_string[i:i + chunk_size] for i in range(0, len(doc_string), chunk_size)]
        
        for i, chunk in enumerate(chunks):
            box_key = cred_start_box_key + i
            store_in_box(client, APP_ID, box_key, chunk.encode())
        
        cred_end_box_key = cred_start_box_key + len(chunks) - 1
        
        # Update Metadata Box with credential info
        update_metadata_box(
            client,
            APP_ID,
            cred_start_box_key=cred_start_box_key,
            cred_end_box_key=cred_end_box_key,
            cred_status=1,
            cred_size=len(doc_string)
        )
        
        return {
            "status": "success",
            "credential": credential,
            "storage": {
                "start_box_key": cred_start_box_key,
                "end_box_key": cred_end_box_key
            }
        }
        
    except Exception as e:
        logger.error(f"Failed to issue credential: {e}")
        raise

def reconstruct_did_document(client: algod.AlgodClient, app_id: int, start_key: int, end_key: int) -> Dict:
    """Reconstruct DID document from Data Boxes"""
    try:
        chunks = []
        for box_key in range(start_key, end_key + 1):
            box_name = box_key.to_bytes(8, 'big')
            box_content = client.application_box_by_name(app_id, box_name)
            chunks.append(box_content.decode())
        
        return json.loads(''.join(chunks))
    except Exception as e:
        logger.error(f"Failed to reconstruct DID document: {e}")
        raise

# Add this at the end of the file
register_did_with_document = register_did  # Alias for compatibility
