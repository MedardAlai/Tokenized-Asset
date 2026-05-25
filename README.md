# Tokenized Asset

Solidity contracts for `GOLD-C`, an ERC20-style token intended to represent claims against allocated gold held off-chain.

## Contracts

- `contracts/GoldCToken.sol` - gold-backed token skeleton using Solidity `^0.8.24`, with custodian minting, approval-gated custodian burning, pause controls, delayed custodian changes, two-step ownership transfer, safer allowance helpers, and reserve report events.

## Notes

This code is only the on-chain component. A production gold token also needs custody agreements, redemption rules, audits, compliance controls, and legal review.

For production use, prefer audited OpenZeppelin contracts and an independent smart-contract audit before deployment.

## Production Readiness Checklist

- [ ] Replace the self-contained ERC20 implementation with modern OpenZeppelin Contracts, such as ERC20, Ownable or AccessControl, Pausable, and related extensions.
- [ ] Put privileged roles behind a multisig wallet, such as a Safe, instead of a single externally owned account.
- [ ] Route high-impact admin actions through a timelock. The current token includes a custodian-change delay, but production governance should use a dedicated timelock controller.
- [ ] Publish legal reserve documentation covering custody, redemption rights, audit cadence, reserve attestations, insolvency treatment, and compliance controls.
- [ ] Obtain external smart-contract, operational, and legal audits before mainnet deployment.
