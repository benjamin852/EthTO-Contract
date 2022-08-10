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

  const erc20s = ["0x0000000000000000000000000000000000000000","0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa","0x7d66CDe53cc0A169cAE32712fC48934e610aeF14","0x01BE23585060835E02B77ef475b0Cc51aA1e0709"];
  const tokenNames = ["Eth","Dai","USDC","LINK"];
  const tokenColors = ["#bba3db","#d8dba3","#a3dbc5","#a3d0db"];
  const aggregators = ["0x8A753747A1Fa494EC906cE90E9f37563A8AF630e","0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF","0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB","0xd8bD0a1cB028a31AA859A21A3758685a95dE4623"];
    
  const TokenRenderer = await ethers.getContractFactory("TokenRenderer");
  const tokenrenderer = await upgrades.deployProxy(TokenRenderer, [erc20s,tokenNames,tokenColors,aggregators]);
  await tokenrenderer.deployed();

  // console.log(
  //   "TokenRenderer address:",
  //   tokenrenderer.address
  // );

  const beneficiary = deployer.address;
  const vestingDate = 1691650712; 

  const SoulFund = await ethers.getContractFactory("SoulFund");
  
  // For upgradeable version
  const soulfund = await upgrades.deployProxy(SoulFund, [beneficiary, vestingDate, "0x3362Ac3528a3F39542b94E42e999699bbCaeC2DD"]);
  await soulfund.deployed();

  console.log(
    "SoulFund address:",
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
