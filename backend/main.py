from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any
import logging
import hashlib
import uuid
import json
from did_management import register_did, resolve_did, get_algod_client
from data_display import display_user_data
from did_update import update_did

# Setup logging
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

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DIDRegistrationRequest(BaseModel):
    address: str
    private_key: Optional[str] = None
    user_info: Optional[Dict[str, Any]] = None

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
        
        account_info = {
            "address": request.address,
            "private_key": request.private_key,
            "user_info_hash": user_info_hash
        }
        
        result = await register_did(account_info)
        
        # Add explorer links
        result["explorer_links"] = {
            "transaction": f"https://testnet.explorer.perawallet.app/tx/{result['transaction_id']}",
            "address": f"https://testnet.explorer.perawallet.app/address/{request.address}"
        }
        
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

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
