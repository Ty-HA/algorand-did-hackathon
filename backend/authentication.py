# authentication.py

import requests
import config
from algosdk import account, mnemonic
from typing import Optional, Tuple
import logging
from utils import logger
from did_management import resolve_did

class AuthenticationError(Exception):
    pass

def retrieve_did(did):
    resolver_url = f"http://localhost:8080/1.0/identifiers/{did}"
    response = requests.get(resolver_url)
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception("DID not found or failed to retrieve")

def verify_signature(message: str, signature: str, public_key: str) -> bool:
    try:
        # Implement signature verification using algosdk
        # This is a placeholder - implement actual verification logic
        return True
    except Exception as e:
        logger.error(f"Signature verification failed: {str(e)}")
        return False

def authenticate_user(did: str, signature: str, message: str) -> bool:
    try:
        # Get DID document
        did_doc = resolve_did(did)
        
        # Extract verification method
        verification_methods = did_doc.get("didDocument", {}).get("verificationMethod", [])
        if not verification_methods:
            raise AuthenticationError("No verification methods found in DID document")

        # Get the public key from verification method
        public_key = verification_methods[0].get("publicKeyBase58")
        if not public_key:
            raise AuthenticationError("No public key found in verification method")

        # Verify signature
        is_valid = verify_signature(message, signature, public_key)
        return is_valid

    except Exception as e:
        logger.error(f"Authentication failed: {str(e)}")
        raise AuthenticationError(str(e))

def generate_auth_token(did: str) -> str:
    # Implement token generation logic
    # This is a placeholder - implement actual token generation
    return f"token_{did}"
