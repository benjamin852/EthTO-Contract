// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {

  const provider = ethers.provider;
  const deployer = new ethers.Wallet(process.env.AURORA_PRIVATE_KEY, provider);

  console.log(
    "Deployer account:",
    deployer.address
  );

  console.log(
    "Deployer balance:",
    (await deployer.getBalance()).toString()
  );
  
  const beneficiary = deployer.address;
  const vestingDate = 1660125581; 

  const SoulFund = await ethers.getContractFactory("SoulFund");
  
  // For upgradeable version
  const soulfund = await upgrades.deployProxy(SoulFund, [beneficiary, vestingDate]);
  await soulfund.deployed();

  console.log(
    "Deployed address:",
    soulfund.address
  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
