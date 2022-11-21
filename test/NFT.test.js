const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Test NFT Encapsulation", function () {

  
  async function deployFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, operator, user1, user2] = await ethers.getSigners();

    const wethFactory = await ethers.getContractFactory("WETH");
    const wbtcFactory = await ethers.getContractFactory("WBTC");
    const wbnbFactory = await ethers.getContractFactory("WBNB");
    const nftFactory = await ethers.getContractFactory("EncapsuleNFT721");


    const weth = await wethFactory.deploy();
    const wbtc = await wbtcFactory.deploy();
    const wbnb = await wbnbFactory.deploy();
    const nft = await nftFactory.deploy();
    
    // await weth.transfer(user1.address, 1000)
    // await weth.transfer(user2.address, 1000)
    await weth.transfer(operator.address, 1000)

    // await wbtc.transfer(user1.address, 1000)
    // await wbtc.transfer(user2.address, 1000)
    await wbtc.transfer(operator.address, 1000)

    // await wbnb.transfer(user1.address, 1000)
    // await wbnb.transfer(user2.address, 1000)
    await wbnb.transfer(operator.address, 1000)

    // console.log();
    // console.log("weth : ",weth.address)
    // console.log("wbtc : ",wbtc.address)
    // console.log("wbnb : ",wbnb.address)
    // console.log("nft : ",nft.address)

    return { weth, wbtc, wbnb, nft, owner, operator, user1, user2 };
  }

  describe("Deployment", function () {
    it("Should Deploy properly", async function () {
      const { weth, wbtc, wbnb, nft, owner, operator, user1, user2 } = await loadFixture(deployFixture);
    });
  })

  describe("NFT Functionalities", function () {

    it("Should mint a nft with cryto", async function () {
      const { weth, wbtc, wbnb, nft, owner, operator, user1, user2 } = await loadFixture(deployFixture);

      // Approve weth to NFT Contract
      await weth.approve(nft.address, 1000);

      // Mint NFT
      tx = await nft.mint(user1.address, [weth.address], [100])
      await tx.wait()


      expect(await nft.ownerOf(1)).to.equal(user1.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);

      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);
    });

    it("Add more ERC20 tokens to existing minted NFT", async function () {
      const { weth, wbtc, wbnb, nft, owner, operator, user1, user2 } = await loadFixture(deployFixture);

      // Approve weth to NFT Contract
      await weth.approve(nft.address, 1000)

      // Mint NFT
      tx = await nft.mint(user1.address,[weth.address], [100])
      await tx.wait()

      expect(await nft.ownerOf(1)).to.equal(user1.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);
      
      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);

      //===  Add wbtc and wbnb to tokenId: 1 ====

      // Approve wbtc, wbnb
      await wbtc.connect(operator).approve(nft.address, 1000)
      await wbnb.connect(operator).approve(nft.address, 1000)

      // update and transfer to NFT
      await nft.connect(operator).addERC20Tokens(1, [wbtc.address, wbnb.address], [10, 10])

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);
      expect(erc20Tokens[1]).to.equal(wbtc.address);
      expect(erc20Tokens[2]).to.equal(wbnb.address);
      
      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(1, wbtc.address)).to.equal(10);
      expect(await nft.getERC20BalanceOf(1, wbnb.address)).to.equal(10);
    });

    it("Should withdraw erc20 tokens from nft", async function () {
      const { weth, wbtc, wbnb, nft, owner, operator, user1, user2 } = await loadFixture(deployFixture);

      // Approve weth to NFT Contract
      await weth.approve(nft.address, 1000)

      // Mint NFT
      tx = await nft.mint(user1.address,[weth.address], [100])
      await tx.wait()

      expect(await nft.ownerOf(1)).to.equal(user1.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);
      
      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);

      //===  Add wbtc and wbnb to tokenId: 1 ====

      // Approve wbtc, wbnb
      await wbtc.connect(operator).approve(nft.address, 1000)
      await wbnb.connect(operator).approve(nft.address, 1000)

      // update and transfer to NFT
      await nft.connect(operator).addERC20Tokens(1, [wbtc.address, wbnb.address], [10, 10])

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);
      expect(erc20Tokens[1]).to.equal(wbtc.address);
      expect(erc20Tokens[2]).to.equal(wbnb.address);
      
      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(1, wbtc.address)).to.equal(10);
      expect(await nft.getERC20BalanceOf(1, wbnb.address)).to.equal(10);

      expect(await weth.balanceOf(user2.address)).to.equal(0);
      // withdraw erc20 from nft to user2 address
      await nft.connect(user1).burnNFTAndWithdrawAllERC20Tokens(1, user2.address) 

      // tokens transferred to user2
      expect(await weth.balanceOf(user2.address)).to.equal(100);
      expect(await wbtc.balanceOf(user2.address)).to.equal(10);
      expect(await wbnb.balanceOf(user2.address)).to.equal(10);

      // balances updated in nft contract
      await expect(nft.getERC20lockedByTokenId(1)).to.be.revertedWith("Invalid token ID");
     

    });

    it("Should withdraw only wbnb tokens from nft", async function () {
      const { weth, wbtc, wbnb, nft, owner, operator, user1, user2 } = await loadFixture(deployFixture);

      // Approve weth to NFT Contract
      await weth.approve(nft.address, 1000)

      // Mint NFT
      tx = await nft.mint(user1.address,[weth.address], [100])
      await tx.wait()

      expect(await nft.ownerOf(1)).to.equal(user1.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);
      
      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);

      //===  Add wbtc and wbnb to tokenId: 1 ====

      // Approve wbtc, wbnb
      await wbtc.connect(operator).approve(nft.address, 1000)
      await wbnb.connect(operator).approve(nft.address, 1000)

      // update and transfer to NFT
      await nft.connect(operator).addERC20Tokens(1, [wbtc.address, wbnb.address], [10, 10])

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);
      expect(erc20Tokens[1]).to.equal(wbtc.address);
      expect(erc20Tokens[2]).to.equal(wbnb.address);
      
      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(1, wbtc.address)).to.equal(10);
      expect(await nft.getERC20BalanceOf(1, wbnb.address)).to.equal(10);

      expect(await weth.balanceOf(user2.address)).to.equal(0)

      // withdraw erc20 from nft to user2 address
      await nft.connect(user1).withdrawERC20Token(1, wbnb.address, user2.address) 
      
      // tokens transferred to user2
      expect(await weth.balanceOf(user2.address)).to.equal(0);
      expect(await wbtc.balanceOf(user2.address)).to.equal(0);
      expect(await wbnb.balanceOf(user2.address)).to.equal(10);

      // balances updated in nft contract
      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens.length).to.equal(2);

      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(1, wbtc.address)).to.equal(10);
      expect(await nft.getERC20BalanceOf(1, wbnb.address)).to.equal(0);

    });

    it("Should swap cryto with another NFT", async function () {
      const { weth, wbtc, wbnb, nft, owner, operator, user1, user2 } = await loadFixture(deployFixture);

      // Approve weth to NFT Contract
      await weth.approve(nft.address, 1000);
      await wbtc.approve(nft.address, 1000);

      // Mint NFT
      tx = await nft.mint(user1.address,[weth.address], [100])
      await tx.wait()

      tx = await nft.mint(user1.address, [wbtc.address], [500])
      await tx.wait()

      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.ownerOf(2)).to.equal(user1.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(2);
      expect(erc20Tokens[0]).to.equal(wbtc.address);

      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(1, wbtc.address)).to.equal(0);

      expect(await nft.getERC20BalanceOf(2, weth.address)).to.equal(0);
      expect(await nft.getERC20BalanceOf(2, wbtc.address)).to.equal(500);

      // Swap token1 and token2 Crytos
      tx = await nft.connect(user1).swapErc20Tokens(1,2)
      await tx.wait()


      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(wbtc.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(2);
      expect(erc20Tokens[0]).to.equal(weth.address);

      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(0);
      expect(await nft.getERC20BalanceOf(1, wbtc.address)).to.equal(500);

      expect(await nft.getERC20BalanceOf(2, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(2, wbtc.address)).to.equal(0);

      // Swap token1 and token2 Crytos again
      tx = await nft.connect(user1).swapErc20Tokens(1,2)
      await tx.wait()

      // Back to initial state before swapping
      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(2);
      expect(erc20Tokens[0]).to.equal(wbtc.address);

      expect(await nft.getERC20BalanceOf(1, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(1, wbtc.address)).to.equal(0);

      expect(await nft.getERC20BalanceOf(2, weth.address)).to.equal(0);
      expect(await nft.getERC20BalanceOf(2, wbtc.address)).to.equal(500);

    });

    it("Should Merge NFT cryto to master NFT", async function () {
      const { weth, wbtc, wbnb, nft, owner, operator, user1, user2 } = await loadFixture(deployFixture);

      // Approve weth to NFT Contract
      await weth.approve(nft.address, 1000);
      await wbtc.approve(nft.address, 1000);
      await wbnb.approve(nft.address, 1000);

      // Mint NFT
      tx = await nft.mint(user1.address,[weth.address], [100])
      await tx.wait()

      tx = await nft.mint(user1.address, [wbtc.address], [100])
      await tx.wait()

      tx = await nft.mint(user1.address, [wbnb.address], [100])
      await tx.wait()

      expect(await nft.ownerOf(1)).to.equal(user1.address);
      expect(await nft.ownerOf(2)).to.equal(user1.address);
      expect(await nft.ownerOf(3)).to.equal(user1.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(1);
      expect(erc20Tokens[0]).to.equal(weth.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(2);
      expect(erc20Tokens[0]).to.equal(wbtc.address);

      erc20Tokens = await nft.getERC20lockedByTokenId(3);
      expect(erc20Tokens[0]).to.equal(wbnb.address);

      // Burn and merge token1 and token2 Crytos to token3
      tx = await nft.connect(user1).burnAndMergeNFT([1,2],3);
      await tx.wait()

      await expect(nft.getERC20lockedByTokenId(1)).to.be.revertedWith("Invalid token ID");

      await expect(nft.getERC20lockedByTokenId(2)).to.be.revertedWith("Invalid token ID");

      expect(await nft.getERC20BalanceOf(3, weth.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(3, wbtc.address)).to.equal(100);
      expect(await nft.getERC20BalanceOf(3, weth.address)).to.equal(100);

    });
  });
});
