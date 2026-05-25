# Audit Scope

## Smart Contracts

- `contracts/GoldCToken.sol`
- `contracts/GoldCGovernanceTimelock.sol`

## External Dependencies

- OpenZeppelin Contracts from `@openzeppelin/contracts`.
- Hardhat toolchain.

## Security Questions

- Are all privileged actions protected by the intended roles?
- Can custodians mint only under the expected role?
- Can custodians burn only with holder allowance and while unpaused?
- Does pausing prevent transfers, minting, and burning?
- Can role administration be fully transferred to the timelock?
- Can deployer privileges be safely revoked after setup?
- Are reserve-report events sufficient for off-chain audit publication?

## Out of Scope Unless Audited Separately

- Gold custody operations.
- Legal enforceability of redemption rights.
- Multisig signer security.
- Timelock operational procedures.
- Oracle, pricing, or proof-of-reserve integrations.
