# Deployment and Governance

## Intended Production Control Flow

1. Deploy a multisig wallet, such as Safe, with the issuer's required signers and threshold.
2. Deploy `GoldCGovernanceTimelock` with:
   - `minDelay`: the public governance delay for admin actions.
   - `proposers`: the multisig address.
   - `executors`: the multisig, an operations executor, or `address(0)` for open execution.
   - `admin`: a temporary deployer used only during setup.
3. Deploy `GoldCToken` with `governanceAdmin` set to the timelock address. Do not use a personal wallet for this parameter in production.
4. Grant `DEFAULT_ADMIN_ROLE`, `CUSTODIAN_ROLE`, `PAUSER_ROLE`, and `RESERVE_REPORTER_ROLE` as required through the timelock.
5. Revoke temporary deployer roles and renounce temporary timelock admin powers after verification.

## Governance Requirements

- The token owner should be the timelock, not an individual wallet.
- Role administration should be controlled by the timelock.
- The timelock proposer should be a multisig.
- Minting should be limited to approved custodians or issuance operations addresses.
- Emergency pausing should be granted only to tightly controlled operational roles.

## Operational Notes

- Keep a public runbook for mint, redemption, pause, unpause, and reserve-report publication.
- Record transaction hashes for every role change, mint, burn, and reserve-report update.
- Before mainnet deployment, run a rehearsal on a testnet with the same signer threshold and delay.
