import logging
from algosdk import account, mnemonic
from algosdk.v2client import algod
from algosdk import transaction
import base64
import hashlib
import time
import json
from base58 import b58encode

from ..core.config import ALGOD_ADDRESS, ALGOD_TOKEN
from ..core.utils import logger

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration Algorand TestNet
ALGOD_ADDRESS = "https://testnet-api.algonode.cloud"
ALGOD_TOKEN = ""
PERA_EXPLORER_TESTNET = "https://testnet.explorer.perawallet.app"

def get_algod_client():
    return algod.AlgodClient(ALGOD_TOKEN, ALGOD_ADDRESS)

def create_did_from_address(address: str) -> str:
    """Crée un DID à partir d'une adresse Algorand."""
    try:
        address_bytes = address.encode('utf-8')
        address_hash = hashlib.sha256(address_bytes).digest()
        truncated_hash = address_hash[:16]
        did_suffix = b58encode(truncated_hash).decode('utf-8')
        did = f"did:algo:{did_suffix}"
        logger.info(f"Created DID {did} for address {address}")
        logger.debug(f"Verify address on Pera Explorer: {PERA_EXPLORER_TESTNET}/address/{address}")
        return did
    except Exception as e:
        logger.error(f"Error creating DID: {e}")
        raise

def register_did_for_account(address: str, private_key: str = None, m_phrase: str = None):
    """
    Enregistre un DID pour un compte existant.
    Accepte soit la clé privée, soit la phrase mnémonique.
    """
    try:
        client = get_algod_client()
        
        # Obtenir la clé privée soit directement, soit via la phrase mnémonique
        if private_key is None and m_phrase is not None:
            private_key = mnemonic.to_private_key(m_phrase)
        elif private_key is None:
            raise ValueError("Either private_key or m_phrase must be provided")

        # Vérifier le solde du compte
        account_info = client.account_info(address)
        balance = account_info.get('amount', 0)
        logger.info(f"Account balance: {balance} microAlgos")

        # Créer le DID
        did = create_did_from_address(address)

        # Créer la note pour la transaction
        note = json.dumps({
            "type": "DID_REGISTRATION",
            "did": did,
            "timestamp": int(time.time())
        }).encode()

        # Obtenir les paramètres de transaction
        params = client.suggested_params()
        
        # Créer et signer la transaction
        unsigned_txn = transaction.PaymentTxn(
            sender=address,
            sp=params,
            receiver=address,  # Transaction à soi-même
            amt=0,            # Montant 0 car on stocke juste des données
            note=note
        )
        
        signed_txn = unsigned_txn.sign(private_key)
        
        # Envoyer la transaction
        tx_id = client.send_transaction(signed_txn)
        logger.info(f"Transaction sent with ID: {tx_id}")
        logger.info(f"🔍 Verify on Pera Explorer: {PERA_EXPLORER_TESTNET}/tx/{tx_id}")
        logger.info("Note: Attendre quelques secondes pour que la transaction soit visible sur l'explorateur")

        # Attendre la confirmation
        confirmed_txn = transaction.wait_for_confirmation(client, tx_id, 4)
        logger.info(f"Transaction confirmed in round: {confirmed_txn['confirmed-round']}")

        result = {
            "did": did,
            "address": address,
            "transaction_id": tx_id,
            "confirmation_round": confirmed_txn['confirmed-round'],
            "explorer_links": {
                "transaction": f"{PERA_EXPLORER_TESTNET}/tx/{tx_id}",
                "address": f"{PERA_EXPLORER_TESTNET}/address/{address}"
            }
        }

        logger.info("\n=== 🔍 Verification Links ===")
        logger.info(f"→ Transaction: {result['explorer_links']['transaction']}")
        logger.info(f"→ Address: {result['explorer_links']['address']}")
        logger.info("=========================")

        return result
    
    except Exception as e:
        logger.error(f"Failed to register DID: {e}")
        raise

if __name__ == "__main__":
    try:
        # Remplacez ces valeurs par celles de votre compte test
        TEST_ACCOUNT_ADDRESS = "S75EYJ6LZUGZWCNVEA4UARBEDTS4D2KQHPFJINLOIHDSALWANUVEK5JB7U"
        TEST_ACCOUNT_MNEMONIC = "believe bronze involve lottery scrub assault share symptom reduce penalty melt maze weird profit fun crisp speed husband crush update business empty public ability vault"
        
        result = register_did_for_account(
            address=TEST_ACCOUNT_ADDRESS,
            m_phrase=TEST_ACCOUNT_MNEMONIC
        )
        
        print("\n=== 📝 DID Registration Result ===")
        print(f"DID: {result['did']}")
        print(f"Address: {result['address']}")
        print(f"Transaction ID: {result['transaction_id']}")
        print(f"Confirmed in round: {result['confirmation_round']}")
        print("\n=== 🔍 Verification Links ===")
        print(f"→ Transaction: {result['explorer_links']['transaction']}")
        print(f"→ Address: {result['explorer_links']['address']}")
        print("================================\n")
        
    except Exception as e:
        logger.error(f"Main execution failed: {e}")