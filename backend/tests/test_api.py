from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from src.api.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_register_did():
    with patch('src.did.management.register_did') as mock_register:
        mock_register.return_value = {
            "status": "success",
            "did": "did:algo:test",
            "didDocument": {},
            "transaction_id": "test_tx",
            "confirmed_round": 1,
            "paid_by": "test_address"
        }
        
        response = client.post(
            "/register",
            json={
                "address": "test_address",
                "user_info": {
                    "name": "Test User",
                    "email": "test@example.com"
                }
            }
        )
        
        assert response.status_code == 200
        assert "did" in response.json()
        assert "transaction_id" in response.json()

def test_issue_credential():
    with patch('src.credentials.management.issue_credential') as mock_issue:
        mock_issue.return_value = {
            "status": "success",
            "credential_hash": "test_hash",
            "transaction_id": "test_tx"
        }
        
        response = client.post(
            "/issue_credential",
            json={
                "category": "Education",
                "subject": "Test Subject",
                "issuer_name": "Test Issuer",
                "issuer_did": "did:algo:issuer",
                "period": {
                    "start": "2024-01-01",
                    "end": "2024-12-31"
                },
                "destinator_did": "did:algo:recipient",
                "metadata": {
                    "grade": "A"
                }
            }
        )
        
        assert response.status_code == 200
        assert "credential_hash" in response.json()
        assert "transaction_id" in response.json()

def test_verify_credential():
    with patch('src.credentials.management.verify_credential') as mock_verify:
        mock_verify.return_value = {
            "status": "valid",
            "credential": {},
            "metadata": {}
        }
        
        response = client.get("/verify_credential/test_hash")
        assert response.status_code == 200
        assert response.json()["status"] == "valid" 