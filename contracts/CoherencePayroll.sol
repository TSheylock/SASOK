// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TFHE} from "fhevm/lib/TFHE.sol";
import {SepoliaConfig} from "fhevm/config/ZamaFHEVMConfig.sol";
import {SepoliaZamaGateway} from "fhevm/gateway/config/GatewayConfig.sol";
import {GatewayContractConfig} from "fhevm/gateway/GatewayContractConfig.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CoherencePayroll
 * @author Teymur Safiulov / Evorin LLC (SASOK Project)
 * @notice Confidential on-chain payroll system using Zama FHE Protocol
 * @dev Salaries and bonuses are fully encrypted via TFHE homomorphic operations.
 *      Only the employer and the respective employee can decrypt their own salary.
 */
contract CoherencePayroll is SepoliaConfig, GatewayContractConfig, Ownable {

    // ─── Structs ───────────────────────────────────────────────────────────

    struct Employee {
        euint64 encryptedSalary;   // Base salary (encrypted)
        euint8  encryptedBonus;    // Bonus factor 0-100% (encrypted)
        bool    active;
    }

    // ─── State ─────────────────────────────────────────────────────────────

    mapping(address => Employee) private employees;
    address[] public employeeList;

    /// @notice ERC-7984 confidential token used for payroll transfers
    address public payrollToken;

    // ─── Events ────────────────────────────────────────────────────────────

    event EmployeeRegistered(address indexed worker);
    event EmployeeDeactivated(address indexed worker);
    event PayrollExecuted(uint256 timestamp, uint256 count);

    // ─── Constructor ───────────────────────────────────────────────────────

    constructor(address _payrollToken) Ownable(msg.sender) {
        payrollToken = _payrollToken;
    }

    // ─── Employer Functions ────────────────────────────────────────────────

    /**
     * @notice Register a new employee with encrypted salary and bonus factor
     * @param worker       Employee wallet address
     * @param salaryCipher Encrypted salary ciphertext
     * @param bonusCipher  Encrypted bonus factor (0-100) ciphertext
     * @param inputProof   ZK input proof from fhevm-js
     */
    function addEmployee(
        address worker,
        bytes calldata salaryCipher,
        bytes calldata bonusCipher,
        bytes calldata inputProof
    ) external onlyOwner {
        require(worker != address(0), "Invalid address");
        require(!employees[worker].active, "Already registered");

        euint64 salary = TFHE.asEuint64(salaryCipher, inputProof);
        euint8  bonus  = TFHE.asEuint8(bonusCipher, inputProof);

        employees[worker] = Employee({
            encryptedSalary: salary,
            encryptedBonus:  bonus,
            active:          true
        });
        employeeList.push(worker);

        // Grant view permissions: employee sees own salary, employer sees all
        TFHE.allow(salary, worker);
        TFHE.allow(salary, owner());
        TFHE.allow(bonus,  owner());

        emit EmployeeRegistered(worker);
    }

    /**
     * @notice Execute payroll for all active employees.
     *         Total payout = salary + (salary * bonus / 100)
     *         All arithmetic is performed homomorphically — values stay encrypted.
     */
    function executePayroll() external onlyOwner {
        uint256 count = 0;
        for (uint256 i = 0; i < employeeList.length; i++) {
            address emp = employeeList[i];
            if (!employees[emp].active) continue;

            Employee storage e = employees[emp];

            // Bonus amount = salary * bonusFactor / 100
            euint64 bonusMult   = TFHE.asEuint64(e.encryptedBonus);
            euint64 bonusAmount = TFHE.div(
                TFHE.mul(e.encryptedSalary, bonusMult),
                100
            );
            euint64 totalPayout = TFHE.add(e.encryptedSalary, bonusAmount);

            // ERC-7984 confidential transfer
            (bool ok,) = payrollToken.call(
                abi.encodeWithSignature(
                    "confidentialTransfer(address,bytes32)",
                    emp,
                    TFHE.toBytes32(totalPayout)
                )
            );
            require(ok, "Transfer failed");
            count++;
        }
        emit PayrollExecuted(block.timestamp, count);
    }

    /**
     * @notice Deactivate an employee (stops future payroll)
     */
    function deactivateEmployee(address worker) external onlyOwner {
        require(employees[worker].active, "Not active");
        employees[worker].active = false;
        emit EmployeeDeactivated(worker);
    }

    // ─── Employee View Functions ────────────────────────────────────────────

    /**
     * @notice Returns the encrypted salary handle for the caller.
     *         Decrypt off-chain using Zama Gateway + fhevm-js.
     */
    function getMySalary() external view returns (euint64) {
        require(
            msg.sender == owner() || employees[msg.sender].active,
            "Unauthorized"
        );
        return employees[msg.sender].encryptedSalary;
    }

    /**
     * @notice Returns employee count
     */
    function employeeCount() external view returns (uint256) {
        return employeeList.length;
    }

    /**
     * @notice Check if an address is an active employee
     */
    function isActive(address worker) external view returns (bool) {
        return employees[worker].active;
    }
}
