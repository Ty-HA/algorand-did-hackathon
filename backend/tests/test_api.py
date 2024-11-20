import base64
import json
from fastapi.testclient import TestClient
from unittest.mock import patch
from src.api.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_register_did():
    with patch('src.did.management.get_deployer_account') as mock_deployer, \
         patch('src.did.management.register_did') as mock_register, \
         patch('src.did.management.create_testnet_account') as mock_account:
        mock_deployer.return_value = {"address": "BUXKT6AQKPZLNOVODY4JQ3QADOTCLLP6YXDU34VACXHXVEBN4NYMALUSOE", "private_key": "test_private_key"}
        mock_account.return_value = {"address": "TEST_ADDRESS", "private_key": "TEST_PRIVATE_KEY"}
        mock_register.return_value = {"status": "success", "did": "did:algo:test", "didDocument": {}, "transaction_id": "test_tx"}
        response = client.post("/register", json={"address": "", "user_info": {"name": "Test User"}})
        assert response.status_code == 200

def test_issue_credential():
    with patch('src.credentials.management.issue_credential') as mock_issue, \
         patch('src.credentials.management.get_indexer_client') as mock_indexer:
        mock_issue.return_value = {"status": "success", "credential_hash": "test_hash", "transaction_id": "test_tx"}
        mock_indexer.return_value.search_transactions.return_value = {"transactions": [{"confirmed-round": 1000, "note": base64.b64encode(json.dumps({"type": "CREDENTIAL", "credential": {}}).encode())}]}
        response = client.post("/issue_credential", json={"category": "Education", "subject": "Test Subject", "issuer_name": "Test Issuer", "issuer_did": "did:algo:issuer", "period": {"start": "2024-01-01", "end": "2024-12-31"}, "destinator_did": "did:algo:recipient", "metadata": {"grade": "A"}})
        assert response.status_code == 200

def test_verify_credential():
    with patch('src.credentials.management.get_indexer_client') as mock_indexer, \
         patch('src.credentials.management.verify_credential') as mock_verify:
        mock_indexer.return_value.search_transactions.return_value = {"transactions": [{"confirmed-round": 1000, "note": base64.b64encode(json.dumps({"type": "CREDENTIAL", "credential": {}}).encode())}]}
        mock_verify.return_value = {"status": "valid", "credential": {}, "metadata": {}}
        response = client.get("/verify_credential/test_hash")
        assert response.status_code == 200