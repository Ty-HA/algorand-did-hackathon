from algosdk import account, mnemonic
import json
import os
from datetime import datetime
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class AccountGenerator:
    def __init__(self):
        self.accounts_file = "accounts_record.json"
        self.accounts = self._load_accounts()

    def _load_accounts(self):
        """Load existing accounts from file"""
        try:
            if os.path.exists(self.accounts_file):
                with open(self.accounts_file, 'r') as f:
                    return json.load(f)
            return {"accounts": []}
        except Exception as e:
            logger.error(f"Error loading accounts: {e}")
            return {"accounts": []}

    def _save_accounts(self):
        """Save accounts to file"""
        try:
            with open(self.accounts_file, 'w') as f:
                json.dump(self.accounts, f, indent=2)
        except Exception as e:
            logger.error(f"Error saving accounts: {e}")

    def create_account(self, label: str = None):
        """Create a new Algorand account and save it to record"""
        try:
            # Generate account
            private_key, address = account.generate_account()
            passphrase = mnemonic.from_private_key(private_key)
            
            # Create account record
            account_record = {
                "label": label or f"account_{len(self.accounts['accounts']) + 1}",
                "address": address,
                "private_key": private_key,
                "passphrase": passphrase,
                "created_at": datetime.now().isoformat(),
                "funded": False,
                "balance": 0,
                "transactions": []
            }
            
            # Add to accounts list
            self.accounts["accounts"].append(account_record)
            
            # Save updated records
            self._save_accounts()
            
            logger.info(f"Created new account with label: {account_record['label']}")
            logger.info(f"Address: {address}")
            logger.info("Please fund this account at: https://bank.testnet.algorand.network/")
            
            return account_record
            
        except Exception as e:
            logger.error(f"Error creating account: {e}")
            raise

    def list_accounts(self):
        """List all accounts"""
        return self.accounts["accounts"]

    def get_account(self, address=None, label=None):
        """Get account by address or label"""
        for account in self.accounts["accounts"]:
            if address and account["address"] == address:
                return account
            if label and account["label"] == label:
                return account
        return None

    def update_account_status(self, address, funded=None, balance=None, new_transaction=None):
        """Update account status"""
        for account in self.accounts["accounts"]:
            if account["address"] == address:
                if funded is not None:
                    account["funded"] = funded
                if balance is not None:
                    account["balance"] = balance
                if new_transaction:
                    account["transactions"].append(new_transaction)
                self._save_accounts()
                return True
        return False

def main():
    generator = AccountGenerator()
    
    while True:
        print("\nAlgorand Account Generator")
        print("1. Create new account")
        print("2. List all accounts")
        print("3. Get account details")
        print("4. Exit")
        
        choice = input("\nEnter your choice (1-4): ")
        
        if choice == "1":
            label = input("Enter account label (or press Enter for default): ")
            account = generator.create_account(label if label else None)
            print("\nAccount created successfully!")
            print(f"Address: {account['address']}")
            print(f"Private Key: {account['private_key']}")
            print(f"Passphrase: {account['passphrase']}")
            
        elif choice == "2":
            accounts = generator.list_accounts()
            print("\nAll Accounts:")
            for acc in accounts:
                print(f"\nLabel: {acc['label']}")
                print(f"Address: {acc['address']}")
                print(f"Funded: {acc['funded']}")
                print(f"Balance: {acc['balance']}")
                
        elif choice == "3":
            identifier = input("Enter account address or label: ")
            account = generator.get_account(address=identifier) or generator.get_account(label=identifier)
            if account:
                print("\nAccount Details:")
                for key, value in account.items():
                    print(f"{key}: {value}")
            else:
                print("Account not found")
                
        elif choice == "4":
            print("Goodbye!")
            break
            
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    main() 