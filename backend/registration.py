# registration.py

from algosdk import account, mnemonic
from algosdk.v2client import algod
import config

def create_account():
    private_key, address = account.generate_account()
    passphrase = mnemonic.from_private_key(private_key)
    print(f"Account Address: {address}")
    print(f"Passphrase: {passphrase}")
    return address, passphrase, private_key

def register_user():
    address, passphrase, private_key = create_account()
    
    # Initialize Algorand client
    algod_client = algod.AlgodClient(config.ALGOD_TOKEN, config.ALGOD_ADDRESS, config.HEADERS)
    
    # Here, implement DID creation using Algorand SDK instead of CLI
    # This is a placeholder and needs to be implemented based on your specific DID creation logic
    did = f"did:algo:{address}"
    
    print(f"DID created for user {address}")
    
    return address, passphrase
