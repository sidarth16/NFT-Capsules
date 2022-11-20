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
  const weth = await wethFactory.deploy();
  console.log("Waiting for tx Confirmation");
  await weth.deployTransaction.wait(6);

  console.log("Deployed Weth at : ",weth.address);

  console.log("Verifying WETH : ")
  await hre.run("verify:verify", {
    address: "0x066e2511fe43332A729b5d977dfCCe4F0C493FcD",
    contract: "contracts/WETH.sol:WETH",
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
