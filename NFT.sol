// SPDX-License-Identifier: UNLICENSED

// contracts/NFT.sol
// Author: Thanh Le (lythanh.xyz)
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    mapping(uint256 => bool) private _lockTokens;
    mapping(address => bool) private _whitelistedMinters;

    event NFTLocked(uint256 indexed tokenId, bool locked);
    event NFTMintersWhitelistChanged(address indexed minterAddress, bool allowance);

    /* Minter whitelisting */
    modifier onlyWhitelistedMinter() {
        require(_whitelistedMinters[msg.sender], "Minter not allowed.");
        _;
    }

    function setWhitelistedMinter(address minterAddress, bool allowance) external onlyOwner {
        _whitelistedMinters[minterAddress] = allowance;
        emit NFTMintersWhitelistChanged(minterAddress, allowance);
    }

    function whitelistedMinter(address minterAddress) external view returns (bool) {
        return (_whitelistedMinters[minterAddress]);
    }

    constructor() ERC721("ASPO NFTs", "ASPO NFT") {
        _whitelistedMinters[msg.sender] = true;
    }

    // mint a new token
    function createToken(uint256 tokenId, string memory uriOfToken) public onlyWhitelistedMinter {
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, uriOfToken);
        _lockTokens[tokenId] = false;
    }

    // mint multiple tokens
    function createTokens(string memory tokenBaseURI, uint256[] memory tokenIds) public onlyWhitelistedMinter {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 newItemId = tokenIds[i];
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, string(abi.encodePacked(tokenBaseURI, Strings.toString(newItemId))));
            _lockTokens[newItemId] = false;
        }
    }

    // mint a new token for a specific user
    function createTokenForUser(uint256 tokenId, string memory uriOfToken, address ownerAddress) public onlyWhitelistedMinter {
        _safeMint(ownerAddress, tokenId);
        _setTokenURI(tokenId, uriOfToken);
        _lockTokens[tokenId] = false;
    }

    // mint multiple tokens for a specific user
    function createTokensForUser(string memory tokenBaseURI, uint256[] memory tokenIds, address ownerAddress) public onlyWhitelistedMinter {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 newItemId = tokenIds[i];
            _safeMint(ownerAddress, newItemId);
            _setTokenURI(newItemId, string(abi.encodePacked(tokenBaseURI, Strings.toString(newItemId))));
            _lockTokens[newItemId] = false;
        }
    }

    // burn a token
    function burn(uint256 tokenId) public onlyWhitelistedMinter {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /// @notice Returns a list of all ASPO NFTs assigned to an address.
    /// @param ownerAddress The owner whose ASPO NFT we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire NFT array looking for cats belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokenIdsOfOwner(address ownerAddress) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(ownerAddress);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(ownerAddress, i);
            }
            return result;
        }
    }

    struct TokenItem {
        uint256 tokenId;
        string tokenURI;
        bool locked;
    }

    function tokenItemOfOwner(address ownerAddress) external view returns (TokenItem[] memory) {
        uint256 tokenCount = balanceOf(ownerAddress);

        if (tokenCount == 0) {
            // Return an empty array
            return new TokenItem[](0);
        } else {
            TokenItem[] memory result = new TokenItem[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i].tokenId = tokenOfOwnerByIndex(ownerAddress, i);
                result[i].tokenURI = tokenURI(result[i].tokenId);
                result[i].locked = _lockTokens[result[i].tokenId];
            }
            return result;
        }
    }

    function isTokenLocked(uint256 tokenId) external view returns (bool) {
        return (_lockTokens[tokenId]);
    }

    // functions to lock/unlock token
    function lockToken(uint256 tokenId, bool locked) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ASPO NFTs: lockToken caller is not owner nor approved");
        require(_lockTokens[tokenId] != locked, "ASPO NFTs: invalid params");
        _lockTokens[tokenId] = locked;
        emit NFTLocked(tokenId, locked);
    }

    // override transfer functions to handle lock token logic
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(!_lockTokens[tokenId]);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(!_lockTokens[tokenId]);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(!_lockTokens[tokenId]);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFromAndLock(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(!_lockTokens[tokenId]);
        super.transferFrom(from, to, tokenId);
        _lockTokens[tokenId] = true;
        emit NFTLocked(tokenId, true);
    }

    function safeTransferFromAndLock(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(!_lockTokens[tokenId]);
        super.safeTransferFrom(from, to, tokenId);
        _lockTokens[tokenId] = true;
        emit NFTLocked(tokenId, true);
    }

    // ========================
    // Override functions
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}
