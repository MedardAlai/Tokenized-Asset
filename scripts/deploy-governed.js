const hre = require("hardhat");

const DEFAULT_MIN_DELAY_SECONDS = 48 * 60 * 60;

function requireAddress(name) {
  const value = process.env[name];

  if (!value || !hre.ethers.isAddress(value)) {
    throw new Error(`${name} must be set to a valid address`);
  }

  return value;
}

function parseMinDelay() {
  const value = process.env.TIMELOCK_MIN_DELAY_SECONDS;

  if (!value) {
    return DEFAULT_MIN_DELAY_SECONDS;
  }

  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error("TIMELOCK_MIN_DELAY_SECONDS must be a positive integer");
  }

  return parsed;
}

async function main() {
  const multisigAddress = requireAddress("MULTISIG_ADDRESS");
  const minDelay = parseMinDelay();
  const [deployer] = await hre.ethers.getSigners();

  console.log(`Deploying with temporary deployer: ${deployer.address}`);
  console.log(`Governance multisig proposer: ${multisigAddress}`);
  console.log(`Timelock minimum delay: ${minDelay} seconds`);

  const Timelock = await hre.ethers.getContractFactory("GoldCGovernanceTimelock");
  const timelock = await Timelock.deploy(
    minDelay,
    [multisigAddress],
    [multisigAddress],
    deployer.address
  );
  await timelock.waitForDeployment();

  const timelockAddress = await timelock.getAddress();
  console.log(`GoldCGovernanceTimelock deployed: ${timelockAddress}`);

  const Token = await hre.ethers.getContractFactory("GoldCToken");
  const token = await Token.deploy(timelockAddress);
  await token.waitForDeployment();

  console.log(`GoldCToken deployed: ${await token.getAddress()}`);
  console.log("Next: configure any additional roles through the timelock, then renounce temporary timelock admin powers.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
