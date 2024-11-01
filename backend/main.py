from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any
import logging
import json
import hashlib
import uuid
import base64
import datetime
from algosdk.v2client import indexer
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

# async def verify_did(transaction_id: str) -> Dict[str, Any]:
    # try:
        # client = get_algod_client()
        # Implement your verification logic here
        # return {
             # "status": "success",
            # "transaction_id": transaction_id,
            # "verified": True
        # }
    # except Exception as e:
        # raise HTTPException(status_code=404, detail=str(e))


async def verify_did(did: str, transaction_id: str) -> bool:
    try:
        # 1. Vérifier que la transaction existe
        indexer = get_indexer_client()
        txn_info = indexer.transaction(transaction_id)
        
        # 2. Vérifier le format de la note avant le décodage
        if "note" not in txn_info or not txn_info["note"]:
            logger.error("No note found in transaction")
            return False
            
        # 3. Vérifier que le DID est dans la transaction
        try:
            note = base64.b64decode(txn_info["note"]).decode()
            did_data = json.loads(note)
        except Exception as e:
            logger.error(f"Error decoding note: {e}")
            return False
        
        # 4. Vérifier que la transaction est une transaction DID_REGISTRATION
        if "type" not in did_data or did_data["type"] != "DID_REGISTRATION":
            logger.error("Not a DID_REGISTRATION transaction")
            return False
            
        # 5. Vérifier que le DID dans la transaction correspond
        if "did" not in did_data or did_data["did"] != did:
            logger.error("DID mismatch")
            return False
            
        logger.info(f"DID {did} verified successfully")
        return True
    except Exception as e:
        logger.error(f"Error verifying DID: {e}")
        return False

class VerifyDIDRequest(BaseModel):
    did: str
    transaction_id: str
    did_document: Dict[str, Any]

@app.post("/verify-did")
async def verify_did_endpoint(request: VerifyDIDRequest) -> Dict[str, Any]:
    try:
        # Vérifier la transaction sur la blockchain
        is_valid = await verify_did(request.did, request.transaction_id)
        
        if not is_valid:
            raise HTTPException(
                status_code=400,
                detail="Invalid DID or transaction"
            )
            
        # Vérifier que le DID document correspond
        try:
            stored_did = await resolve_did(request.did)
            if stored_did["didDocument"] != request.did_document:
                raise HTTPException(
                    status_code=400,
                    detail="DID document mismatch"
                )
        except Exception as e:
            logger.error(f"Error verifying DID document: {e}")
            raise HTTPException(
                status_code=400,
                detail="Error verifying DID document"
            )
            
        return {
            "status": "success",
            "verified": True,
            "did": request.did,
            "transaction_id": request.transaction_id,
            "verification_timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Verification failed: {e}")
        raise HTTPException(
            status_code=400,
            detail=f"Verification failed: {str(e)}"
        )