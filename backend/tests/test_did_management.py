import pytest
from did_management import (
    create_did_from_address, 
    create_did_document, 
    register_did_with_document,
    get_algod_client
)
from unittest.mock import patch, Mock, MagicMock
from algosdk import transaction, encoding, constants
from algosdk.transaction import SignedTransaction
import json
import base64

def test_create_did_from_address(test_keys):
    did = create_did_from_address(test_keys["address"])
    assert did.startswith("did:algo:")
    assert len(did) > 10

def test_create_did_document(test_keys, mock_did_document):
    did = "did:algo:test123"
    doc = create_did_document(did, test_keys["address"])
    
    assert doc["@context"] == mock_did_document["@context"]
    assert doc["id"] == did
    assert "verificationMethod" in doc
    assert "authentication" in doc

@pytest.mark.asyncio
async def test_register_did_with_document(mock_algod_client, mock_did_document, test_keys):
    with patch('did_management.create_did_from_address') as mock_create_did, \
         patch('did_management.verify_existing_did') as mock_verify, \
         patch('did_management.create_did_document') as mock_create_doc:
        
        # Setup mocks
        mock_create_did.return_value = "did:algo:test123"
        mock_verify.return_value = {"has_did": False}
        mock_create_doc.return_value = mock_did_document

        # Create a proper mock for AlgodClient
        mock_algod_client.suggested_params.return_value = transaction.SuggestedParams(
            fee=1000,
            first=1,
            last=1000,
            gh=base64.b64decode("SGVsbG8gd29ybGQ="),  # "Hello world" in base64
            gen="testnet-v1.0",
            flat_fee=True,
            min_fee=1000
        )

        # Mock the transaction sending process
        def mock_send_transaction(signed_txn):
            return "mock_transaction_id"
        
        mock_algod_client.send_transaction = mock_send_transaction

        # Mock transaction confirmation
        mock_algod_client.pending_transaction_info.return_value = {
            "confirmed-round": 1000,
            "pool-error": "",
            "txn": {"txn": {}}
        }

        # Create a mock for the PaymentTxn
        class MockPaymentTxn(transaction.PaymentTxn):
            def sign(self, private_key):
                mock_signed = MagicMock()
                mock_signed.dictify.return_value = {
                    "sig": base64.b64decode("MockSignature123"),
                    "txn": {
                        "amt": 0,
                        "fee": 1000,
                        "fv": 1,
                        "gh": base64.b64decode("SGVsbG8gd29ybGQ="),
                        "lv": 1000,
                        "note": self.note,
                        "snd": encoding.decode_address(self.sender),
                        "type": "pay",
                        "gen": "testnet-v1.0",
                        "grp": None,
                        "lx": None,
                        "rcv": encoding.decode_address(self.receiver)
                    }
                }
                return mock_signed

        # Patch the PaymentTxn class
        with patch('did_management.transaction.PaymentTxn', MockPaymentTxn):
            # Execute the function
            result = await register_did_with_document(
                address=test_keys["address"],
                private_key=test_keys["private_key"]
            )
            
            # Verify results
            assert result["did"] == "did:algo:test123"
            assert "didDocument" in result
            assert result["didDocument"] == mock_did_document
            
            # Verify that the transaction was sent
            assert "transaction_id" in result
            assert "confirmation_round" in result
            assert result["confirmation_round"] == 1000
