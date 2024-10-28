from fastapi.testclient import TestClient
from main import app
from unittest.mock import patch

client = TestClient(app)

def test_register():
    with patch('main.register_user') as mock_register:
        mock_register.return_value = ("mock_address", "mock_passphrase")
        response = client.post("/register")
        assert response.status_code == 200
        assert "address" in response.json()
        assert "passphrase" in response.json()
    print("test_register passed")

def test_authenticate():
    with patch('main.authenticate_user') as mock_authenticate:
        mock_authenticate.return_value = False
        response = client.post("/authenticate", json={"did": "did:algo:123", "address": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"})
        assert response.status_code == 401
        assert response.json() == {"detail": "Authentication failed"}
    print("test_authenticate passed")

def test_display():
    with patch('main.display_user_data') as mock_display:
        mock_display.side_effect = Exception("DID not found")
        response = client.get("/display/did:algo:123")
        assert response.status_code == 404  # Assuming DID not found for this test case
    print("test_display passed")

def test_update():
    with patch('main.update_did') as mock_update:
        mock_update.side_effect = Exception("Update failed")
        response = client.post("/update", json={"did": "did:algo:123", "new_key": "newkey1"})
        assert response.status_code == 400
        assert response.json() == {"detail": "Update failed"}
    print("test_update passed")

def test_register_with_mock():
    with patch('main.register_user') as mock_register:
        mock_register.return_value = ("mock_address", "mock_passphrase")
        response = client.post("/register")
        assert response.status_code == 200
        assert response.json() == {"address": "mock_address", "passphrase": "mock_passphrase"}
    print("test_register_with_mock passed")

def test_user_registration_and_did_creation():
    with patch('main.register_user') as mock_register:
        # Mock the return value to simulate successful registration and DID creation
        mock_register.return_value = ("ALGO123456789", "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20 word21 word22 word23 word24 word25")
        
        response = client.post("/register")
        
        assert response.status_code == 200
        assert "address" in response.json()
        assert "passphrase" in response.json()
        
        # Check if the returned address matches the expected format
        assert response.json()["address"].startswith("ALGO")
        
        # Check if the returned passphrase is a 25-word mnemonic
        assert len(response.json()["passphrase"].split()) == 25
        
        print("test_user_registration_and_did_creation passed")
