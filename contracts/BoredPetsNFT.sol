//SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title BoredPetsNFT smart contract for minting new tokens.
/// @author ddos_kas
/// @notice mints ERC721 token type NFTs for the marketplace.
/// @dev To be a valid NFT, BoredPets implements ERC721 standard by inheriting the implementation of ERC721URIStorage.sol abstract contract available in openzeppelin project. It is used so that we can store the tokenURI's on chain in storage(which is what allows us to store the metadata we upload on chain).

contract BoredPetsNFT is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; // Counter type variable to track total number of NFTs and assign a unique token id to each NFT.
    address marketplaceContract; // address of the marketplace contract where our NFTs will be traded.

    /// @notice Event to mark successful minting of a NFT.
    /// @param  tokenId unique tokenIdentifier of the minted NFT.
    event NFTMinted(uint256 tokenId);

    constructor(address _marketplaceContract)
        ERC721("Bored Pets Yatch Club", "BPYC")
    {
        marketplaceContract = _marketplaceContract;
    }

    /// @notice Function to mint a ERC721 token type NFT,
    /// @dev Allowing marketplace contract to transfer a token of sender on their behalf during minting itself. To revoke these rights manually approve in the marketplace contract while listing.
    /// @param _tokenURI a unique identifier of what the token "looks" like.
    function mint(string memory _tokenURI) public nonReentrant {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        // Function to safely mint tokens.
        _safeMint(msg.sender, newTokenId);
        // Internal function to set the token URI for a given token.
        // Reverts if the token ID does not exist.
        _setTokenURI(newTokenId, _tokenURI);
        // Sets or unsets the approval of a given operator. An operator is allowed to transfer all tokens of the sender on their behalf.
        setApprovalForAll(marketplaceContract, true);
        emit NFTMinted(newTokenId);
    }
}
