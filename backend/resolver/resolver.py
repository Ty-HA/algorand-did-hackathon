# resolver.py

from fastapi import FastAPI, HTTPException
import requests
import config

app = FastAPI()

@app.get("/1.0/identifiers/{did}")
def get_did_document(did: str):
    try:
        # Replace with actual logic for retrieving DID document
        response = requests.get(f"http://algorand-node-api/resolve/{did}")
        return response.json()
    except Exception as e:
        raise HTTPException(status_code=500, detail="DID resolution failed.")
