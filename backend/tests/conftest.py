import pytest
from fastapi.testclient import TestClient
import os
import sys
from unittest.mock import Mock, patch
from typing import Dict, Any
from algosdk import account

# Get the absolute path to the backend directory
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, backend_dir)

from main import app  # Import after adding backend_dir to sys.path

@pytest.fixture
def test_keys():
    # Generate a test account
    private_key, address = account.generate_account()
    return {
        "private_key": private_key,
        "address": address
    }

@pytest.fixture
def mock_algod_client():
    mock_client = Mock()
    
    # Mock search_transactions
    mock_client.search_transactions.return_value = []
    
    # Mock suggested_params
    mock_client.suggested_params.return_value = Mock(
        fee=1000,
        first=1,
        last=1000,
        gh="mock_genesis_hash"
    )
    
    # Mock transaction methods
    mock_client.send_transaction.return_value = "test_tx_id"
    mock_client.pending_transaction_info.return_value = {
        "confirmed-round": 1000,
        "pool-error": "",
        "txn": {"txn": {}}
    }
    
    return mock_client

@pytest.fixture
def mock_indexer_client():
    mock_client = Mock()
    mock_client.search_transactions.return_value = {"transactions": []}
    return mock_client

@pytest.fixture
def test_client(mock_algod_client, mock_indexer_client):
    # Patch all necessary dependencies
    with patch('did_management.get_algod_client', return_value=mock_algod_client), \
         patch('did_management.get_indexer_client', return_value=mock_indexer_client), \
         patch('did_management.verify_existing_did', return_value={"has_did": False}):
        yield TestClient(app)

@pytest.fixture
def test_did():
    return "did:algo:test123"

@pytest.fixture
def mock_did_document():
    return {
        "@context": [
            "https://www.w3.org/ns/did/v1",
            "https://w3id.org/security/suites/ed25519-2018/v1"
        ],
        "id": "did:algo:test123",
        "verificationMethod": [{
            "id": "did:algo:test123#key-1",
            "type": "Ed25519VerificationKey2018",
            "controller": "did:algo:test123",
            "publicKeyBase58": "TEST123456789"
        }],
        "authentication": ["did:algo:test123#key-1"],
        "assertionMethod": ["did:algo:test123#key-1"],
        "created": 1635724800
    }


