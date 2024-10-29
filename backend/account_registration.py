import logging
from algosdk import account, mnemonic
from algosdk.v2client import algod
from algosdk import transaction
import base64
import hashlib
import time
import json
from base58 import b58encode
from datetime import datetime
import os

# Configuration du logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration Algorand TestNet
ALGOD_ADDRESS = "https://testnet-api.algonode.cloud"
ALGOD_TOKEN = ""  # Token non requis pour TestNet public

# Créer un fichier de log avec la date
log_filename = f"logs/registration_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

# Configuration du logging pour écrire dans un fichier et la console
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_filename),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def ensure_directory_exists(file_path):
    """Ensure the directory exists for the given file path"""
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        os.makedirs(directory)

def save_account_info(account_data):
    """Save account information to logs/accounts/accounts_record.json"""
    accounts_file = os.path.join("logs", "accounts", "accounts_record.json")
    
    # Ensure the directory exists
    ensure_directory_exists(accounts_file)
    
    # Load existing accounts or create new structure
    try:
        if os.path.exists(accounts_file):
            with open(accounts_file, 'r') as f:
                accounts = json.load(f)
        else:
            accounts = {"accounts": []}
    except Exception as e:
        logger.error(f"Error loading accounts file: {e}")
        accounts = {"accounts": []}

    # Add new account with timestamp
    account_record = {
        "label": f"account_{len(accounts['accounts']) + 1}",
        "address": account_data["address"],
        "passphrase": account_data["passphrase"],
        "did": account_data["did"],
        "transaction_id": account_data["transaction_id"],
        "created_at": datetime.now().isoformat(),
        "funded": False,
        "balance": 0,
        "transactions": []
    }
    
    accounts["accounts"].append(account_record)

    # Save updated accounts
    try:
        with open(accounts_file, 'w') as f:
            json.dump(accounts, f, indent=2)
        logger.info(f"Account information saved to {accounts_file}")
        
        # Also save sensitive info to separate log file
        sensitive_log = os.path.join("logs", "accounts", f"account_info_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
        with open(sensitive_log, 'w') as f:
            f.write("=== ACCOUNT INFORMATION ===\n")
            f.write(f"Address: {account_data['address']}\n")
            f.write(f"Mnemonic: {account_data['passphrase']}\n")
            f.write(f"DID: {account_data['did']}\n")
            f.write(f"Transaction ID: {account_data['transaction_id']}\n")
            f.write("=========================\n")
        
        return accounts_file
    except Exception as e:
        logger.error(f"Failed to save account info: {e}")
        return None

def get_algod_client():
    """Crée et retourne un client Algorand pour TestNet."""
    try:
        client = algod.AlgodClient(ALGOD_TOKEN, ALGOD_ADDRESS)
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
        
        # Encoder en base58 (importé en haut du fichier)
        did_suffix = b58encode(truncated_hash).decode('utf-8')
        did = f"did:algo:{did_suffix}"
        
        logger.debug(f"Created DID {did} for address {address}")
        return did
    except Exception as e:
        logger.error(f"Error creating DID: {e}")
        raise Exception(f"Failed to create DID: {str(e)}")

def create_onchain_transaction(client, private_key, did):
    """
    Crée et envoie une transaction pour enregistrer le DID sur la blockchain.
    """
    try:
        # Récupérer l'adresse de l'expéditeur à partir de la clé privée
        sender = account.address_from_private_key(private_key)
        
        # Obtenir les paramètres suggérés
        params = client.suggested_params()
        logger.debug(f"Got suggested parameters for transaction")

        # Créer une note contenant le DID
        note = json.dumps({
            "type": "DID_REGISTRATION",
            "did": did,
            "timestamp": int(time.time())
        }).encode()

        # Créer la transaction (modifié ici pour utiliser PaymentTxn correctement)
        try:
            unsigned_txn = transaction.PaymentTxn(
                sender=sender,
                sp=params,
                receiver=sender,  # Transaction à soi-même
                amt=0,            # Montant 0 car on stocke juste des données
                note=note
            )

            # Signer la transaction
            signed_txn = unsigned_txn.sign(private_key)
            logger.debug("Transaction signed successfully")

            # Envoyer la transaction
            tx_id = client.send_transaction(signed_txn)
            logger.info(f"Transaction sent with ID: {tx_id}")

            # Attendre la confirmation
            confirmed_txn = transaction.wait_for_confirmation(client, tx_id, 4)
            logger.info(f"Transaction confirmed in round: {confirmed_txn['confirmed-round']}")

            return tx_id, confirmed_txn

        except Exception as tx_error:
            logger.error(f"Transaction creation/sending failed: {tx_error}")
            raise Exception(f"Transaction failed: {str(tx_error)}")

    except Exception as e:
        logger.error(f"Failed to create on-chain transaction: {e}")
        raise Exception(f"On-chain registration failed: {str(e)}")

def verify_onchain_did(client, transaction_id):
    """
    Vérifie un DID enregistré sur la blockchain.
    """
    try:
        # Récupérer la transaction
        transaction = client.pending_transaction_info(transaction_id)
        
        # Décoder la note
        if "note" in transaction:
            note_bytes = base64.b64decode(transaction["note"])
            note_json = json.loads(note_bytes.decode())
            
            if note_json["type"] == "DID_REGISTRATION":
                logger.info(f"DID verification successful: {note_json['did']}")
                return {
                    "status": "confirmed",
                    "did": note_json["did"],
                    "timestamp": note_json["timestamp"],
                    "block": transaction["confirmed-round"]
                }
        
        logger.warning("No valid DID registration found in transaction")
        return {"status": "invalid", "error": "No valid DID registration found"}
        
    except Exception as e:
        logger.error(f"DID verification failed: {e}")
        return {"status": "failed", "error": str(e)}

def register_user():
    """Register a new user with logging detailed."""
    try:
        logger.info("Starting user registration process...")
        
        # Generate new account
        private_key, address = account.generate_account()
        logger.info("=== IMPORTANT: SAVE THESE DETAILS ===")
        logger.info(f"Address: {address}")
        
        # Generate mnemonic
        passphrase = mnemonic.from_private_key(private_key)
        logger.info(f"Mnemonic Passphrase: {passphrase}")
        logger.info("==============================")
        
        # Create DID
        did = create_did_from_address(address)
        logger.info(f"Created DID: {did}")
        
        try:
            # Attempt on-chain transaction
            client = get_algod_client()
            params = client.suggested_params()
            logger.debug(f"Network parameters: {params.__dict__}")
            
            # Create note with DID
            note = json.dumps({
                "type": "DID_REGISTRATION",
                "did": did,
                "timestamp": int(time.time())
            }).encode()

            # Create transaction
            unsigned_txn = transaction.PaymentTxn(
                sender=address,
                sp=params,
                receiver=address,
                amt=0,
                note=note
            )
            
            signed_txn = unsigned_txn.sign(private_key)
            logger.debug("Transaction signed successfully")

            tx_id = client.send_transaction(signed_txn)
            logger.info(f"Transaction ID: {tx_id}")

        except Exception as tx_error:
            logger.error(f"Transaction failed: {tx_error}")
            tx_id = "FAILED_TX_" + base64.b64encode(address.encode()).decode()[:16]

        # Save account information
        account_data = {
            "address": address,
            "passphrase": passphrase,
            "did": did,
            "transaction_id": tx_id
        }
        
        saved_file = save_account_info(account_data)
        if saved_file:
            logger.info(f"All account details saved to: {saved_file}")
        
        return account_data

    except Exception as e:
        logger.error(f"Registration failed: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    try:
        logger.info("Starting registration process...")
        result = register_user()
        
        print("\n=== ACCOUNT CREATION SUCCESSFUL ===")
        print(f"Address: {result['address']}")
        print(f"DID: {result['did']}")
        print(f"Transaction ID: {result['transaction_id']}")
        print("\nIMPORTANT: Your mnemonic phrase has been saved to the logs directory.")
        print("Please keep it safe as it's required to recover your account!")
        print("=====================================\n")
        
    except Exception as e:
        logger.error(f"Process failed: {e}")