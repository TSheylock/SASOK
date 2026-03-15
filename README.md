# Coherence Finance (CoFi)

> **Confidential On-Chain Payroll** — a Privacy-Module powered by Zama FHE Protocol

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue)](contracts/CoherencePayroll.sol)
[![Network](https://img.shields.io/badge/Network-Sepolia-purple)]()

---

## Overview

Coherence Finance (CoFi) is a **plug-and-play FHE (Fully Homomorphic Encryption) Privacy-Module** that brings confidential computations to on-chain payroll systems.

### The Problem
Current financial dApps are fully transparent. Salaries, bonus structures, and payroll logic are visible to everyone on-chain — making enterprise adoption impossible.

### The Solution
CoFi encrypts every financial operation using **Zama's TFHE library**. The business logic remains verifiable by the protocol but completely opaque to external observers.

---

## Features

| Feature | Description |
|---|---|
| **Encrypted Salaries** | Only employer + respective employee can view their own salary |
| **Encrypted Bonus Logic** | Bonus factors (0-100%) computed homomorphically on-chain |
| **ERC-7984 Ready** | Compatible with Zama confidential token standard |
| **ACL Permissions** | Fine-grained TFHE access control per employee |
| **Audit-Ready** | Role-based access for compliance without data leakage |
| **Employee Portal** | Workers decrypt their own salary via Zama Gateway + fhevm-js |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   CoFi Architecture                  │
├─────────────────────────────────────────────────────┤
│  Layer 1: Ethereum / Sepolia  ──  Security Layer     │
│  Layer 2: FHE Module (TFHE)   ──  Confidential Comp  │
│  Interface: fhevm-js + Next.js ── Employer/Employee  │
└─────────────────────────────────────────────────────┘
```

**Encryption flow:**
1. Employer encrypts salary client-side via `fhevm-js`
2. Encrypted ciphertext + ZK input proof sent to contract
3. `TFHE.asEuint64()` verifies and stores encrypted value on-chain
4. `executePayroll()` computes `total = salary + (salary * bonus / 100)` homomorphically
5. Employee calls `getMySalary()` → Zama Gateway re-encrypts for their key

---

## Smart Contract

**`contracts/CoherencePayroll.sol`**

```solidity
// Key functions:
function addEmployee(address worker, bytes calldata salaryCipher, 
    bytes calldata bonusCipher, bytes calldata inputProof) external onlyOwner;

function executePayroll() external onlyOwner;

function getMySalary() external view returns (euint64);

function deactivateEmployee(address worker) external onlyOwner;
```

### Key FHE Operations
- `TFHE.asEuint64()` — encrypt salary input with ZK proof
- `TFHE.mul() / TFHE.div() / TFHE.add()` — homomorphic bonus calculation
- `TFHE.allow()` — grant per-employee decryption permissions

---

## Tech Stack

- **Solidity** `^0.8.24` + `fhevm` (Zama TFHE library)
- **Hardhat** + `fhevm-hardhat-template`
- **Next.js 15** + Tailwind CSS (Frontend)
- **wagmi** + **fhevm-js** (Client-side encryption)
- **Network:** Sepolia testnet

---

## Project Structure

```
SASOK/
├── contracts/
│   └── CoherencePayroll.sol   # Main FHE payroll contract
├── frontend/
│   └── index.html             # Employer + Employee UI
├── hardhat.config.js          # Hardhat + Sepolia config
└── README.md
```

---

## Setup & Deployment

```bash
# 1. Clone and install
git clone https://github.com/TSheylock/SASOK
cd SASOK
npm install

# 2. Configure environment
cp .env.example .env
# Set SEPOLIA_RPC_URL and PRIVATE_KEY

# 3. Compile
npx hardhat compile

# 4. Deploy to Sepolia
npx hardhat deploy --network sepolia
```

---

## Author

**Teymur Safiulov** — Evorin LLC / SASOK AI Project  
Baku, Azerbaijan  
GitHub: [@TSheylock](https://github.com/TSheylock)

---

## License

MIT — see [LICENSE](LICENSE)
