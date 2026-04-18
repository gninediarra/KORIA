"""
Deploy EcoToken.sol to a local Ganache instance (or any EVM-compatible chain).

Usage:
    python deploy_contract.py

Prerequisites:
    1. Ganache running:  npx ganache --port 8545
    2. pip install web3 py-solc-x
    3. .env configured (see .env.example)

After a successful deploy the script prints the contract address and the
deployer's private key — paste both into your .env file.
"""

import os
import json
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

try:
    from web3 import Web3
    from solcx import compile_source, install_solc
except ImportError:
    print("Missing deps — run:  pip install web3 py-solc-x")
    raise SystemExit(1)

RPC_URL      = os.getenv("BLOCKCHAIN_RPC_URL", "http://localhost:8545")
DEPLOYER_KEY = os.getenv("DEPLOYER_PRIVATE_KEY", "")

SOL_PATH = Path(__file__).parent / "contracts" / "EcoToken.sol"

def main() -> None:
    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    if not w3.is_connected():
        print(f"Cannot connect to {RPC_URL}. Is Ganache running?")
        raise SystemExit(1)

    print(f"Connected to {RPC_URL}  (chainId={w3.eth.chain_id})")

    # Use first Ganache account when no key is configured
    if DEPLOYER_KEY:
        account = w3.eth.account.from_key(DEPLOYER_KEY)
    else:
        account = w3.eth.account.from_key(w3.eth.accounts[0])  # Ganache auto-funded
        print(f"No DEPLOYER_PRIVATE_KEY set — using Ganache account[0]")

    print(f"Deployer: {account.address}")
    print(f"Balance : {w3.from_wei(w3.eth.get_balance(account.address), 'ether')} ETH")

    # Compile
    install_solc("0.8.20")
    source = SOL_PATH.read_text()
    compiled = compile_source(source, output_values=["abi", "bin"], solc_version="0.8.20")
    _, contract_interface = next(iter(compiled.items()))

    abi      = contract_interface["abi"]
    bytecode = contract_interface["bin"]

    # Deploy
    Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
    nonce    = w3.eth.get_transaction_count(account.address)
    tx       = Contract.constructor().build_transaction({
        "from":     account.address,
        "nonce":    nonce,
        "gas":      2_000_000,
        "gasPrice": w3.to_wei("10", "gwei"),
    })
    signed  = w3.eth.account.sign_transaction(tx, account.key)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=60)

    contract_address = receipt.contractAddress
    print(f"\nEcoToken deployed at: {contract_address}")
    print(f"Tx hash            : {tx_hash.hex()}")
    print(f"\nAdd to your .env:")
    print(f"  BLOCKCHAIN_ENABLED=true")
    print(f"  ECOTOKEN_CONTRACT_ADDRESS={contract_address}")
    if not DEPLOYER_KEY:
        print(f"  DEPLOYER_PRIVATE_KEY=<Ganache account[0] private key>")

    # Save ABI for reference
    abi_path = Path(__file__).parent / "contracts" / "EcoToken.abi.json"
    abi_path.write_text(json.dumps(abi, indent=2))
    print(f"\nABI saved to {abi_path}")


if __name__ == "__main__":
    main()
