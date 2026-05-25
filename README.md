# Tokenized Asset

Solidity contracts for `GOLD-C`, an ERC20-style token intended to represent claims against allocated gold held off-chain.

## Contracts

- `contracts/GoldCToken.sol` - gold-backed token skeleton using Solidity `^0.8.24`, with custodian minting, approval-gated custodian burning, pause controls, delayed custodian changes, two-step ownership transfer, safer allowance helpers, and reserve report events.

## Notes

This code is only the on-chain component. A production gold token also needs custody agreements, redemption rules, audits, compliance controls, and legal review.

For production use, prefer audited OpenZeppelin contracts and an independent smart-contract audit before deployment.
