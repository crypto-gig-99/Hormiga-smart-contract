// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HMGNFTMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private itemIds;
    Counters.Counter private itemsSold;

    address payable public owner;
    address public immutable NFTToken;
    address public immutable nativeToken;
    address public immutable tokenPool;
    uint256 private totalFEVDeposited;
    uint256 private totalFERDeposited;

    constructor(
        address _NFTToken,
        address _nativeToken,
        address _tokenPool
    ) {
        owner = payable(msg.sender);
        NFTToken = _NFTToken;
        nativeToken = _nativeToken;
        tokenPool = _tokenPool;
    }

    struct MarketItem {
        uint256 tokenId;
        uint256 fevValue;
        uint256 ferValue;
        uint256 timeLimit;
        string origin;
        address holder;
        address carrier;
        string destination;
        address recipient;
        bool isActive;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed _itemId,
        uint256 indexed _tokenId,
        string _origin,
        string _destination,
        address _recipient,
        uint256 _price,
        bool _isActive
    );

    function createMarketItem(
        uint256 _tokenId,
        uint256 _fevValue,
        uint256 _ferValue,
        uint256 _timeLimit,
        string memory _origin,
        string memory _destination,
        address _recipient
    ) public nonReentrant {
        require(_fevValue > 0, "ERROR-createMarketItem: Invalid fev value.");
        require(_ferValue > 0, "ERROR-createMarketItem: Invalid fer value.");
        require(
            IERC721(NFTToken).ownerOf(_tokenId) == msg.sender,
            "ERROR-createMarketItem: Should  be owner account of this token"
        );
        require(
            _timeLimit > block.timestamp,
            "ERROR-createMarketItem: Invalid time limit."
        );

        itemIds.increment();
        uint256 _itemId = itemIds.current();

        IERC20(nativeToken).transferFrom(
            msg.sender,
            address(this),
            _fevValue + _ferValue
        );
        IERC721(NFTToken).transferFrom(msg.sender, address(this), _tokenId);

        idToMarketItem[_itemId] = MarketItem(
            _tokenId,
            _fevValue,
            _ferValue,
            _timeLimit,
            _origin,
            msg.sender,
            address(0),
            _destination,
            _recipient,
            true
        );

        totalFEVDeposited += _fevValue;
        totalFERDeposited += _ferValue;
    }

    function reClaimMarketItem(
        uint256 _itemId,
        uint256 _fevValue,
        uint256 _ferValue,
        uint256 _timeLimit,
        string memory _origin,
        string memory _destination,
        address _recipient
    ) public nonReentrant {
        require(
            idToMarketItem[_itemId].isActive == false,
            "ERROR-reClaimMarketItem: Already on Sale for transport."
        );

        // owner of token should be message sender

        uint256 _price = idToMarketItem[_itemId].fevValue +
            idToMarketItem[_itemId].ferValue;
        IERC20(nativeToken).transfer(idToMarketItem[_itemId].holder, _price);

        uint256 _price1 = _fevValue + _ferValue;
        if (_price1 > idToMarketItem[_itemId].fevValue) {
            IERC20(nativeToken).transferFrom(
                msg.sender,
                address(this),
                _price1 - idToMarketItem[_itemId].fevValue
            );
        } else {
            IERC20(nativeToken).transfer(
                msg.sender,
                idToMarketItem[_itemId].fevValue - _price1
            );
        }

        IERC721(NFTToken).transferFrom(
            msg.sender,
            address(this),
            idToMarketItem[_itemId].tokenId
        );

        totalFEVDeposited =
            totalFEVDeposited -
            2 *
            idToMarketItem[_itemId].fevValue +
            _fevValue;
        totalFERDeposited =
            totalFERDeposited -
            idToMarketItem[_itemId].ferValue +
            _ferValue;

        MarketItem storage reclaimItem = idToMarketItem[_itemId];
        reclaimItem.isActive = true;
        reclaimItem.fevValue = _fevValue;
        reclaimItem.ferValue = _ferValue;
        reclaimItem.timeLimit = _timeLimit;
        reclaimItem.holder = msg.sender;
        reclaimItem.carrier = address(0);
        reclaimItem.origin = _origin;
        reclaimItem.destination = _destination;
        reclaimItem.recipient = _recipient;
    }

    function createMarketSale(uint256 _itemId) public nonReentrant {
        require(
            idToMarketItem[_itemId].isActive == true,
            "ERROR-createMarketSale: Already Sold for transport."
        );
        uint256 _price = idToMarketItem[_itemId].fevValue;

        uint256 _tokenId = idToMarketItem[_itemId].tokenId;

        IERC20(nativeToken).transferFrom(msg.sender, address(this), _price);

        IERC721(NFTToken).transferFrom(address(this), msg.sender, _tokenId);

        totalFEVDeposited = totalFEVDeposited + _price;

        idToMarketItem[_itemId].carrier = msg.sender;

        idToMarketItem[_itemId].isActive = false;

        itemsSold.increment();
    }

    function recipientApprove(uint256 _item_id) external nonReentrant {
        require(
            idToMarketItem[_item_id].recipient == msg.sender,
            "ERROR-recipientApprove: Invalid Recipient"
        );

        if (idToMarketItem[_item_id].timeLimit > block.timestamp) {
            IERC20(nativeToken).transferFrom(
                msg.sender,
                idToMarketItem[_item_id].holder,
                idToMarketItem[_item_id].fevValue
            );
            IERC20(nativeToken).transfer(
                idToMarketItem[_item_id].holder,
                idToMarketItem[_item_id].fevValue
            );
            IERC20(nativeToken).transfer(
                idToMarketItem[_item_id].carrier,
                idToMarketItem[_item_id].fevValue +
                    idToMarketItem[_item_id].ferValue
            );
        } else {
            IERC20(nativeToken).transfer(
                idToMarketItem[_item_id].holder,
                idToMarketItem[_item_id].fevValue +
                    idToMarketItem[_item_id].ferValue
            );
            IERC20(nativeToken).transfer(
                idToMarketItem[_item_id].carrier,
                idToMarketItem[_item_id].fevValue
            );
        }
        totalFEVDeposited =
            totalFEVDeposited -
            2 *
            idToMarketItem[_item_id].fevValue;
        totalFERDeposited =
            totalFERDeposited -
            idToMarketItem[_item_id].ferValue;
    }

    function recipientDeny(uint256 _item_id) external nonReentrant {
        require(
            idToMarketItem[_item_id].recipient == msg.sender,
            "ERROR-recipientApprove: Invalid Recipient"
        );

        IERC20(nativeToken).transfer(
            idToMarketItem[_item_id].carrier,
            idToMarketItem[_item_id].fevValue
        );
        
        totalFEVDeposited =
            totalFEVDeposited -
            idToMarketItem[_item_id].fevValue;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 _totalItemCount = itemIds.current();
        uint256 _itemCount = 0;
        uint256 _currentIndex = 0;

        for (uint256 i = 0; i < _totalItemCount; i++) {
            if (idToMarketItem[i + 1].holder == msg.sender) {
                _itemCount += 1;
            }
        }

        MarketItem[] memory _items = new MarketItem[](_itemCount);
        for (uint256 i = 0; i < _totalItemCount; i++) {
            if (idToMarketItem[i + 1].holder == msg.sender) {
                uint256 _currentId = i + 1;
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
            if (idToMarketItem[i + 1].holder == msg.sender) {
                _itemCount += 1;
            }
        }
        MarketItem[] memory _items = new MarketItem[](_itemCount);
        for (uint256 i = 0; i < _totalItemCount; i++) {
            uint256 _currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[_currentId];
            _items[_currentIndex] = currentItem;
            _currentIndex += 1;
        }
        return _items;
    }    

    function getTotalFev() public view returns (uint256) {
        require(msg.sender == owner, "ERROR-getTotalFev: Only Owner call this!");
        return totalFEVDeposited;
    }

    function getTotalFer() public view returns (uint256) {
        require(msg.sender == owner, "ERROR-getTotalFev: Only Owner call this!");
        return totalFERDeposited;
    }
}
