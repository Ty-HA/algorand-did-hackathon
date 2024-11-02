import logging
from algosdk import account, mnemonic
from algosdk.v2client import algod, indexer
from algosdk import transaction
import base64
import hashlib
import time
import json
from datetime import datetime
from typing import Dict, Any, Optional

from ..core.config import (
    ALGOD_ADDRESS, 
    ALGOD_TOKEN, 
    APP_ID,
    DID_PREFIX
)
from ..core.utils import logger
from ..did.management import get_algod_client, get_deployer_account, wait_for_confirmation

def generate_box_key(credential_hash: str) -> str:
    """Generate a box key that's within the 64-byte limit"""
    # Take first 32 characters of the hash to stay within limits
    return f"cred_{credential_hash[:32]}"

async def issue_credential(
    category: str,
    subject: str,
    issuer_name: str,
    issuer_did: str,
    period: Dict[str, str],
    destinator_did: str,
    metadata: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """Issue a verifiable credential on Algorand TestNet"""
    try:
        client = get_algod_client()
        params = client.suggested_params()
        
        # Get deployer account to pay for transaction
        deployer = get_deployer_account()
        logger.info(f"Using deployer account: {deployer['address']}")
        
        # Create credential document
        credential_document = {
            "@context": [
                "https://www.w3.org/2018/credentials/v1",
                "https://www.w3.org/2018/credentials/examples/v1"
            ],
            "type": ["VerifiableCredential", category],
            "issuer": {
                "id": issuer_did,
                "name": issuer_name
            },
            "issuanceDate": datetime.utcnow().isoformat(),
            "credentialSubject": {
                "id": destinator_did,
                "subject": subject,
                "period": period
            },
            "metadata": metadata or {}
        }
        
        # Generate credential hash
        credential_bytes = json.dumps(credential_document, sort_keys=True).encode()
        credential_hash = hashlib.sha256(credential_bytes).hexdigest()
        
        # Generate box key (shorter version)
        box_key = f"cred_{credential_hash[:32]}"
        logger.info(f"Using box key: {box_key}")
        
        # Create transaction note
        note = json.dumps({
            "type": "CREDENTIAL_ISSUANCE",
            "credential_hash": credential_hash,
            "box_key": box_key,
            "issuer_did": issuer_did,
            "destinator_did": destinator_did,
            "timestamp": int(time.time())
        }).encode()

        # Create transaction
        txn = transaction.ApplicationCallTxn(
            sender=deployer["address"],
            sp=params,
            index=APP_ID,
            on_complete=transaction.OnComplete.NoOpOC,
            app_args=[b"issue_credential", box_key.encode()],
            boxes=[(APP_ID, box_key.encode())],
            note=note
        )

        # Handle private key using mnemonic
        try:
            # Convert private key to mnemonic
            m = mnemonic.from_private_key(deployer["private_key"])
            # Get signing key from mnemonic
            signing_key = mnemonic.to_private_key(m)
            logger.debug("Successfully processed private key using mnemonic")
            
            # Sign transaction
            signed_txn = txn.sign(signing_key)
            logger.info("Transaction signed successfully")
            
        except Exception as e:
            logger.error(f"Failed to process private key: {e}")
            raise

        # Send transaction
        tx_id = client.send_transaction(signed_txn)
        logger.info(f"Transaction {tx_id} sent to network")
        
        # Wait for confirmation
        confirmed_txn = await wait_for_confirmation(client, tx_id, timeout=15)
        
        return {
            "status": "success",
            "credential_hash": credential_hash,
            "box_key": box_key,
            "credential": credential_document,
            "transaction_id": tx_id,
            "confirmed_round": confirmed_txn["confirmed-round"]
        }
        
    except Exception as e:
        logger.error(f"Failed to issue credential: {str(e)}")
        raise Exception(f"Failed to issue credential: {str(e)}")

async def verify_credential(credential_hash: str) -> Dict[str, Any]:
    """Verify a credential on Algorand TestNet"""
    try:
        indexer = get_indexer_client()
        
        # Search for credential issuance transaction
        response = indexer.search_transactions(
            note_prefix=b"CREDENTIAL_ISSUANCE",
            application_id=APP_ID
        )
        
        if not response.get("transactions"):
            raise Exception("Credential not found")
            
        # Get the latest transaction
        latest_tx = sorted(
            response["transactions"],
            key=lambda x: x["confirmed-round"],
            reverse=True
        )[0]
        
        # Decode the note to get credential
        note = base64.b64decode(latest_tx["note"]).decode()
        credential_data = json.loads(note)
        
        if credential_data["credential_hash"] != credential_hash:
            raise Exception("Credential hash mismatch")
        
        return {
            "status": "valid",
            "credential": credential_data["credential"],
            "metadata": {
                "chain": "algorand-testnet",
                "issuer": credential_data["issuer_did"],
                "destinator": credential_data["destinator_did"],
                "issuance_timestamp": credential_data["timestamp"]
            }
        }
        
    except Exception as e:
        raise Exception(f"Failed to verify credential: {str(e)}") 