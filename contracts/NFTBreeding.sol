// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC/ERC721/ERC721.sol";
import "./ERC/ERC721/IERC721.sol";
import "./access/Ownable.sol";
import "./proxy/ERC721TransferProxy.sol";
import "./lifecycle/Pausable.sol";
import "./ERC/ERC20/IBEP20.sol";
import "./security/ReentrancyGuard.sol";
import "./ERC/ERC20/SafeBEP20.sol";
    
/// @title A Breeding contract for NFT
/// @author Topbot-dev

contract BreedNFT is ERC721, Pausable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;

    IBEP20 public immutable nativeToken;
    uint256 public nftPrice = 0.25 ether;
    uint256 public currentId;
    bool public isPublic;

    struct BreedToken {
        uint256[] parent;
        uint256 bornAt;
    }

    mapping(address => bool) whitelist;
    mapping(uint256 => BreedToken) breedTokens;
    mapping(uint256 => bool) isParent;

    event Breed(
        address indexed caller,
        address indexed to,
        uint256 indexed newNftId,
        uint256[] parent,
        uint256 time
    );

    constructor(address _nativeToken) ERC721("Name", "Symbol") {
        currentId = 1;
        nativeToken = IBEP20(_nativeToken);
    }

    function setWhitelist(address _account, bool _isWhitelist)
        public
        onlyOwner
    {
        require(
            _account != address(0),
            "ERROR-setWhitelist: Invalid Account Address!"
        );
        whitelist[_account] = _isWhitelist;
    }

    function setPublic(bool _isPublic) public onlyOwner {
        isPublic = _isPublic;
    }

    function setPrice(uint256 _price) public onlyOwner {
        nftPrice = _price;
    }

    function buy(address _toAddress) public nonReentrant {
        require(
            isWhitelisted(_msgSender()),
            "Not have born permisison"
        );
        uint256 _nftId = currentId;

        nativeToken.safeTransferFrom(_msgSender(), address(this), nftPrice);
        _mint(_toAddress, _nftId);

        currentId = currentId + 1;
        // return _nftId;
    }

    function breed(address _toAddress, uint256[] memory _parent)
        public
        nonReentrant
        returns (uint256)
    {
        require(isWhitelisted(_msgSender()), "ERROR-breed: Not Whitelisted");
        require(_parent.length == 6, "ERROR-breed: Parents Number Incorrect");
        for (uint256 index = 0; index < _parent.length; index++) {
            require(
                _exists(_parent[index]) && ownerOf(_parent[index]) == _msgSender(),
                "ERROR-breed: Parent Not Exist"
            );
            require(
                !isParent[_parent[index]],
                "ERROR-breed: Already Taken as Parent"
            );
        }

        uint256 _nftId = currentId;
        _mint(_toAddress, _nftId);

        breedTokens[_nftId] = BreedToken(_parent, block.timestamp);

        for (uint256 index = 0; index < _parent.length; index++) {
            isParent[_parent[index]] = true;
        }

        emit Breed(_msgSender(), _toAddress, _nftId, _parent, block.timestamp);

        currentId = currentId + 1;

        return _nftId;
    }

    function isWhitelisted(address _account) public view returns (bool) {
        require(
            _account != address(0),
            "ERROR-isWhitelisted: Invalid Account Address!"
        );
        return isPublic || whitelist[_account];
    }

    function exists(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }

    function get(uint256 _nftId)
        external
        view
        returns (
            address,
            uint256[] memory,
            uint256
        )
    {
        return (
            ownerOf(_nftId),
            breedTokens[_nftId].parent,
            breedTokens[_nftId].bornAt
        );
    }
}
