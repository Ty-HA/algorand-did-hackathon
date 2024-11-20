import logging
from algosdk import account, mnemonic
from algosdk.v2client import algod, indexer
from algosdk import transaction
import base64
import json
from ..core.config import ALGOD_ADDRESS, ALGOD_TOKEN, INDEXER_ADDRESS, INDEXER_TOKEN, APP_ID, DID_PREFIX
from ..core.utils import logger

def get_algod_client() -> algod.AlgodClient:
    return algod.AlgodClient(ALGOD_TOKEN, ALGOD_ADDRESS)

def get_indexer_client() -> indexer.IndexerClient:
    return indexer.IndexerClient(INDEXER_TOKEN, INDEXER_ADDRESS)

async def create_testnet_account() -> dict:
    private_key, address = account.generate_account()
    passphrase = mnemonic.from_private_key(private_key)
    return {"address": address, "private_key": private_key, "passphrase": passphrase}

def get_deployer_account() -> dict:
    try:
        with open("logs/deployments/contract_deployment.json", "r") as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Failed to load deployer account: {e}")
        raise

async def register_did(account_info: dict) -> dict:
    try:
        client = get_algod_client()
        params = client.suggested_params()
        params.first = params.first
        params.last = params.first + 4
        deployer = get_deployer_account()
        did = f"{DID_PREFIX}{account_info['address']}"
        did_document = {
            "@context": ["https://www.w3.org/ns/did/v1"],
            "id": did,
            "verificationMethod": [{"id": f"{did}#key-1", "type": "Ed25519VerificationKey2018", "controller": did, "publicKeyBase58": account_info["address"]}],
            "authentication": [f"{did}#key-1"],
            "userInfoHash": account_info.get("user_info_hash")
        }
        note = json.dumps({"type": "DID_REGISTRATION", "did": did, "didDocument": did_document}).encode()
        txn = transaction.ApplicationCallTxn(sender=deployer["address"], sp=params, index=APP_ID, on_complete=transaction.OnComplete.NoOpOC, app_args=[b"register"], accounts=[account_info["address"]], note=note)
        signed_txn = txn.sign(deployer["private_key"])
        tx_id = client.send_transaction(signed_txn)
        logger.info(f"Transaction {tx_id} sent")
        confirmed_txn = await wait_for_confirmation(client, tx_id, 15)
        return {"status": "success", "did": did, "didDocument": did_document, "transaction_id": tx_id, "confirmed_round": confirmed_txn["confirmed-round"], "paid_by": deployer["address"]}
    except Exception as e:
        logger.error(f"Failed to register DID: {e}")
        raise Exception(f"Failed to register DID: {e}")

async def resolve_did(did: str) -> dict:
    try:
        indexer = get_indexer_client()
        address = did.replace(DID_PREFIX, "")
        response = indexer.search_transactions(address=address, note_prefix=b"DID_REGISTRATION", application_id=APP_ID)
        if not response.get("transactions"):
            raise Exception("DID not found")
        latest_tx = max(response["transactions"], key=lambda x: x["confirmed-round"])
        note = base64.b64decode(latest_tx["note"]).decode()
        did_data = json.loads(note)
        return {"did": did, "didDocument": did_data["didDocument"], "metadata": {"chain": "algorand-testnet", "recovered": True}}
    except Exception as e:
        raise Exception(f"Failed to resolve DID: {e}")

async def wait_for_confirmation(client: algod.AlgodClient, txid: str, timeout: int = 10) -> dict:
    try:
        start_round = client.status()["last-round"] + 1
        current_round = start_round
        while current_round < start_round + timeout:
            try:
                pending_txn = client.pending_transaction_info(txid)
                if pending_txn.get("confirmed-round", 0) > 0:
                    logger.info(f"Transaction {txid} confirmed in round {pending_txn['confirmed-round']}")
                    return pending_txn
                elif pending_txn.get("pool-error"):
                    raise Exception(f"Transaction pool error: {pending_txn['pool-error']}")
                logger.debug(f"Waiting for confirmation... (Round {current_round})")
                await asyncio.sleep(2)
                current_round += 1
            except Exception as e:
                logger.error(f"Error checking transaction status: {e}")
                raise
        raise Exception(f'Transaction {txid} not confirmed after {timeout} rounds')
    except Exception as e:
        logger.error(f"Error in wait_for_confirmation: {e}")
        raise