// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function loadContracts(){
  const nftContractAddress = "0x85f94190C4f2b3b2f9d0C73757bdB6A9Ee973320";
  const nftFactory = await ethers.getContractFactory("EncapsuleNFT721");
  const nft = nftFactory.attach(nftContractAddress)

  const wethContractAddress = "0x8597cfd36829de5C20E40696772987fbEbbc54E7";
  const wethFactory = await ethers.getContractFactory("WETH");
  const weth = wethFactory.attach(wethContractAddress)

  const wbnbContractAddress = "0xb7b3fec55d3f5133D5Eb85283bf161C10a271cbE";
  const wbnbFactory = await ethers.getContractFactory("WBNB");
  const wbnb = wbnbFactory.attach(wbnbContractAddress)

  const wbtcContractAddress = "0x92a5b2fadEA900020697bC16b76d94446968A7ea";
  const wbtcFactory = await ethers.getContractFactory("WBTC");
  const wbtc = wbtcFactory.attach(wbtcContractAddress)

  return [nft, weth, wbtc, wbnb]
}

async function main() {
  
  const [deployer] = await ethers.getSigners();
  console.log("deployer : ", deployer.address);

  let contracts = await loadContracts()
  nft = contracts[0]
  weth = contracts[1]
  wbtc = contracts[2]
  wbnb = contracts[3]

  // console.log(await nft.ownerOf(1))

  console.log("Approving erc20 to contract");
  // Approve 1000 ETH to NFT Contract
  await weth.approve(nft.address, "10000000000000000000" )
  await wbtc.approve(nft.address, "10000000000000000000" )
  await wbnb.approve(nft.address, "10000000000000000000" )
  console.log("Approved erc20 to contract\n\n");


  // Mint NFTs

  // Token1
  tx = await nft.mint(
    deployer.address, [weth.address], ["10000000000000000"]
  )
  await tx.wait()
  console.log("Minted NFT1");
  
  // Token2
  tx = await nft.mint(
    deployer.address, [wbtc.address], ["20000000000000000"]
  )
  await tx.wait()
  console.log("Minted NFT2");
  
  // Token3
  tx = await nft.mint(
    deployer.address, [wbnb.address, wbtc.address], ["30000000000000000", "20000000000000000"]
  )
  await tx.wait()
  console.log("Minted NFT3");

  // Token4
  tx = await nft.mint(
    deployer.address,
    [weth.address, wbnb.address, wbtc.address], ["10000000000000000", "20000000000000000", "30000000000000000"]
  )
  await tx.wait()  
  console.log("Minted NFT4\n\n");


  // // Add more tokens to tokenID: 1
  // tx = await nft.addERC20Tokens(1, [wbtc.address, wbnb.address], ["10000000000000000", "10000000000000000"])
  // await tx.wait()
  // console.log("Added ERC20 to NFT1\n");

  // // Swap tokenId: 2 and TokenId: 3
  // tx = await nft.swapErc20Tokens(2, 3)
  // await tx.wait()
  // console.log("Swapped NFT2 and NFT3 ERC20Tokens\n");

  // // Withdraw weth Token from tokenId: 4
  // tx = await nft.withdrawERC20Token(4, weth.address, deployer.address)
  // await tx.wait()
  // console.log("Withdrawn WETH ERC20Token from NFT4");

  // // Withdraw All Token from tokenId: 4
  // tx = await nft.withdrawAllERC20Tokens(4, deployer.address)
  // await tx.wait()
  // console.log("Withdrawn All ERC20Token from NFT4");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
