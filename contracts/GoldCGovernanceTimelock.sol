// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title GOLD CHAIN Governance Timelock
 * @dev Use this timelock as the owner and DEFAULT_ADMIN_ROLE holder for GoldCToken.
 *
 * Recommended production setup:
 * - proposers: one or more multisig addresses.
 * - executors: a multisig, dedicated executor, or address(0) for open execution.
 * - admin: temporary deployer only during setup, then renounced after roles are configured.
 */
contract GoldCGovernanceTimelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}
