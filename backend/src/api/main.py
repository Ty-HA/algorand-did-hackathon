from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from .routes import did, credentials

# Setup logging
logging.basicConfig(level=logging.DEBUG)
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

# Include routers with prefixes
app.include_router(did.router, prefix="", tags=["DID"])
app.include_router(credentials.router, prefix="", tags=["Credentials"])

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
