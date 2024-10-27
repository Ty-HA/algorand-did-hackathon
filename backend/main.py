# main.py

from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from registration import register_user
from authentication import authenticate_user
from data_display import display_user_data
from did_update import update_did

app = FastAPI()

class AuthenticationRequest(BaseModel):
    did: str
    address: str

class UpdateRequest(BaseModel):
    did: str
    new_key: str = None
    new_service: str = None

@app.post("/register")
def register():
    try:
        address, passphrase = register_user()
        return {"address": address, "passphrase": passphrase}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/authenticate")
def authenticate(request: AuthenticationRequest):
    if authenticate_user(request.did, request.address):
        return {"status": "Authenticated"}
    else:
        raise HTTPException(status_code=401, detail="Authentication failed")

@app.get("/display/{did}")
def display(did: str):
    try:
        data = display_user_data(did)
        return data
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@app.post("/update")
def update(request: UpdateRequest):
    try:
        update_did(request.did, request.new_key, request.new_service)
        return {"status": "DID updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
