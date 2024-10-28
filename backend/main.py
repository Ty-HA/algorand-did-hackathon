from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from registration import register_user
from typing import Optional
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = FastAPI()

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class RegistrationResponse(BaseModel):
    did: str
    address: str
    passphrase: str

@app.post("/register", response_model=RegistrationResponse)
async def register():
    """
    Enregistre un nouvel utilisateur et génère son DID.
    """
    try:
        result = register_user()
        logger.info(f"Registration successful. DID: {result['did']}")
        return result
    except Exception as e:
        logger.error(f"Registration failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))