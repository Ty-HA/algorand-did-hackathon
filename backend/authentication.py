# authentication.py

import requests
import config

def retrieve_did(did):
    resolver_url = f"http://localhost:8080/1.0/identifiers/{did}"
    response = requests.get(resolver_url)
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception("DID not found or failed to retrieve")

def authenticate_user(did, address):
    did_document = retrieve_did(did)
    controller = did_document.get("controller")

    return controller == address
