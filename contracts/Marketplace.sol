//SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Marketplace smartcontract
/// @author ddos_kas
/// @dev don't use safeTransferFrom function for asset transfer ganache accounts will raise an error
///     `VM Exception while processing transaction: revert ERC721: transfer to non ERC721Receiver implementer`
///     because they get destroyed as soon as chain goes offline leaving assets locked.
contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter; // attach every function from library Counters to type Counters.Counter
    Counters.Counter private _nftsSold; //variable to keep count of sold NFTs
    Counters.Counter private _nftsCount; // variable to keep count of listed NFTs

    uint256 public LISTING_FEE = 0.001 ether; //  taken from the seller and transferred to marketplace contract owner whenever a NFT is sold.
    address payable private _marketOwner; // store the marketplace contract owner
    mapping(uint256 => NFT) private _idToNFT; // mapping for a unique token id to struct

    // NFT structure to store relevant information for an NFT listed in the marketplace
    struct NFT {
        address nftContract; // BoredPetsNFT smart contract address 
        uint256 tokenId;// unique token identifier for each NFT
        address payable seller;// seller's wallet address which can receive ether.
        address payable owner;// owner's wallet address which can receive ether.
        uint256 price;// price for the NFT
        bool listed;// flag to mark if the NFT is listed on the marketplace or not.
    }

    /// @notice emitted every time a NFT is listed on the marketplace
    event NFTListed(
        address nftContract,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price
    );

    ///@notice emitted every time a NFT is sold
    event NFTSold(
        address nftContract,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price
    );

    constructor() {
        _marketOwner = payable(msg.sender);
    }

    /// @notice this function is called when a user first mints and lists their NFT, this function here transfers ownership from the user over to the Marketplace contract.
    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        //require tooken id to be unique
        require(_price > 0, "Price must be atleast 1 wei");
        require(msg.value == LISTING_FEE, "Not enought ether for listing fee.");
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        _nftsCount.increment();
        _idToNFT[_tokenId] = NFT(
            _nftContract,
            _tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price,
            true
        );
        emit NFTListed(
            _nftContract,
            _tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price
        );
    }

    /// @notice this function is called when a user buys a NFT, the buyer becomes the new owner of the NFT,
    ///         the token is transferred from marketplace contract over to the buyer.
    function buyNFT(address _nftContract, uint256 _tokenId)
        public
        payable
        nonReentrant
    {
        NFT storage nft = _idToNFT[_tokenId];
        require(
            msg.value >= nft.price,
            "Not enough ether to cover asking price"
        );
        address payable buyer = payable(msg.sender);
        payable(nft.seller).transfer(msg.value); //transfer ether to seller
        IERC721(_nftContract).transferFrom(address(this), buyer, nft.tokenId);
        //revert if there is no listing fee coverage ether in sellers account
        require(
            nft.seller.balance >= LISTING_FEE,
            "Insufficient funds at seller."
        );
        _marketOwner.transfer(LISTING_FEE); // transfer listing fee to marketplace contract from seller.
        nft.owner = buyer;
        nft.listed = false;

        _nftsSold.increment();
        emit NFTSold(_nftContract, nft.tokenId, nft.seller, buyer, msg.value);
    }

    /// @notice this function is called when a buyer who previously bought a NFT from the marketplace wishes to resell it
    function relistNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        require(_price > 0, "Price must be atleast 1 wei");
        require(msg.value == LISTING_FEE, "Not enough ether for listing fee.");
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        NFT storage nft = _idToNFT[_tokenId];
        nft.seller = payable(msg.sender);
        nft.owner = payable(address(this));
        nft.listed = true;
        nft.price = _price;

        _nftsSold.decrement();
        emit NFTListed(
            _nftContract,
            _tokenId,
            msg.sender,
            address(this),
            _price
        );
    }

    //get listing fee
    function getListingFee() public view returns (uint256) {
        return LISTING_FEE;
    }

    //get listed NFTs from the marketplace
    function getListedNFTs() public view returns (NFT[] memory) {
        uint256 nftCount = _nftsCount.current();
        uint256 unsoldNFTsCount = nftCount - _nftsSold.current();

        NFT[] memory nfts = new NFT[](unsoldNFTsCount);
        uint256 nftsIndex = 0;
        for (uint256 i = 0; i < nftCount; i++) {
            if (_idToNFT[i + 1].listed) {
                nfts[nftsIndex] = _idToNFT[i + 1];
                nftsIndex++;
            }
        }
        return nfts;
    }

    //get NFTs from users account
    function getMyNFTs() public view returns (NFT[] memory) {
        uint256 nftCount = _nftsCount.current();
        uint256 myNFTCount = 0;
        for (uint256 i = 0; i < nftCount; i++) {
            if (_idToNFT[i + 1].owner == msg.sender) myNFTCount++;
        }

        NFT[] memory nfts = new NFT[](myNFTCount);
        uint256 nftIndex = 0;
        for (uint256 i = 0; i < myNFTCount; i++) {
            if (_idToNFT[i + 1].seller == msg.sender && _idToNFT[i + 1].listed)
                nfts[nftIndex++] = _idToNFT[i + 1];
        }
        return nfts;
    }

    //get NFT's listed on Marketplace from user's account

    function getMyListedNFTs() public view returns (NFT[] memory) {
        uint256 nftCount = _nftsCount.current();
        uint256 myListedNFTCount = 0;
        for (uint256 i = 0; i < nftCount; i++) {
            if (_idToNFT[i + 1].seller == msg.sender && _idToNFT[i + 1].listed)
                myListedNFTCount++;
        }

        NFT[] memory nfts = new NFT[](myListedNFTCount);

        uint256 nftIndex = 0;

        for (uint256 i = 0; i < nftCount; i++) {
            if (_idToNFT[i + 1].seller == msg.sender && _idToNFT[i + 1].listed)
                nfts[nftIndex++] = _idToNFT[i + 1];
        }

        return nfts;
    }
}
