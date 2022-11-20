// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract EncapsuleNFT721 is
    ERC721,
    ERC721Burnable,
    AccessControl
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    string private baseTokenURI;
    address public owner;
    mapping(uint256 => bool) private usedNonce;
    address public operator;

    // TokenId -> erc20TokenAddresses
    mapping(uint256 => address[]) private _erc20Tokenlocked;

    // TokenId -> erc20TokenAddresses -> TokenBalance
    mapping(uint256 => mapping(address => uint256)) private _erc20Balances;

    // mapping used for swapping
    mapping(uint256 => mapping(address => uint256)) private tempTokenBalances;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event Minted(address to, uint256 tokenId, address[] erc20TokenAddresses,  uint256[] erc20TokenAmounts);

    event erc20TokenAdded(uint256 tokenId, address[] erc20TokenAddresses,  uint256[] erc20TokenAmounts);

    event erc20WithdrawAll(uint256 tokenId, address beneficiaryAddress);

    event erc20Withdraw(uint256 tokenId, address erc20TokenAddresses, address beneficiaryAddress);

    event erc20Swapped(uint256 tokenId1, uint256 tokenId2);

    event BurnAndMergedNFT(uint256[] fromTokenIds, uint256 MergedToTokenId);

    constructor() ERC721("EncapsuleNFT721", "EncapsuleNFT721") {
        owner = _msgSender();
        operator = _msgSender();
        _setupRole("ADMIN_ROLE", msg.sender);
        _setupRole("OPERATOR_ROLE", operator);
        _tokenIdTracker.increment();
    }

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        emit OwnershipTransferred(owner, newOwner);
        return true;
    }
    
    function getERC20BalanceOf(uint256 _tokenId, address _erc20Address) external view returns ( uint256) {
        require(_exists(_tokenId),"Invalid token ID");
        return _erc20Balances[_tokenId][_erc20Address];
    }

    function getERC20lockedByTokenId(uint256 _tokenId) external view returns ( address[] memory ) {
        require(_exists(_tokenId),"Invalid token ID");
        return _erc20Tokenlocked[_tokenId];
    }   

    function mint(
        address mintTo,
        address[] calldata _erc20TokenAddresses,
        uint256[] calldata _erc20TokenAmounts
    ) external virtual returns (uint256 _tokenId) {

        require(_erc20TokenAddresses.length == _erc20TokenAmounts.length, "Mismatch in arguments length");
        _tokenId = _tokenIdTracker.current();
        _mint(mintTo, _tokenId);

        for(uint i = 0 ; i<_erc20TokenAddresses.length; i++){
            require( IERC20(_erc20TokenAddresses[i]).transferFrom(_msgSender(), address(this), _erc20TokenAmounts[i]), "failure while transferring ERC20 Tokens");
            _erc20Balances[_tokenId][_erc20TokenAddresses[i]] = _erc20TokenAmounts[i] ;
        }

        _erc20Tokenlocked[_tokenId] = _erc20TokenAddresses ;

        _tokenIdTracker.increment();

        emit Minted(mintTo, _tokenId, _erc20TokenAddresses, _erc20TokenAmounts);
        return _tokenId;
    }

    function addERC20Tokens( 
        uint256 _tokenId,
        address[] calldata _erc20TokenAddresses, 
        uint256[] calldata _erc20TokenAmounts
    ) public virtual {
        for(uint i = 0 ; i<_erc20TokenAddresses.length; i++){
            require( IERC20(_erc20TokenAddresses[i]).transferFrom(_msgSender(), address(this), _erc20TokenAmounts[i]), "failure while transferring ERC20 Tokens");
            if (_erc20Balances[_tokenId][_erc20TokenAddresses[i]] == 0){
                _erc20Tokenlocked[_tokenId].push(_erc20TokenAddresses[i]);
                _erc20Balances[_tokenId][_erc20TokenAddresses[i]] = _erc20TokenAmounts[i] ;
            }
            else{
            _erc20Balances[_tokenId][_erc20TokenAddresses[i]] += _erc20TokenAmounts[i] ;
            }
        }

        emit erc20TokenAdded(_tokenId, _erc20TokenAddresses,  _erc20TokenAmounts);
    }

    function burnNFTAndWithdrawAllERC20Tokens( 
        uint256 _tokenId,
        address beneficiaryAddress
    ) external virtual {
        require(msg.sender == ownerOf(_tokenId), "Unauthorized Access");
        for(uint i = 0 ; i< _erc20Tokenlocked[_tokenId].length; i++){
            address _token = _erc20Tokenlocked[_tokenId][i];
            uint256 _amount = _erc20Balances[_tokenId][_token];
            require( IERC20(_token).transfer( beneficiaryAddress, _amount ), "failure while transferring ERC20 Tokens");
            
            // Updates balances
            _erc20Balances[_tokenId][_token] = 0;   
        }
        delete _erc20Tokenlocked[_tokenId] ; 
        _burn( _tokenId);

        emit erc20WithdrawAll(_tokenId, beneficiaryAddress);
    }

    function withdrawERC20Token( 
        uint256 _tokenId,
        address _erc20TokenAddress,
        address beneficiaryAddress
    ) external virtual{

        require(msg.sender == ownerOf(_tokenId), "Unauthorized Access");
        require(_erc20Tokenlocked[_tokenId].length>1, "Atleast 1 ERC 20 should be left encapsulated");

        for(uint i = 0 ; i < _erc20Tokenlocked[_tokenId].length; i++){
            address _token = _erc20Tokenlocked[_tokenId][i];
            
            if (_token == _erc20TokenAddress){
                uint256 _amount = _erc20Balances[_tokenId][_token];

                // transfer tokens
                require( IERC20(_token).transfer( beneficiaryAddress, _amount ), "failure while transferring ERC20 Tokens");
                
                // Updates balances
                _erc20Balances[_tokenId][_token] = 0;  

                _erc20Tokenlocked[_tokenId][i] = _erc20Tokenlocked[_tokenId][_erc20Tokenlocked[_tokenId].length-1] ;
                _erc20Tokenlocked[_tokenId].pop();
            }
            
        }
        emit erc20Withdraw(_tokenId, _erc20TokenAddress, beneficiaryAddress);
    }

    function burnAndMergeNFT(uint256[] calldata _fromTokenIds, uint256 tokenId) external virtual {   

        for(uint i=0; i<_fromTokenIds.length; i++){

            uint256 fromTokenId = _fromTokenIds[i];
            require(msg.sender == ownerOf(fromTokenId), "Unauthorized Access");
            address[] memory erc20TokenAddresses = _erc20Tokenlocked[fromTokenId];

            for (uint j=0; j<erc20TokenAddresses.length; j++){
                if (_erc20Balances[tokenId][erc20TokenAddresses[j]] == 0){
                    _erc20Tokenlocked[tokenId].push(erc20TokenAddresses[j]);
                    _erc20Balances[tokenId][erc20TokenAddresses[j]] = _erc20Balances[fromTokenId][erc20TokenAddresses[j]] ;
                }
                else{
                    _erc20Balances[tokenId][erc20TokenAddresses[j]] += _erc20Balances[fromTokenId][erc20TokenAddresses[j]] ;
                }
                _erc20Balances[fromTokenId][erc20TokenAddresses[j]] = 0 ;
            }
            delete _erc20Tokenlocked[fromTokenId];
            _burn( fromTokenId);
        }
        emit BurnAndMergedNFT(_fromTokenIds, tokenId);
    }

    function swapErc20Tokens(uint256 _tokenId1, uint256 _tokenId2) external virtual {
        require((msg.sender == ownerOf(_tokenId1)) && (msg.sender == ownerOf(_tokenId2)), "Unauthorized Access");
        address[] memory tempTokensLocked1 = _erc20Tokenlocked[_tokenId1] ;
        address[] memory tempTokensLocked2 = _erc20Tokenlocked[_tokenId2] ;
        delete _erc20Tokenlocked[_tokenId1];
        delete _erc20Tokenlocked[_tokenId2];

        for(uint i=0; i<tempTokensLocked1.length; i++){
            address tokenAddress = tempTokensLocked1[i];
            tempTokenBalances[_tokenId1][tokenAddress] = _erc20Balances[_tokenId1][tokenAddress];
            _erc20Balances[_tokenId1][tokenAddress] = 0;
        }

        for(uint i=0; i<tempTokensLocked2.length; i++){
            address tokenAddress = tempTokensLocked2[i];
            tempTokenBalances[_tokenId2][tokenAddress] = _erc20Balances[_tokenId2][tokenAddress];
            _erc20Balances[_tokenId2][tokenAddress] = 0;
        }

        //Update tokenId1  from ( tempTokenBalances of tokenId2 )
        for(uint i=0; i<tempTokensLocked2.length; i++){
            _erc20Balances[_tokenId1][tempTokensLocked2[i]] = tempTokenBalances[_tokenId2][tempTokensLocked2[i]];
        }

        //Update tokenId2 ) from ( tempTokenBalances of tokenId1 )
        for(uint i=0; i<tempTokensLocked1.length; i++){
            _erc20Balances[_tokenId2][tempTokensLocked1[i]] = tempTokenBalances[_tokenId1][tempTokensLocked1[i]];
        }

        _erc20Tokenlocked[_tokenId1] = tempTokensLocked2 ;
        _erc20Tokenlocked[_tokenId2] = tempTokensLocked1 ;
        
        emit erc20Swapped(_tokenId1, _tokenId2);
    }

    function generateSVG(uint256 tokenId) public virtual view returns (string memory svg) {

        string memory token = tokenId.toString();
        if (bytes(token).length == 1) token = string(abi.encodePacked('0',token));

        address[] memory erc20Tokens = _erc20Tokenlocked[tokenId];
        uint256 height = 275;
        if(erc20Tokens.length>4) height = height + (50 * (erc20Tokens.length-4));
        svg =  string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" style="background:#ffff" width="350" height="',height.toString(),'">", ',
            '<rect id="header" x="0" y="0" width="350" height="58" opacity="85%" fill="#1a1a19"/>',
            '<text id="TokenId" x="110" y="25" stroke="#ffffff" stroke-width="0.25" fill="#f5c240" style="font: 20px Copperplate;"> Wallet #',token,'</text>',
            '<text id="Owner" x="4" y="47" fill="#f8f7f4" style="font-family:Monospace;font-size:13.5">',
            Strings.toHexString(uint160(ownerOf(tokenId)), 20),'</text>',
            '<rect id="bg" x="0" y="60" width="100%" height="100%" opacity="85%" fill="#F3BA2F">',
            '<animate attributeName="opacity" dur="5s"  values="0.25; 0.45; 0.60; 0.85; 1; 0.85; 0.60; 0.45; 0.25" repeatCount="indefinite"/> </rect>'
        ));

        delete height; delete token ;

        for (uint256 i=0; i<erc20Tokens.length; i++){
            string memory tokenSymbol = IERC20(erc20Tokens[i]).symbol();
            uint256 tokenBalance = _erc20Balances[tokenId][erc20Tokens[i]];
            uint256 pathY = 80 + 50*i ;
            uint256 textY = pathY+20 ;
            svg = string(abi.encodePacked(
                    svg,
                    '<path stroke="#000000" stroke-width="3" opacity="90%" d="M 18 ',pathY.toString(),' v 30 h 310 v -30 z" fill="#ffffff"/>',
                    '<text x="25" y="',textY.toString(),'" style="font-family:Monospace;font-size:15">',
                    tokenSymbol,': ',tokenBalance.toString(),' Wei',
                    '</text>'
                    ));
        }  

        svg = string(abi.encodePacked(svg,  "</svg>" ));
        return svg ;
    }

    function getAttributes(uint256 tokenId) internal virtual view returns(string memory attr){
        address[] memory erc20Tokens = _erc20Tokenlocked[tokenId];
        uint256 numOfTokens = erc20Tokens.length ;

        for (uint256 i=0; i<numOfTokens; i++){
            attr = string(abi.encodePacked( 
                        attr,
                        '{"trait_type":"Token", "value":"',IERC20(erc20Tokens[i]).symbol(),'"},'
                    ));
        }  

        attr =  string(abi.encodePacked(attr,
            '{"trait_type": "Level", "value":',numOfTokens.toString(),'}'
        ));
    }

    function generateFinalMetaJson(uint256 tokenId) internal view returns (string memory){
        string memory token = tokenId.toString();
        if (bytes(token).length == 1) token = string(abi.encodePacked('0',token));
        string memory nftName = string(abi.encodePacked("Portfolio #", tokenId.toString())) ;

        string memory finalSvg = generateSVG(tokenId);
        string memory attr = getAttributes(tokenId);

        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        // set the title of minted NFT.
                        '{"name": "',nftName,'",',
                        ' "description": "On-Chain Portfolio Managment !",',
                        ' "attributes": [',attr,'],',
                        ' "image": "data:image/svg+xml;base64,',
                        //add data:image/svg+xml;base64 and then append our base64 encode our svg.
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        // prepend data:application/json;base64, to our data.
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return finalTokenUri;
    }    
    

    function _burn(uint256 tokenId)
        internal
        override(ERC721)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return generateFinalMetaJson(tokenId);
        // return super.tokenURI(tokenId);
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}