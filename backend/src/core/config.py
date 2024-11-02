# src/core/config.py

# Algorand TestNet Configuration
ALGOD_ADDRESS = "https://testnet-api.algonode.cloud"  # Using AlgoNode's free TestNet API
ALGOD_TOKEN = ""  # AlgoNode doesn't require a token
INDEXER_ADDRESS = "https://testnet-idx.algonode.cloud"
INDEXER_TOKEN = ""

# Explorer URL for transaction verification
EXPLORER_URL = "https://testnet.algoexplorer.io/tx/"

# Application Configuration
APP_ID = 728262235  # Will be set after deployment

# DID Configuration
DID_METHOD = "algo"
DID_PREFIX = f"did:{DID_METHOD}:"

# Logging Configuration
LOG_LEVEL = "DEBUG"

# Box Storage Configuration
MAX_BOX_SIZE = 32768  # 32KB
MAX_NAME_LENGTH = 64  # Maximum box name length in bytes
