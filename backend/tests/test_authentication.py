import pytest
from authentication import verify_signature, generate_auth_token

def test_verify_signature():
    result = verify_signature("test_message", "test_signature", "test_public_key")
    assert isinstance(result, bool)

def test_generate_auth_token():
    did = "did:algo:test123"
    token = generate_auth_token(did)
    assert token.startswith("token_")
    assert did in token

