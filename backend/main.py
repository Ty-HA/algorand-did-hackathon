from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import logging
from registration import register_user
from authentication import authenticate_user
from data_display import display_user_data
from did_update import update_did

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifiez les domaines exacts
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AuthenticationRequest(BaseModel):
    did: str
    address: str

class UpdateRequest(BaseModel):
    did: str
    new_key: Optional[str] = None
    new_service: Optional[str] = None

@app.post("/register")
async def register():
    try:
        logger.info("Processing registration request")
        address, passphrase = register_user()
        logger.info(f"Registration successful for address: {address}")
        return {
            "address": address,
            "passphrase": passphrase
        }
    except Exception as e:
        logger.error(f"Registration failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/authenticate")
async def authenticate(request: AuthenticationRequest):
    try:
        logger.info(f"Processing authentication request for DID: {request.did}")
        if authenticate_user(request.did, request.address):
            return {"status": "Authenticated"}
        else:
            raise HTTPException(status_code=401, detail="Authentication failed")
    except Exception as e:
        logger.error(f"Authentication failed: {str(e)}")
        raise HTTPException(status_code=401, detail=str(e))

@app.get("/display/{did}")
async def display(did: str):
    try:
        logger.info(f"Fetching data for DID: {did}")
        data = display_user_data(did)
        return data
    except Exception as e:
        logger.error(f"Data display failed: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

@app.post("/update")
async def update(request: UpdateRequest):
    try:
        logger.info(f"Processing update request for DID: {request.did}")
        update_did(request.did, request.new_key, request.new_service)
        return {"status": "DID updated successfully"}
    except Exception as e:
        logger.error(f"Update failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

# Endpoint de test pour vérifier la connectivité
@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}

# Log des routes disponibles au démarrage
@app.on_event("startup")
async def startup_event():
    logger.info("Server starting up")
    logger.info("Available routes:")
    for route in app.routes:
        logger.info(f"{route.methods} {route.path}")