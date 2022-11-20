// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  
  const [deployer] = await ethers.getSigners();
  console.log("deployer : ", deployer.address);

  const wethFactory = await ethers.getContractFactory("WETH");
  const wbtcFactory = await ethers.getContractFactory("WBTC");
  const wbnbFactory = await ethers.getContractFactory("WBNB");

  const weth = await wethFactory.deploy();
  await weth.deployTransaction.wait(6);
  console.log("Deployed Weth at : ",weth.address);
  console.log("Verifying WETH : ")
  await hre.run("verify:verify", {
    address: weth.address,
    constructorArguments: [],
    contract: "contracts/WETH.sol:WETH"
  });


  const wbtc = await wbtcFactory.deploy();
  await wbtc.deployTransaction.wait(6);
  console.log("Deployed WBTC at : ",wbtc.address);
  console.log("Verifying WBTC : ")
  await hre.run("verify:verify", {
    address: wbtc.address,
    contract: "contracts/WBTC.sol:WBTC",
    constructorArguments: [],
  });


  const wbnb = await wbnbFactory.deploy();
  await wbnb.deployTransaction.wait(6);
  console.log("Deployed WBNB at : ",wbnb.address);
  console.log("Verifying NFT : ")
  await hre.run("verify:verify", {
    address: wbnb.address,
    contract: "contracts/WBNB.sol:WBNB",
    constructorArguments: [],
  });

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
