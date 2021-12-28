// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


// // // // // // // // // // // // // // // // // // // // // // // // // // // // //
//       ___           ___           ___           ___                              //
//      /  /\         /  /\         /  /\         /  /\        ___         ___      //
//     /  /::|       /  /::\       /  /:/_       /  /:/       /  /\       /  /\     //
//    /  /:/:|      /  /:/\:\     /  /:/ /\     /  /:/       /  /:/      /  /:/     //
//   /  /:/|:|__   /  /:/~/::\   /  /:/ /::\   /  /:/  ___  /__/::\     /__/::\     //
//  /__/:/ |:| /\ /__/:/ /:/\:\ /__/:/ /:/\:\ /__/:/  /  /\ \__\/\:\__  \__\/\:\__  //
//  \__\/  |:|/:/ \  \:\/:/__\/ \  \:\/:/~/:/ \  \:\ /  /:/    \  \:\/\    \  \:\/\ //
//      |  |:/:/   \  \::/       \  \::/ /:/   \  \:\  /:/      \__\::/     \__\::/ //
//      |  |::/     \  \:\        \__\/ /:/     \  \:\/:/       /__/:/      /__/:/  //
//      |  |:/       \  \:\         /__/:/       \  \::/        \__\/       \__\/   //
//      |__|/         \__\/         \__\/         \__\/                             //
//                                                                                  //
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // 


contract ERC721Template is ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    event BaseURIUpdated(string newBaseURL);
    event MerkleRootUpdated(bytes32 newMerkleRoot);
    
    bool public mintActive = false;
    uint256 public lastMintedId;
    uint256 public constant MAX_SUPPLY = 42069;
    uint256 public constant MINT_PRICE = 0.06 ether;
    uint256 public constant MINT_PRICE_TOKEN = 100000;
    
    bool public baseURILocked = false;
    string public baseURI;

    bytes32 public merkleRoot;
    mapping(address => bool) public claimeWhitelist;

    IERC20 private _token;

    constructor(IERC20 token) ERC721("Name", "SYMBOL") {
        _token = token;
    }

    function getBase() public view onlyOwner returns (string memory){
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }
    
    function setBaseURI(string memory _url) public onlyOwner {
        require(!baseURILocked, "Metadata locked.");
        emit BaseURIUpdated(_url);
        baseURI = _url;
    }
    
    function setBaseLocked() public onlyOwner returns (bool) {
        baseURILocked = true;
        return baseURILocked;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        emit MerkleRootUpdated(_merkleRoot);
        merkleRoot = _merkleRoot;
    }
    
    function mintState() public onlyOwner returns (bool) {
        mintActive = !mintActive;
        return mintActive;
    }

    function getMintState() public view onlyOwner returns (bool){
        return mintActive;
    }

    function mintEth() public payable nonReentrant {
        require(mintActive, "Minting not active.");
        require(
            lastMintedId < MAX_SUPPLY,
            "Minting has ended.");
        require(MINT_PRICE == msg.value, "Must use correct amount of ETH.");
        _mint();
    }

    function mintToken() public payable nonReentrant {
        require(mintActive, "Minting not active.");
        require(
            lastMintedId < MAX_SUPPLY,
            "Minting has ended.");
        address from = msg.sender;
        _token.transferFrom(from, address(this), MINT_PRICE_TOKEN);
        _mint();
    }

    function _mint() private {
        require(lastMintedId < MAX_SUPPLY, "Mint limit reached");
        uint256 newTokenId = lastMintedId + 1;
        lastMintedId = newTokenId;
        _safeMint(msg.sender, newTokenId);
    }

    function reserveMint() public onlyOwner {
        _mint();
    }

    function whitelistMint(bytes32[] calldata merkleProof) public nonReentrant{
        require(!claimeWhitelist[msg.sender], "Already claimed whitelist");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not in whitelist");
        claimeWhitelist[msg.sender] = true;
        _mint();
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(uint256 amount) public onlyOwner {
        _token.transfer(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}