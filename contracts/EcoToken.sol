// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EcoToken — Jeton de citoyenneté environnementale GabèsEye
/// @notice ERC-20 simplifié sans bibliothèque externe pour déploiement facile
contract EcoToken {
    string public name     = "EcoToken";
    string public symbol   = "ECT";
    uint8  public decimals = 0;   // Jetons entiers uniquement

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool)    public validators;

    // ─── Events ──────────────────────────────────────────────────────────────
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TokensAwarded(address indexed to,   uint256 amount, string reason);
    event TokensSpent  (address indexed from, uint256 amount, string reason);
    event ValidatorAdded(address indexed validator);

    // ─── Modifiers ───────────────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "EcoToken: not owner");
        _;
    }

    modifier onlyValidator() {
        require(validators[msg.sender] || msg.sender == owner, "EcoToken: not authorized");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────
    constructor() {
        owner = msg.sender;
        validators[msg.sender] = true;
    }

    // ─── Admin ───────────────────────────────────────────────────────────────
    function addValidator(address validator) external onlyOwner {
        validators[validator] = true;
        emit ValidatorAdded(validator);
    }

    function removeValidator(address validator) external onlyOwner {
        validators[validator] = false;
    }

    // ─── Token operations (appelées par le backend via le wallet déployeur) ──
    function awardTokens(
        address to,
        uint256 amount,
        string calldata reason
    ) external onlyValidator {
        require(to != address(0), "EcoToken: zero address");
        balanceOf[to] += amount;
        totalSupply    += amount;
        emit Transfer(address(0), to, amount);
        emit TokensAwarded(to, amount, reason);
    }

    function spendTokens(
        address from,
        uint256 amount,
        string calldata reason
    ) external onlyValidator {
        require(balanceOf[from] >= amount, "EcoToken: insufficient balance");
        balanceOf[from] -= amount;
        totalSupply     -= amount;
        emit Transfer(from, address(0), amount);
        emit TokensSpent(from, amount, reason);
    }

    // ─── User-initiated transfer ──────────────────────────────────────────────
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "EcoToken: insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to]         += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // ─── View ────────────────────────────────────────────────────────────────
    function getBalance(address user) external view returns (uint256) {
        return balanceOf[user];
    }
}
