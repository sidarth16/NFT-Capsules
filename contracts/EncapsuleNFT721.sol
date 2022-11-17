// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "hardhat/console.sol";

contract EncapsuleNFT721 is
    Context,
    ERC721,
    ERC721Burnable,
    // ERC721URIStorage,
    AccessControl
{
    using Counters for Counters.Counter;
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

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function getERC20BalanceOf(uint256 _tokenId, address _erc20Address) external view returns ( uint256) {
        return _erc20Balances[_tokenId][_erc20Address];
    }

    function getERC20lockedByTokenId(uint256 _tokenId) external view returns ( address[] memory ) {
        return _erc20Tokenlocked[_tokenId];
    }   

    // function setBaseURI(string memory _baseTokenURI) external onlyRole("ADMIN_ROLE") {
    //     baseTokenURI = _baseTokenURI;
    // }

    function mint(
        address mintTo,
        address[] calldata _erc20TokenAddresses,
        uint256[] calldata _erc20TokenAmounts
    ) external virtual onlyRole("ADMIN_ROLE") returns (uint256 _tokenId) {

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
    ) external virtual onlyRole("OPERATOR_ROLE") {
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

    function withdrawAllERC20Tokens( 
        uint256 _tokenId,
        address beneficiaryAddress
    ) external virtual onlyRole("OPERATOR_ROLE") {
        for(uint i = 0 ; i< _erc20Tokenlocked[_tokenId].length; i++){
            address _token = _erc20Tokenlocked[_tokenId][i];
            uint256 _amount = _erc20Balances[_tokenId][_token];
            require( IERC20(_token).transfer( beneficiaryAddress, _amount ), "failure while transferring ERC20 Tokens");
            
            // Updates balances
            _erc20Balances[_tokenId][_token] = 0;   
        }
        delete _erc20Tokenlocked[_tokenId] ; 

        emit erc20WithdrawAll(_tokenId, beneficiaryAddress);
    }

    function withdrawERC20Token( 
        uint256 _tokenId,
        address _erc20TokenAddress,
        address beneficiaryAddress
    ) external virtual onlyRole("OPERATOR_ROLE") {
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

    function swapErc20Tokens(uint256 _tokenId1, uint256 _tokenId2) external virtual onlyRole("OPERATOR_ROLE") {
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
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual override(ERC721) {
    //     super._beforeTokenTransfer(from, to, tokenId, 1);
    // }

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