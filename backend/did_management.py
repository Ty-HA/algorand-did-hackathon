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
from typing import List, Dict, Optional, Union
from base58 import b58encode, b58decode

# Configuration du logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration Algorand TestNet
ALGOD_ADDRESS = "https://testnet-api.algonode.cloud"
ALGOD_TOKEN = ""
INDEXER_ADDRESS = "https://testnet-idx.algonode.cloud"
INDEXER_TOKEN = ""
PERA_EXPLORER_TESTNET = "https://testnet.explorer.perawallet.app"

# Configuration des types de transactions
TX_TYPE_DID_REGISTRATION = "DID_REGISTRATION"
TX_TYPE_DID_UPDATE = "DID_UPDATE"
TX_TYPE_DID_DEACTIVATE = "DID_DEACTIVATE"

def get_algod_client() -> algod.AlgodClient:
    """Retourne un client Algorand pour le TestNet."""
    return algod.AlgodClient(ALGOD_TOKEN, ALGOD_ADDRESS)

def get_indexer_client() -> indexer.IndexerClient:
    """Retourne un client Indexer pour le TestNet."""
    return indexer.IndexerClient(INDEXER_TOKEN, INDEXER_ADDRESS)

def verify_existing_did(client, address: str) -> dict:
    """
    Vérifie si une adresse a déjà un DID enregistré.
    """
    try:
        # Récupérer les transactions de l'adresse
        transactions = client.search_transactions(
            address=address,
            txn_type="pay",
            note_prefix=json.dumps({"type": "DID_REGISTRATION"}).encode()[:10]
        )

        dids_found = []
        for tx in transactions:
            if "note" in tx:
                note_bytes = base64.b64decode(tx["note"])
                note_json = json.loads(note_bytes.decode())
                if note_json["type"] == "DID_REGISTRATION":
                    dids_found.append({
                        "did": note_json["did"],
                        "timestamp": note_json["timestamp"],
                        "tx_id": tx["id"]
                    })

        return {
            "address": address,
            "has_did": len(dids_found) > 0,
            "did_count": len(dids_found),
            "dids": dids_found
        }
    except Exception as e:
        logger.error(f"Error verifying existing DID: {e}")
        raise

def create_did_document(did: str, address: str, controller: str = None) -> dict:
    """
    Crée un DID Document conforme aux standards W3C.
    """
    timestamp = int(time.time())
    
    did_document = {
        "@context": [
            "https://www.w3.org/ns/did/v1",
            "https://w3id.org/security/suites/ed25519-2018/v1"
        ],
        "id": did,
        "controller": controller or did,
        "verificationMethod": [{
            "id": f"{did}#key-1",
            "type": "Ed25519VerificationKey2018",
            "controller": did,
            "publicKeyBase58": address
        }],
        "authentication": [
            f"{did}#key-1"
        ],
        "assertionMethod": [
            f"{did}#key-1"
        ],
        "created": timestamp,
        "updated": timestamp,
        "alsoKnownAs": [
            f"algorand:{address}"
        ]
    }
    
    return did_document

def create_did_from_address(address: str) -> str:
    """
    Crée un DID à partir d'une adresse Algorand.
    Format: did:algo:base58(sha256(address)[:16])
    """
    try:
        address_bytes = address.encode('utf-8')
        address_hash = hashlib.sha256(address_bytes).digest()
        truncated_hash = address_hash[:16]
        
        # Encoder en base58 (importé en haut du fichier)
        did_suffix = b58encode(truncated_hash).decode('utf-8')
        did = f"did:algo:{did_suffix}"
        
        logger.debug(f"Created DID {did} for address {address}")
        return did
    except Exception as e:
        logger.error(f"Error creating DID: {e}")
        raise Exception(f"Failed to create DID: {str(e)}")

def register_did_with_document(address: str, private_key: str = None, m_phrase: str = None):
    """
    Enregistre un DID avec son DID Document sur la blockchain.
    """
    try:
        client = get_algod_client()
        
        # Vérifier si l'adresse a déjà un DID
        existing = verify_existing_did(client, address)
        if existing["has_did"]:
            raise Exception(f"Address already has {existing['did_count']} DID(s) registered")
        
        # Créer le DID
        did = create_did_from_address(address)
        
        # Créer le DID Document
        did_document = create_did_document(did, address)
        
        # Créer la note pour la transaction
        note = json.dumps({
            "type": "DID_REGISTRATION",
            "did": did,
            "timestamp": int(time.time()),
            "didDocument": did_document
        }).encode()
        
        # Obtenir la clé privée
        if private_key is None and m_phrase is not None:
            private_key = mnemonic.to_private_key(m_phrase)
            
        # Créer et envoyer la transaction
        params = client.suggested_params()
        unsigned_txn = transaction.PaymentTxn(
            sender=address,
            sp=params,
            receiver=address,
            amt=0,
            note=note
        )
        
        signed_txn = unsigned_txn.sign(private_key)
        tx_id = client.send_transaction(signed_txn)
        
        # Attendre la confirmation
        confirmed_txn = transaction.wait_for_confirmation(client, tx_id, 4)
        
        return {
            "did": did,
            "didDocument": did_document,
            "transaction_id": tx_id,
            "confirmation_round": confirmed_txn['confirmed-round'],
            "explorer_link": f"{PERA_EXPLORER_TESTNET}/tx/{tx_id}"
        }
        
    except Exception as e:
        logger.error(f"Failed to register DID with document: {e}")
        raise

def resolve_did(did: str) -> dict:
    """
    Résout un DID pour obtenir son DID Document.
    """
    try:
        client = get_algod_client()
        
        # Extraire l'adresse du DID
        did_suffix = did.split(':')[-1]
        # Ici vous devrez implémenter la logique inverse de create_did_from_address
        
        # Rechercher la dernière transaction DID_REGISTRATION
        transactions = client.search_transactions(
            note_prefix=json.dumps({"type": "DID_REGISTRATION", "did": did}).encode()[:20]
        )
        
        latest_doc = None
        latest_timestamp = 0
        
        for tx in transactions:
            if "note" in tx:
                note_bytes = base64.b64decode(tx["note"])
                note_json = json.loads(note_bytes.decode())
                if note_json["type"] == "DID_REGISTRATION" and note_json["did"] == did:
                    if note_json["timestamp"] > latest_timestamp:
                        latest_timestamp = note_json["timestamp"]
                        latest_doc = note_json.get("didDocument")
        
        if not latest_doc:
            raise Exception(f"No DID Document found for {did}")
            
        return {
            "did": did,
            "didDocument": latest_doc,
            "timestamp": latest_timestamp,
            "metadata": {
                "recovered": True,
                "network": "testnet"
            }
        }
        
    except Exception as e:
        logger.error(f"Failed to resolve DID: {e}")
        raise