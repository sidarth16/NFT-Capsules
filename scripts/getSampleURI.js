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
  const nftFactory = await ethers.getContractFactory("EncapsuleNFT721");


  const nft = await nftFactory.deploy();
  const weth = await wethFactory.deploy();
  const wbtc = await wbtcFactory.deploy();
  const wbnb = await wbnbFactory.deploy();

  console.log("Approving erc20 to contract");
  // Approve 1000 ETH to NFT Contract
  await weth.approve(nft.address, "10000000000000000000" )
  await wbtc.approve(nft.address, "10000000000000000000" )
  await wbnb.approve(nft.address, "10000000000000000000" )
  console.log("Approved erc20 to contract\n\n");

  // Token1
  tx = await nft.mint(
    deployer.address,
    [weth.address, wbtc.address], ["10000000000000000", "5000000000000000"]
  )
  await tx.wait()
  console.log("Minted NFT1");
  console.log("````````````````````````````````````````````")
  console.log(await nft.tokenURI(1))
  console.log("``````````````````````````````````````````````")

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
