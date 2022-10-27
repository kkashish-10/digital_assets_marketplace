//SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter; // attach every function from library Counters to type Counters.Counter
    Counters.Counter private _nftsSold;
    Counters.Counter private _nftsCount;

    uint256 public LISTING_FEE = 0.001 ether;
    address payable private _marketOwner;
    mapping(uint256 => NFT) private _idToNFT;

    // NFT structure with instance variables
    struct NFT {
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool listed;
    }

    event NFTListed(
        address nftContract,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price
    );

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

    /**
    @notice Explain to an end user what this does
    @dev Explain to a developer any extra details
    @param _nftContract a parameter just like in doxygen (must be followed by parameter name)
    @param _tokenId a
    @param _price price for the NFT
    */
    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        require(_price > 0, "Price must be atleast 1 wei");
        require(msg.value == LISTING_FEE, "Not enought ether for listing fee");
        IERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

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

    //buy an NFT
    function buyNFT(address _nftContract, uint256 _tokenId)
        public
        payable
        nonReentrant
    {
        NFT storage nft = _idToNFT[_tokenId];
        require(
            msg.value >= nft.price,
            "Not enought ether to cover asking price"
        );
        address payable buyer = payable(msg.sender);
        payable(nft.seller).transfer(msg.value);
        IERC721(_nftContract).safeTransferFrom(
            address(this),
            buyer,
            nft.tokenId
        );
        _marketOwner.transfer(LISTING_FEE);
        nft.owner = buyer;
        nft.listed = false;

        _nftsSold.increment();
        emit NFTSold(_nftContract, nft.tokenId, nft.seller, buyer, msg.value);
    }

    //Resell an NFT purchased from the marketplace
    function resellNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        require(_price > 0, "Price must be atleast 1 wei");
        require(msg.value == LISTING_FEE, "Not enough ether for listing fee.");
        IERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

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
