# Tokenized Asset

Solidity contracts for `GOLD-C`, an ERC20 token intended to represent claims against allocated gold held off-chain.

## Contracts

- `contracts/GoldCToken.sol` - gold-backed token using Solidity `^0.8.24` and modern OpenZeppelin ERC20, ERC20Burnable, ERC20Pausable, AccessControl, and Ownable2Step imports.
- `contracts/GoldCGovernanceTimelock.sol` - OpenZeppelin TimelockController wrapper for delayed production governance.
- `docs/DEPLOYMENT_GOVERNANCE.md` - deployment checklist for multisig plus timelock control.
- `docs/LEGAL_RESERVE_FRAMEWORK.md` - reserve, custody, redemption, and compliance documentation template.
- `docs/AUDIT_SCOPE.md` - external audit scope checklist.

## Notes

This code is only the on-chain component. A production gold token also needs custody agreements, redemption rules, audits, compliance controls, and legal review.

For production use, obtain independent smart-contract, legal, custody, and operational audits before deployment.

## Production Readiness Checklist

- [x] Replace the self-contained ERC20 implementation with modern OpenZeppelin Contracts.
- [x] Add formal timelock governance contract based on OpenZeppelin TimelockController.
- [x] Document multisig deployment requirements for privileged roles.
- [x] Add legal reserve documentation template covering custody, redemption rights, audit cadence, reserve attestations, insolvency treatment, and compliance controls.
- [x] Add external audit scope template.
- [ ] Deploy with a real multisig as timelock proposer/admin operator.
- [ ] Publish completed legal reserve documentation signed off by counsel and custody providers.
- [ ] Obtain external smart-contract, operational, and legal audits before mainnet deployment.

## Development

Install dependencies and compile:

```sh
npm install
npm run compile
```
