# data_display.py

from authentication import retrieve_did

def display_user_data(did):
    did_document = retrieve_did(did)
    verification_method = did_document.get("verificationMethod", [])
    authentication = did_document.get("authentication", [])

    return {
        "id": did_document.get("id"),
        "verificationMethod": verification_method,
        "authentication": authentication,
    }
