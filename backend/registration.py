import logging
from algosdk import account, mnemonic
from algosdk.v2client import algod
import base64
import hashlib
import time

# Configuration du logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration Algorand TestNet
ALGOD_ADDRESS = "https://testnet-api.algonode.cloud"
ALGOD_TOKEN = ""  # Token non requis pour TestNet public

def get_algod_client():
    """Crée et retourne un client Algorand pour TestNet."""
    try:
        client = algod.AlgodClient(ALGOD_TOKEN, ALGOD_ADDRESS)
        # Vérifier la connexion
        status = client.status()
        logger.info(f"Connected to TestNet. Last round: {status['last-round']}")
        return client
    except Exception as e:
        logger.error(f"Failed to connect to TestNet: {e}")
        raise Exception("Could not connect to Algorand TestNet")

def create_did_from_address(address: str) -> str:
    """
    Crée un DID à partir d'une adresse Algorand.
    Format: did:algo:base58(sha256(address)[:16])
    """
    try:
        address_bytes = address.encode('utf-8')
        address_hash = hashlib.sha256(address_bytes).digest()
        truncated_hash = address_hash[:16]
        
        # Encoder en base58
        from base58 import b58encode
        did_suffix = b58encode(truncated_hash).decode('utf-8')
        did = f"did:algo:{did_suffix}"
        
        logger.debug(f"Created DID {did} for address {address}")
        return did
    except Exception as e:
        logger.error(f"Error creating DID: {e}")
        raise Exception("Failed to create DID")

def register_user():
    """
    Enregistre un nouvel utilisateur sur Algorand et génère son DID.
    Retourne un dictionnaire contenant le DID, l'adresse, la passphrase et l'ID de transaction.
    """
    try:
        logger.info("Starting user registration")
        
        # Obtenir le client Algorand
        client = get_algod_client()
        
        # Générer une nouvelle paire de clés
        private_key, address = account.generate_account()
        logger.debug(f"Generated address: {address}")
        
        # Créer le DID
        did = create_did_from_address(address)
        logger.info(f"Created DID: {did}")
        
        # Générer la phrase mnémonique
        passphrase = mnemonic.from_private_key(private_key)
        logger.debug("Generated passphrase")

        try:
            # Préparer pour une vraie transaction dans le futur
            params = client.suggested_params()
            logger.debug(f"Got suggested parameters: {params}")
            # Pour l'instant, simulation de transaction
            transaction_id = "SIMULATED_TX_" + base64.b64encode(address.encode()).decode()[:16]
            logger.debug(f"Created simulated transaction ID: {transaction_id}")
        except Exception as tx_error:
            logger.error(f"Transaction preparation failed: {tx_error}")
            transaction_id = None
        
        result = {
            "did": did,
            "address": address,
            "passphrase": passphrase,
            "transaction_id": transaction_id
        }
        
        logger.info("User registration completed successfully")
        return result
        
    except Exception as e:
        logger.error(f"Registration failed: {e}", exc_info=True)
        raise Exception(f"Failed to register user: {str(e)}")

def test_connection():
    """Test de la connexion au réseau Algorand."""
    try:
        client = get_algod_client()
        status = client.status()
        network_info = {
            "status": "connected",
            "last_round": status['last-round'],
            "catchup_time": status.get('catchup-time', None),
            "network": "TestNet"
        }
        logger.info(f"Successfully connected to Algorand. Network status: {network_info}")
        return True
    except Exception as e:
        logger.error(f"Failed to connect to Algorand: {e}", exc_info=True)
        return False

if __name__ == "__main__":
    # Test de connexion au démarrage
    logger.info("Testing Algorand connection...")
    if test_connection():
        logger.info("Algorand connection test successful")
    else:
        logger.error("Algorand connection test failed")