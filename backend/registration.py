import logging
from algosdk import account, mnemonic
import base64
import hashlib

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def create_did_from_address(address: str) -> str:
    """Convertit une adresse Algorand en DID."""
    try:
        # Format: did:algo:base58(sha256(address))
        address_bytes = address.encode('utf-8')
        address_hash = hashlib.sha256(address_bytes).digest()
        # Prendre les 16 premiers octets du hash pour un identifiant plus court
        truncated_hash = address_hash[:16]
        # Encoder en base58 pour un format plus lisible
        from base58 import b58encode
        did_suffix = b58encode(truncated_hash).decode('utf-8')
        did = f"did:algo:{did_suffix}"
        return did
    except Exception as e:
        logger.error(f"Error creating DID: {e}")
        raise Exception("Failed to create DID")

def register_user():
    """
    Enregistre un nouvel utilisateur et génère son DID.
    Retourne (did, address, passphrase)
    """
    try:
        logger.info("Generating new account")
        # Générer une nouvelle paire de clés
        private_key, address = account.generate_account()
        logger.debug(f"Generated address: {address}")
        
        # Créer le DID
        did = create_did_from_address(address)
        logger.info(f"Created DID: {did}")
        
        # Générer la phrase mnémonique
        passphrase = mnemonic.from_private_key(private_key)
        logger.debug("Generated passphrase")
        
        return {
            "did": did,
            "address": address,
            "passphrase": passphrase
        }
        
    except Exception as e:
        logger.error(f"Registration failed: {e}")
        raise Exception(f"Failed to register user: {str(e)}")