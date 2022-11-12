//SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 @title BoredPetsNFT smart contract 
 @author ddos_kas
 @notice mints ERC721 token type NFTs and initializes the marketplace
 @dev to be a valid NFT, BoredPetsNFT implements the ERC721 standard by inheriting the implementation of ERC721URIStorage.sol
    The implementation of ERC721 is used so that we store the tokenURIs on chain in storage, which is what allows us to store the metadata we upload 

    Also here, we used a counter to track the total number of NFTs and assign a unique token id to each NFT.
    address marketplaceContract is the address of the Marketplace contract we'll be writing in the next section.
    event NFTMinted will be emitted every time a NFT is minted. When an event is emitted in solidity, the parameters are stored in the transaction's log. We will need the tokenId later when we build out the web app.
 */

contract BoredPetsNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketplaceContract;

    /// @notice Explain to an end user what this does
    event NFTMinted(uint256);

    constructor(address _marketplaceContract)
        ERC721("Bored Pets Yatch Club", "BPYC")
    {
        marketplaceContract = _marketplaceContract;
    }

    /// @notice Minting an NFT, or non-fungible token, is publishing a unique digial asset on a blockchain so that it can be bought, sold, and traded.
    /// @param _tokenURI unique identifier for the NFT token type
    function mint(string memory _tokenURI) public {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        setApprovalForAll(marketplaceContract, true);
        emit NFTMinted(newTokenId);
    }
}
