from fastapi.testclient import TestClient
from unittest.mock import patch
import pytest
from main import app
from did_management import register_did, resolve_did
from authentication import authenticate_user
from data_display import display_user_data

client = TestClient(app)

@pytest.mark.asyncio
async def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "version": "1.0.0"}

@pytest.mark.asyncio
async def test_register():
    mock_response = {
        "status": "success",
        "did": "did:algo:test123",
        "address": "TEST123456789",
        "passphrase": "test word1 word2 word3",
        "transaction_id": "TEST_TX_ID"
    }
    
    with patch('main.register_user') as mock_register:  # Changé ici
        mock_register.return_value = mock_response
        response = client.post(
            "/register",
            json={"address": "TEST123456789"}  # Ajouté une adresse valide
        )
        assert response.status_code == 200
        assert "did" in response.json()
        assert "address" in response.json()

@pytest.mark.asyncio
async def test_resolve_did():
    mock_did_doc = {
        "did": "did:algo:test123",
        "didDocument": {
            "@context": ["https://www.w3.org/ns/did/v1"],
            "id": "did:algo:test123",
            "verificationMethod": [{
                "id": "did:algo:test123#key-1",
                "type": "Ed25519VerificationKey2018",
                "controller": "did:algo:test123",
                "publicKeyBase58": "TEST123456789"
            }]
        }
    }
    
    with patch('main.resolve_did') as mock_resolve:  # Changé ici
        mock_resolve.return_value = mock_did_doc
        response = client.get("/resolve/did:algo:test123")
        assert response.status_code == 200
        assert "didDocument" in response.json()

@pytest.mark.asyncio
async def test_verify_did():
    mock_verification = {
        "status": "success",
        "transaction_id": "TEST_TX_ID",
        "verified": True
    }
    
    with patch('main.get_algod_client'):
        response = client.get("/verify-did/TEST_TX_ID")
        assert response.status_code == 200
        assert "verified" in response.json()

@pytest.mark.asyncio
async def test_register_error():
    with patch('did_management.register_did') as mock_register:
        mock_register.side_effect = Exception("Registration failed")
        response = client.post(
            "/register",
            json={"address": "", "private_key": None, "mnemonic": None}
        )
        assert response.status_code == 400
        assert "detail" in response.json()

def test_bad_did_format():
    response = client.get("/resolve/invalid_did_format")
    assert response.status_code == 404