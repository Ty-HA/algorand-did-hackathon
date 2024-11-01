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
from typing import List, Dict, Optional, Union, Any
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
        deployment_file = os.path.join("logs", "deployments", "contract_deployment.json")
        if not os.path.exists(deployment_file):
            raise Exception(f"Deployment info not found at {deployment_file}")
            
        with open(deployment_file, "r") as f:
            deployment_info = json.load(f)
            return {
                "address": deployment_info["address"],
                "private_key": deployment_info["private_key"]
            }
    except Exception as e:
        logger.error(f"Failed to load deployer account: {e}")
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

async def register_did(account_info: Dict[str, str]) -> Dict[str, Any]:
    """Register a DID for an account on TestNet, with fees paid by deployer"""
    try:
        client = get_algod_client()
        params = client.suggested_params()
        
        # Generate user info hash if user_info is provided
        user_info_hash = None
        if "user_info" in account_info:
            user_info_hash = generate_user_info_hash(account_info["user_info"])
        
        # Adjust the validity window
        params.first = params.first
        params.last = params.first + 4
        
        # Get deployer account to pay for transaction
        deployer = get_deployer_account()
        
        # Create DID identifier from user's address
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
            "userInfoHash": user_info_hash  # Add the generated hash
        }
        
        # Create note for transaction
        note = json.dumps({
            "type": "DID_REGISTRATION",
            "did": did,
            "didDocument": did_document
        }).encode()

        # Create transaction - using deployer as sender
        txn = transaction.ApplicationCallTxn(
            sender=deployer["address"],  # Deployer pays for transaction
            sp=params,
            index=APP_ID,
            on_complete=transaction.OnComplete.NoOpOC,
            app_args=[b"register"],
            accounts=[account_info["address"]],  # Include user's address as an account
            note=note
        )

        # Sign with deployer's private key
        signed_txn = txn.sign(deployer["private_key"])
        tx_id = client.send_transaction(signed_txn)
        
        logger.info(f"Transaction {tx_id} sent to network")
        
        # Wait for confirmation
        confirmed_txn = await wait_for_confirmation(client, tx_id, timeout=15)
        
        return {
            "status": "success",
            "did": did,
            "didDocument": did_document,
            "transaction_id": tx_id,
            "confirmed_round": confirmed_txn["confirmed-round"],
            "paid_by": deployer["address"]
        }
        
    except Exception as e:
        logger.error(f"Failed to register DID: {str(e)}")
        raise Exception(f"Failed to register DID: {str(e)}")

async def resolve_did(did: str) -> Dict[str, Any]:
    """Resolve a DID to get its DID Document from TestNet"""
    try:
        indexer = get_indexer_client()
        
        # Extract address from DID
        address = did.replace(DID_PREFIX, "")
        
        # Search for DID registration transaction
        response = indexer.search_transactions(
            address=address,
            note_prefix=b"DID_REGISTRATION",
            application_id=APP_ID
        )
        
        if not response.get("transactions"):
            raise Exception("DID not found")
            
        # Get the latest transaction
        latest_tx = sorted(
            response["transactions"],
            key=lambda x: x["confirmed-round"],
            reverse=True
        )[0]
        
        # Decode the note to get DID Document
        note = base64.b64decode(latest_tx["note"]).decode()
        did_data = json.loads(note)
        
        return {
            "did": did,
            "didDocument": did_data["didDocument"],
            "metadata": {
                "chain": "algorand-testnet",
                "recovered": True
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

# Add this at the end of the file
register_did_with_document = register_did  # Alias for compatibility
