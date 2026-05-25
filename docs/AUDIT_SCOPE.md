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
- Is `governanceAdmin` a multisig-controlled timelock rather than a personal wallet?
- Can deployer privileges be safely revoked after setup?
- Are reserve-report events sufficient for off-chain audit publication?
- Is EIP-2612 permit behavior compatible with the intended wallet and custody flows?
- If upgradeability is introduced later, are proxy admin powers, upgrade delays, and implementation changes publicly documented?

## Out of Scope Unless Audited Separately

- Gold custody operations.
- Legal enforceability of redemption rights.
- Multisig signer security.
- Timelock operational procedures.
- Oracle, pricing, or proof-of-reserve integrations.
