"""
Service blockchain pour GabèsEye.

Mode hybride :
  - La source de vérité principale est PostgreSQL (fiable, sans frais de gas).
  - Les opérations on-chain sont tentées si BLOCKCHAIN_ENABLED=true et qu'un
    nœud Ethereum est disponible (Ganache local ou testnet).
  - En cas d'indisponibilité du nœud, le système continue sans erreur.

Workflow d'inscription :
  create_wallet()  →  (address, private_key)   # entièrement hors-ligne
  encrypt_private_key(pk)  →  str              # chiffrée en base de données
"""

import os
import base64
import hashlib
import logging
from typing import Optional

from eth_account import Account
from cryptography.fernet import Fernet

logger = logging.getLogger(__name__)

# ─── Configuration ────────────────────────────────────────────────────────────

BLOCKCHAIN_ENABLED = os.getenv("BLOCKCHAIN_ENABLED", "false").lower() == "true"
RPC_URL            = os.getenv("BLOCKCHAIN_RPC_URL", "http://localhost:8545")
CONTRACT_ADDRESS   = os.getenv("ECOTOKEN_CONTRACT_ADDRESS", "")
DEPLOYER_PK        = os.getenv("DEPLOYER_PRIVATE_KEY", "")
SECRET_KEY         = os.getenv("SECRET_KEY", "gabeseye_secret")

# ─── ABI du contrat EcoToken (compilé depuis contracts/EcoToken.sol) ─────────

ECOTOKEN_ABI = [
    {"inputs": [], "stateMutability": "nonpayable", "type": "constructor"},
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True,  "name": "to",     "type": "address"},
            {"indexed": False, "name": "amount", "type": "uint256"},
            {"indexed": False, "name": "reason", "type": "string"},
        ],
        "name": "TokensAwarded",
        "type": "event",
    },
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True,  "name": "from",   "type": "address"},
            {"indexed": False, "name": "amount", "type": "uint256"},
            {"indexed": False, "name": "reason", "type": "string"},
        ],
        "name": "TokensSpent",
        "type": "event",
    },
    {
        "inputs": [{"name": "validator", "type": "address"}],
        "name": "addValidator",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [
            {"name": "to",     "type": "address"},
            {"name": "amount", "type": "uint256"},
            {"name": "reason", "type": "string"},
        ],
        "name": "awardTokens",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [
            {"name": "from",   "type": "address"},
            {"name": "amount", "type": "uint256"},
            {"name": "reason", "type": "string"},
        ],
        "name": "spendTokens",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"name": "user", "type": "address"}],
        "name": "getBalance",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [],
        "name": "totalSupply",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
]

# ─── Chiffrement Fernet ───────────────────────────────────────────────────────

def _get_fernet() -> Fernet:
    """Dérive une clé Fernet à partir du SECRET_KEY applicatif."""
    raw = hashlib.sha256(SECRET_KEY.encode()).digest()
    key = base64.urlsafe_b64encode(raw)
    return Fernet(key)


def encrypt_private_key(private_key: str) -> str:
    """Chiffre la clé privée pour le stockage en base de données."""
    return _get_fernet().encrypt(private_key.encode()).decode()


def decrypt_private_key(encrypted: str) -> str:
    """Déchiffre la clé privée stockée."""
    return _get_fernet().decrypt(encrypted.encode()).decode()

# ─── Création de portefeuille (hors-ligne) ────────────────────────────────────

def create_wallet() -> tuple[str, str]:
    """
    Crée un nouveau portefeuille Ethereum sans connexion réseau.
    Retourne (adresse_publique, clé_privée_hex).
    """
    account = Account.create()
    return account.address, account.key.hex()

# ─── Opérations on-chain (optionnelles) ──────────────────────────────────────

def _get_web3_contract():
    """Retourne (w3, contract) ou lève RuntimeError si non disponible."""
    if not BLOCKCHAIN_ENABLED:
        raise RuntimeError("Blockchain disabled")
    if not CONTRACT_ADDRESS:
        raise RuntimeError("CONTRACT_ADDRESS not set")
    if not DEPLOYER_PK:
        raise RuntimeError("DEPLOYER_PRIVATE_KEY not set")

    from web3 import Web3
    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    if not w3.is_connected():
        raise RuntimeError(f"Cannot connect to {RPC_URL}")

    from web3 import Web3 as W3
    contract = w3.eth.contract(
        address=W3.to_checksum_address(CONTRACT_ADDRESS),
        abi=ECOTOKEN_ABI,
    )
    return w3, contract


def get_token_balance_onchain(wallet_address: str) -> Optional[int]:
    """Lit le solde depuis la blockchain. Retourne None si indisponible."""
    try:
        w3, contract = _get_web3_contract()
        from web3 import Web3
        return contract.functions.getBalance(
            Web3.to_checksum_address(wallet_address)
        ).call()
    except Exception as e:
        logger.debug("Blockchain balance unavailable: %s", e)
        return None


def award_tokens_onchain(
    to_address: str, amount: int, reason: str
) -> Optional[str]:
    """
    Crédite des tokens sur la blockchain.
    Retourne le hash de transaction ou None si échec.
    """
    try:
        w3, contract = _get_web3_contract()
        from web3 import Web3
        deployer = Account.from_key(DEPLOYER_PK)
        addr     = Web3.to_checksum_address(to_address)

        tx = contract.functions.awardTokens(addr, amount, reason).build_transaction(
            {
                "from":     deployer.address,
                "nonce":    w3.eth.get_transaction_count(deployer.address),
                "gas":      200_000,
                "gasPrice": w3.to_wei("1", "gwei"),
            }
        )
        signed   = w3.eth.account.sign_transaction(tx, DEPLOYER_PK)
        tx_hash  = w3.eth.send_raw_transaction(signed.raw_transaction)
        return tx_hash.hex()
    except Exception as e:
        logger.warning("award_tokens_onchain failed: %s", e)
        return None


def spend_tokens_onchain(
    from_address: str, amount: int, reason: str
) -> Optional[str]:
    """
    Débite des tokens sur la blockchain.
    Retourne le hash de transaction ou None si échec.
    """
    try:
        w3, contract = _get_web3_contract()
        from web3 import Web3
        deployer = Account.from_key(DEPLOYER_PK)
        addr     = Web3.to_checksum_address(from_address)

        tx = contract.functions.spendTokens(addr, amount, reason).build_transaction(
            {
                "from":     deployer.address,
                "nonce":    w3.eth.get_transaction_count(deployer.address),
                "gas":      200_000,
                "gasPrice": w3.to_wei("1", "gwei"),
            }
        )
        signed  = w3.eth.account.sign_transaction(tx, DEPLOYER_PK)
        tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
        return tx_hash.hex()
    except Exception as e:
        logger.warning("spend_tokens_onchain failed: %s", e)
        return None
