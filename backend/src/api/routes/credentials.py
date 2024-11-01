from fastapi import APIRouter, HTTPException
from typing import Dict, Any
from ...credentials.management import issue_credential, verify_credential
from ...core.utils import logger
from ..models.credentials import CredentialRequest

router = APIRouter()

@router.post("/issue_credential")
async def create_credential(request: CredentialRequest):
    try:
        result = await issue_credential(
            category=request.category,
            subject=request.subject,
            issuer_name=request.issuer_name,
            issuer_did=request.issuer_did,
            period=request.period,
            destinator_did=request.destinator_did,
            metadata=request.metadata
        )
        return result
    except Exception as e:
        logger.error(f"Credential issuance failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/verify_credential/{credential_hash}")
async def verify_credential_endpoint(credential_hash: str):
    try:
        result = await verify_credential(credential_hash)
        return result
    except Exception as e:
        logger.error(f"Credential verification failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))