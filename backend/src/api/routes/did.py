from fastapi import APIRouter, HTTPException
from typing import Dict, Any
from ...did.management import register_did, resolve_did
from ...core.utils import logger
from ..models.did import DIDRegistrationRequest
import hashlib
import json

router = APIRouter()

def generate_user_info_hash(user_info: Dict[str, Any]) -> str:
    """Generate a SHA-256 hash from user information"""
    info_string = json.dumps(user_info, sort_keys=True)
    return hashlib.sha256(info_string.encode()).hexdigest()

@router.post("/register")
async def register_did_endpoint(request: DIDRegistrationRequest):
    try:
        # Generate user info hash
        user_info_hash = generate_user_info_hash(request.user_info) if request.user_info else None
        
        account_info = {
            "address": request.address,
            "private_key": request.private_key,
            "user_info_hash": user_info_hash
        }
        
        result = await register_did(account_info)
        return result
    except Exception as e:
        logger.error(f"Registration failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/resolve/{did}")
async def resolve_did_endpoint(did: str):
    try:
        result = await resolve_did(did)
        return result
    except Exception as e:
        logger.error(f"DID resolution failed: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e)) 