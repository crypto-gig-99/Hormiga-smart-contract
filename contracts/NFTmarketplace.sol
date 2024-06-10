// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private itemIds;
    Counters.Counter private itemsSold;

    address payable public owner;
    address public immutable NFTToken;

    constructor(address _NFTToken) {
        owner = payable(msg.sender);
        NFTToken = _NFTToken;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice(uint256 _price) internal pure returns (uint256) {
        require(
            _price > 0,
            "Error: The price is zero.Cannot get the listing price"
        );
        return (_price * 2) / 100;
    }

    function createMarketItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        require(_price > 0, "Price must be at least 1 wei");
        require(
            msg.value == getListingPrice(_price),
            "Price must be equal to listing price"
        );

        itemIds.increment();
        uint256 _itemId = itemIds.current();
        idToMarketItem[_itemId] = MarketItem(
            _itemId,
            _nftContract,
            _tokenId,
            payable(msg.sender),
            payable(address(0)),
            _price,
            false
        );
        uint256 _listingPrice = getListingPrice(_price);
        payable(owner).transfer(_listingPrice);
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
    }

    function createMarketSale(address _nftContract, uint256 _itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[_itemId].price;
        uint256 _tokenId = idToMarketItem[_itemId].tokenId;
        require(
            msg.value == price,
            "Please submit the asking price in order to coomplete the purchase"
        );

        idToMarketItem[_itemId].seller.transfer(msg.value);
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        idToMarketItem[_itemId].owner = payable(msg.sender);
        idToMarketItem[_itemId].sold = true;
        itemsSold.increment();
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 _itemCount = itemIds.current();
        uint256 _unsoldItemCount = itemIds.current() - itemsSold.current();
        uint256 _currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](_unsoldItemCount);
        for (uint256 i = 0; i < _itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 _currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage _currentItem = idToMarketItem[_currentId];
                items[_currentIndex] = _currentItem;
                _currentIndex += 1;
            }
        }
        return items;
    }

    function fectchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 _totalItemCount = itemIds.current();
        uint256 _itemCount = 0;
        uint256 _currentIndex = 0;

        for (uint256 i = 0; i < _totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                _itemCount += 1;
            }
        }

        MarketItem[] memory _items = new MarketItem[](_itemCount);
        for (uint256 i = 0; i < _totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 _currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[_currentId];
                _items[_currentIndex] = currentItem;
                _currentIndex += 1;
            }
        }
        return _items;
    }

    function fetchItemCreated() public view returns (MarketItem[] memory) {
        uint256 _totalItemCount = itemIds.current();
        uint256 _itemCount = 0;
        uint256 _currentIndex = 0;

        for (uint256 i = 0; i < _totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                _itemCount += 1;
            }
        }
        MarketItem[] memory _items = new MarketItem[](_itemCount);
        for (uint256 i = 0; i < _totalItemCount; i++) {
            uint256 _currentId = idToMarketItem[i + 1].itemId;
            MarketItem storage currentItem = idToMarketItem[_currentId];
            _items[_currentIndex] = currentItem;
            _currentIndex += 1;
        }
        return _items;
    }
}
