import pytest
from fastapi.testclient import TestClient
import sys
import os
from unittest.mock import patch, Mock

# Add backend directory to Python path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, backend_dir)

from main import app

@pytest.fixture
def test_client():
    return TestClient(app)

def test_health_check(test_client):
    response = test_client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "version": "1.0.0"}

def test_register_did(test_client, mock_did_document, test_keys):
    with patch('main.register_user') as mock_register:  # Changé ici
        mock_register.return_value = {
            "did": "did:algo:test123",
            "didDocument": mock_did_document,
            "address": test_keys["address"],
            "transaction_id": "test_tx_id",
            "passphrase": "test passphrase"
        }
        
        test_data = {
            "address": test_keys["address"],
            "private_key": test_keys["private_key"],
            "mnemonic": None
        }
        response = test_client.post("/register", json=test_data)
        assert response.status_code == 200
        data = response.json()
        assert "did" in data
        assert data["did"] == "did:algo:test123"

def test_resolve_did(test_client, mock_did_document):
    with patch('main.resolve_did') as mock_resolve:
        mock_resolve.return_value = {
            "did": "did:algo:test123",
            "didDocument": mock_did_document,
            "metadata": {"recovered": True, "network": "testnet"}
        }
        
        response = test_client.get("/resolve/did:algo:test123")
        assert response.status_code == 200
        data = response.json()
        assert data["did"] == "did:algo:test123"

def test_update_did(test_client, mock_did_document):
    with patch('main.update_did') as mock_update:
        mock_update.return_value = {
            "status": "success",
            "did": "did:algo:test123",
            "updated_document": mock_did_document,
            "timestamp": 1635724800
        }
        
        test_data = {
            "did": "did:algo:test123",
            "new_key": "new_test_key",
            "new_service": "https://test.service"
        }
        response = test_client.put("/update", json=test_data)
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"

        
