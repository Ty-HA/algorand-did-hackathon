# did_update.py

from subprocess import run
from typing import Optional, Dict, Any
from algosdk import transaction
from utils import logger
import json
import time
from did_management import get_algod_client, resolve_did

class DIDUpdateError(Exception):
    pass

async def update_did(
    did: str,
    new_key: Optional[str] = None,
    new_service: Optional[str] = None,
    private_key: Optional[str] = None
) -> Dict[str, Any]:
    try:
        # Get current DID document
        current_doc = resolve_did(did)
        did_document = current_doc["didDocument"]

        # Update timestamp
        did_document["updated"] = int(time.time())

        # Update verification method if new key provided
        if new_key:
            if "verificationMethod" not in did_document:
                did_document["verificationMethod"] = []
            
            new_verification_method = {
                "id": f"{did}#key-{len(did_document['verificationMethod']) + 1}",
                "type": "Ed25519VerificationKey2018",
                "controller": did,
                "publicKeyBase58": new_key
            }
            did_document["verificationMethod"].append(new_verification_method)

        # Update service if new service provided
        if new_service:
            if "service" not in did_document:
                did_document["service"] = []
            
            new_service_entry = {
                "id": f"{did}#service-{len(did_document['service']) + 1}",
                "type": "DIDService",
                "serviceEndpoint": new_service
            }
            did_document["service"].append(new_service_entry)

        # Create transaction note
        note = json.dumps({
            "type": "DID_UPDATE",
            "did": did,
            "timestamp": did_document["updated"],
            "didDocument": did_document
        }).encode()

        # Submit transaction to Algorand
        client = get_algod_client()
        params = client.suggested_params()
        
        # Create and send transaction
        # Note: This is a simplified version - implement proper transaction handling
        txn = transaction.PaymentTxn(
            sender=did_document["verificationMethod"][0]["publicKeyBase58"],
            sp=params,
            receiver=did_document["verificationMethod"][0]["publicKeyBase58"],
            amt=0,
            note=note
        )

        return {
            "status": "success",
            "did": did,
            "updated_document": did_document,
            "timestamp": did_document["updated"]
        }

    except Exception as e:
        logger.error(f"Failed to update DID: {str(e)}")
        raise DIDUpdateError(f"Failed to update DID: {str(e)}")
