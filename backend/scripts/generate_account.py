from algosdk import account, mnemonic
import json
import os
from datetime import datetime
import logging
import sys

# Add the backend directory to the path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, backend_dir)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def ensure_directory_exists(file_path):
    """Ensure the directory exists for the given file path"""
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        os.makedirs(directory)

def create_account(label: str = None):
    """Create a new Algorand account and save info to file"""
    try:
        # Generate account
        private_key, address = account.generate_account()
        passphrase = mnemonic.from_private_key(private_key)
        
        # Create account info
        account_info = {
            "label": label or f"account_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "address": address,
            "private_key": private_key,
            "passphrase": passphrase,
            "created_at": datetime.now().isoformat()
        }
        
        # Save account info to file
        account_file = os.path.join(backend_dir, "logs", "accounts", f"account_info_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
        ensure_directory_exists(account_file)
        
        with open(account_file, 'w') as f:
            json.dump(account_info, f, indent=2)
        
        logger.info(f"Created new account with label: {account_info['label']}")
        logger.info(f"Address: {address}")
        logger.info(f"Account info saved to: {account_file}")
        logger.info("Please fund this account at: https://bank.testnet.algorand.network/")
        
        return account_info
            
    except Exception as e:
        logger.error(f"Error creating account: {e}")
        raise

def main():
    try:
        label = input("\nEnter account label (or press Enter for default): ")
        account = create_account(label if label else None)
        
        print("\n=== ACCOUNT CREATION SUCCESSFUL ===")
        print(f"Address: {account['address']}")
        print(f"\nIMPORTANT: Account details saved to:")
        print(f"logs/accounts/account_info_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
        print("\nPlease fund this account at: https://bank.testnet.algorand.network/")
        print("=====================================")
        
    except Exception as e:
        print(f"\nError: {e}")

if __name__ == "__main__":
    main() 