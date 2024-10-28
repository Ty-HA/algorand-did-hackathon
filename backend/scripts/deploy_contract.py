from algosdk import account, transaction
from algosdk.v2client import algod
import base64
import os
import sys
import time

# Add the backend directory to the path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, backend_dir)

from config import ALGOD_ADDRESS, ALGOD_TOKEN

def compile_program(client, source_code):
    """Compile TEAL source code to binary"""
    compile_response = client.compile(source_code)
    return base64.b64decode(compile_response['result'])

def wait_for_funding(client, address):
    """Wait for account to be funded"""
    print(f"\nPlease fund the account {address} using the Algorand TestNet Dispenser:")
    print("https://bank.testnet.algorand.network/")
    print("\nWaiting for funding...")
    
    while True:
        account_info = client.account_info(address)
        if account_info.get("amount", 0) > 0:
            print(f"Account funded successfully! Balance: {account_info['amount']} microAlgos")
            return True
        time.sleep(5)  # Check every 5 seconds

def deploy_contract():
    try:
        # Initialize Algod client
        client = algod.AlgodClient(ALGOD_TOKEN, ALGOD_ADDRESS)

        # Create new account for testing
        private_key, address = account.generate_account()
        print(f"\nCreated new account: {address}")
        print(f"Save this private key: {private_key}")
        
        # Wait for account funding
        if not wait_for_funding(client, address):
            print("Failed to fund account")
            return None

        # Read the TEAL files
        with open("contracts/approval.teal", "r") as f:
            approval_source = f.read()

        with open("contracts/clear.teal", "r") as f:
            clear_source = f.read()

        # Compile the programs
        print("\nCompiling TEAL programs...")
        approval_program = compile_program(client, approval_source)
        clear_program = compile_program(client, clear_source)

        # Get suggested parameters
        params = client.suggested_params()

        # Create unsigned transaction
        print("\nCreating application...")
        txn = transaction.ApplicationCreateTxn(
            sender=address,
            sp=params,
            on_complete=transaction.OnComplete.NoOpOC,
            approval_program=approval_program,
            clear_program=clear_program,
            global_schema=transaction.StateSchema(num_uints=1, num_byte_slices=1),
            local_schema=transaction.StateSchema(num_uints=0, num_byte_slices=0)
        )

        # Sign transaction
        signed_txn = txn.sign(private_key)

        # Send transaction
        print("Sending transaction...")
        tx_id = client.send_transaction(signed_txn)
        
        # Wait for confirmation
        print("Waiting for confirmation...")
        confirmed_txn = transaction.wait_for_confirmation(client, tx_id, 4)
        app_id = confirmed_txn["application-index"]
        print(f"\nCreated new app with app_id: {app_id}")
        
        # Save deployment info
        deployment_info = {
            "app_id": app_id,
            "address": address,
            "private_key": private_key,
            "transaction_id": tx_id
        }
        
        with open("deployment_info.json", "w") as f:
            import json
            json.dump(deployment_info, f, indent=2)
            print(f"\nDeployment info saved to deployment_info.json")
        
        return app_id
    
    except Exception as e:
        print(f"\nError deploying contract: {e}")
        return None

if __name__ == "__main__":
    print("\nDeploying DID Management Contract to Algorand TestNet...")
    app_id = deploy_contract()
    if app_id:
        print(f"\nUpdate config.py with APP_ID = {app_id}")
        print("\nDeployment successful!")
    else:
        print("\nDeployment failed!")
