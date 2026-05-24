# Tokenized Asset

Solidity contracts for `GOLD-C`, an ERC20-style token intended to represent claims against allocated gold held off-chain.

## Contracts

- `contracts/GoldCToken.sol` - gold-backed token skeleton with custodian minting, burning, pause controls, and reserve report events.
- `contracts/zeppelin/*.sol` - proxy contracts compatible with Solidity `0.4.24`.

## Notes

This code is only the on-chain component. A production gold token also needs custody agreements, redemption rules, audits, compliance controls, and legal review.
