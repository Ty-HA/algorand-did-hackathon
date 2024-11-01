from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any
import logging
import json
import hashlib
import uuid
from algosdk import account, mnemonic  # Ajoutez ces imports
from did_management import register_did, resolve_did, get_algod_client
from data_display import display_user_data
from did_update import update_did

# Configuration du logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Algorand DID Management",
    description="Decentralized Identity Management System on Algorand",
    version="1.0.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifiez les domaines exacts
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DIDRegistrationRequest(BaseModel):
    address: str
    private_key: Optional[str] = None
    mnemonic: Optional[str] = None
    user_info: Optional[Dict[str, Any]] = None

class DIDUpdateRequest(BaseModel):
    did: str
    new_key: Optional[str] = None
    new_service: Optional[str] = None

class RegistrationResponse(BaseModel):
    status: str
    did: Optional[str] = None
    message: str

def generate_user_info_hash(user_info: Dict[str, Any] = None) -> str:
    """Generate a SHA-256 hash from user information"""
    if user_info:
        info_string = json.dumps(user_info, sort_keys=True)
    else:
        info_string = str(uuid.uuid4())  # Generate random hash if no user info provided
    return hashlib.sha256(info_string.encode()).hexdigest()

@app.post("/register")
async def register_did_endpoint(request: DIDRegistrationRequest) -> Dict[str, Any]:
    try:
        # Generate user info hash
        user_info_hash = generate_user_info_hash(request.user_info)
        
        # Générer un nouveau compte Algorand si aucune adresse n'est fournie
        if not request.address:
            # Créer un nouveau compte
            private_key, address = account.generate_account()
            passphrase = mnemonic.from_private_key(private_key)
            user_info_hash = generate_user_info_hash()
            
            # Créer les informations du compte
            account_info = {
                "address": address,
                "private_key": private_key,
                "passphrase": passphrase,
                "user_info_hash": user_info_hash
            }
        else:
            account_info = {
                "address": request.address,
                "private_key": request.private_key,
                "mnemonic": request.mnemonic,
                "user_info_hash": user_info_hash
            }

        # Enregistrer le DID
        result = await register_did(account_info)

         # Add explorer links
        result["explorer_links"] = {
            "transaction": f"https://testnet.explorer.perawallet.app/tx/{result['transaction_id']}",
            "address": f"https://testnet.explorer.perawallet.app/address/{request.address}"
        }
        
        # Ajouter la passphrase à la réponse si un nouveau compte a été créé
        if not request.address:
            result["passphrase"] = passphrase
            
        return result
    except Exception as e:
        logger.error(f"Registration failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/resolve/{did}")
async def resolve_did_endpoint(did: str) -> Dict[str, Any]:
    try:
        result = await resolve_did(did)
        return result
    except Exception as e:
        logger.error(f"DID resolution failed: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/display/{did}")
async def display_did_data(did: str) -> Dict[str, Any]:
    try:
        return display_user_data(did)
    except Exception as e:
        logger.error(f"Data display failed: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

@app.put("/update")
async def update_did_endpoint(request: DIDUpdateRequest) -> Dict[str, Any]:
    try:
        return await update_did(
            did=request.did,
            new_key=request.new_key,
            new_service=request.new_service
        )
    except Exception as e:
        logger.error(f"DID update failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/health")
async def health_check() -> Dict[str, str]:
    """
    Simple health check endpoint.
    """
    return {"status": "healthy", "version": "1.0.0"}

@app.get("/verify-did/{transaction_id}")
async def verify_did(transaction_id: str) -> Dict[str, Any]:
    try:
        client = get_algod_client()
        # Implement your verification logic here
        return {
            "status": "success",
            "transaction_id": transaction_id,
            "verified": True
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))
