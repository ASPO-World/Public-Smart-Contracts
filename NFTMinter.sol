// SPDX-License-Identifier: UNLICENSED

// contracts/NFT.sol
// Author: Thanh Le (lythanh.xyz)
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface INFT {
    function createTokenForUser(uint256 tokenId, string memory uriOfToken, address ownerAddress) external;
}

contract NFTMinter is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter[] private tokenCounters;

    address public nftContract;
    uint256 public totalGroup = 5; // total group of treasure box
    uint256[] public maxTokenCount = [1000, 1000, 1000, 1000, 999];
    uint256 public baseIndex;
    string public baseURI;

    mapping(address => bool) private _whitelistedMinters;

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

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    constructor(address nftAddress, uint256 index) {
        _whitelistedMinters[msg.sender] = true;
        nftContract = nftAddress;
        for (uint i = 0; i < totalGroup; ++i) tokenCounters.push(Counters.Counter({_value : 0}));
        baseIndex = index;
    }

    // mint a new token to owner
    function mintToken(address owner, uint group) public onlyWhitelistedMinter {
        require(group < totalGroup, "Wrong group value");
        require(tokenCounters[group].current() < maxTokenCount[group], "Not enough token");
        // we can calculate using this equation because the first 4 groups have the same size
        uint tokenBaseIndex = 1000 * group;
        tokenCounters[group].increment();
        uint256 tokenId = tokenCounters[group].current() + tokenBaseIndex + baseIndex;
        INFT(nftContract).createTokenForUser(tokenId, string(abi.encodePacked(baseURI, Strings.toString(tokenId))), owner);
    }

    // mint multiple tokens to owner
    function mintTokens(address owner, uint count, uint group) public onlyWhitelistedMinter {
        require(group < totalGroup, "Wrong group value");
        require(tokenCounters[group].current() + count <= maxTokenCount[group], "Not enough token");
        // we can calculate using this equation because the first 4 groups have the same size
        uint tokenBaseIndex = 1000 * group;
        for (uint i = 0; i < count; ++i) {
            tokenCounters[group].increment();
            uint256 tokenId = tokenCounters[group].current() + tokenBaseIndex + baseIndex;
            INFT(nftContract).createTokenForUser(tokenId, string(abi.encodePacked(baseURI, Strings.toString(tokenId))), owner);
        }
    }

    function countMintedToken() external view returns (uint256[] memory){
        uint256[] memory counts = new uint256[](totalGroup);
        for (uint i = 0; i < totalGroup; ++i) {
            counts[i] = tokenCounters[i].current();
        }
        return counts;
    }

    function countAvailableToken() external view returns (uint256[] memory) {
        uint256[] memory counts = new uint256[](totalGroup);
        for (uint i = 0; i < totalGroup; ++i) {
            counts[i] = maxTokenCount[i] - tokenCounters[i].current();
        }
        return counts;
    }
}
