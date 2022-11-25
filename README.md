# Sample Hardhat Project

This project demonstrates Encapsultion of NFT along with multiple ERC20s. <br/>
- [ NFT + ERC20 ] encapsultion

- **User** --(owns)--> **NFT**
    - **NFT** --(owns)--> **ERC20 Tokens** <br/>

Example : 
- Let User (0xd0208e192353a4dca9f3126b51595435704e019b)
    - Owns NFT TokenId #1
    - TokenId #1 holds:
        - WETH: 1000000000000000000 Wei
        - WBTC: 250000000000000000000 Wei
        - WBNB: 16000000000000000000 Wei
        - WMATIC: 77000000000000000000 Wei

    - Then NFT looks like : <br/>
    - ![NFT #1](assets/sample_nft.svg)

<br/>

### - Instead of sending tokens to User Wallet address, we can use the above NFT as Wallet and add Tokens to this NFT.

### - User can burn this NFT and claim to his wallet address whenver he wishes.

###  - Other Available Functionalties : 
- Burn and Merge two NFTs
- NFT Swappinfg

