// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/**
 * @title GOLD-C
 * @dev ERC20 token representing claims against allocated gold held off-chain.
 *
 * Deploy production ownership and role admin behind a TimelockController whose
 * proposer is a multisig. This contract only covers on-chain token mechanics;
 * custody, audits, redemption rights, and compliance remain off-chain controls.
 */
contract GoldCToken is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, Ownable2Step {
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant RESERVE_REPORTER_ROLE = keccak256("RESERVE_REPORTER_ROLE");

    event Minted(address indexed custodian, address indexed to, uint256 value, string reference);
    event Burned(address indexed from, uint256 value, string reference);
    event ReserveReportPublished(bytes32 indexed reportHash, string uri);

    constructor(address governanceAdmin) ERC20("Gold-C", "GOLD-C") Ownable(governanceAdmin) {
        require(governanceAdmin != address(0), "Invalid governance admin");

        _grantRole(DEFAULT_ADMIN_ROLE, governanceAdmin);
        _grantRole(CUSTODIAN_ROLE, governanceAdmin);
        _grantRole(PAUSER_ROLE, governanceAdmin);
        _grantRole(RESERVE_REPORTER_ROLE, governanceAdmin);
    }

    /**
     * @dev Mints GOLD-C after verified gold has been deposited with the issuer/custodian.
     * @param to Receiver of the newly issued tokens.
     * @param value Token amount, using 18 decimals.
     * @param reference Off-chain custody/deposit reference.
     */
    function mint(address to, uint256 value, string calldata reference)
        external
        onlyRole(CUSTODIAN_ROLE)
        whenNotPaused
        returns (bool)
    {
        require(to != address(0), "Cannot mint to zero address");

        _mint(to, value);

        emit Minted(msg.sender, to, value, reference);
        return true;
    }

    /**
     * @dev Burns caller tokens during redemption or cancellation.
     * @param value Token amount, using 18 decimals.
     * @param reference Off-chain redemption reference.
     */
    function burn(uint256 value, string calldata reference) public whenNotPaused returns (bool) {
        _burn(msg.sender, value);

        emit Burned(msg.sender, value, reference);
        return true;
    }

    /**
     * @dev Burns holder tokens for a completed redemption. The holder must approve
     * the custodian first, preventing custodians from burning arbitrary balances.
     */
    function custodianBurn(address from, uint256 value, string calldata reference)
        external
        onlyRole(CUSTODIAN_ROLE)
        whenNotPaused
        returns (bool)
    {
        _spendAllowance(from, msg.sender, value);
        _burn(from, value);

        emit Burned(from, value, reference);
        return true;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Publishes an immutable pointer to an off-chain reserve report.
     * `reportHash` can be keccak256 of the report contents, and `uri` can point
     * to an IPFS CID, HTTPS URL, or internal audit reference.
     */
    function publishReserveReport(bytes32 reportHash, string calldata uri)
        external
        onlyRole(RESERVE_REPORTER_ROLE)
    {
        require(reportHash != bytes32(0), "Invalid report hash");
        emit ReserveReportPublished(reportHash, uri);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
