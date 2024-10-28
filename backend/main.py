from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from registration import register_user, get_algod_client
from typing import Optional
import logging

# Configuration du logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="SerendID API",
    description="API for DID management with Algorand",
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

class RegistrationResponse(BaseModel):
    did: str
    address: str
    passphrase: str
    transaction_id: Optional[str] = None

class NetworkStatus(BaseModel):
    status: str
    network: str
    last_round: int
    version: list[str]

@app.post("/register", response_model=RegistrationResponse)
async def register():
    """
    Enregistre un nouvel utilisateur et génère son DID.
    """
    try:
        logger.info("Starting registration process")
        result = register_user()
        logger.info(f"Registration successful. DID: {result['did']}")
        return result
    except Exception as e:
        logger.error(f"Registration failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/network-status", response_model=NetworkStatus)
async def check_network_status():
    """
    Vérifie la connexion au réseau Algorand.
    """
    try:
        logger.info("Checking network status")
        client = get_algod_client()
        status = client.status()
        versions = client.versions()
        
        response = {
            "status": "connected",
            "network": "TestNet",
            "last_round": status['last-round'],
            "version": versions['versions']
        }
        logger.info(f"Network status: {response}")
        return response
    except Exception as e:
        logger.error(f"Network status check failed: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to connect to Algorand network: {str(e)}"
        )

@app.get("/health")
async def health_check():
    """
    Simple health check endpoint.
    """
    return {"status": "healthy", "version": "1.0.0"}