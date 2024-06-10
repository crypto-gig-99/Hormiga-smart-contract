// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract HMGNFT is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public price = 10 ether;
    uint256 public maxSupply = 5000;
    address public immutable tokenContract;
    address public tokenPool;
    address public marketplace;
    mapping(uint256 => bool) private revealed;

    //Remit Hormiga token
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _tokenContract,
        address _tokenPool,
        address _marketplace
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        _mint(msg.sender, 1);
        tokenPool = _tokenPool;
        tokenContract = _tokenContract;
        marketplace = _marketplace;
    }

    //internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //public

    function mint(
        address _to,
        uint256 _mintAmount,
        uint256 _payAmount
    ) public whenNotPaused {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);
        if (msg.sender != owner()) {
            require(_payAmount >= price * _mintAmount);
            require(
                IERC20(tokenContract).transferFrom(
                    msg.sender,
                    tokenPool,
                    _payAmount
                ),
                "ERROR-mint: cannot transfer the native token"
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            revealed[supply + i] = true;
        }
        _setApprovalForAll(msg.sender, marketplace, true);
    }

    function destroy(uint256 _nftId) external {
        require(msg.sender == ownerOf(_nftId), "ERROR: Invalid Address");
        _burn(_nftId);
    }

    function setMarketAddress(address _market) external onlyOwner {
        require(
            _market != address(0),
            "ERROR-setMarketAddress: Invalid Address"
        );
        marketplace = _market;
    }

    function setPoolAddress(address _pool) external onlyOwner {
        require(
            _pool != address(0),
            "ERROR-setMarketAddress: Invalid Address"
        );
        tokenPool = _pool;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        if (revealed[tokenId]) {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            baseExtension
                        )
                    )
                    : "";
        } else {
            return "";
        }
    }

    //only owner

    function setPrice(uint256 _newCost) public onlyOwner {
        price = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw(uint256 withdrawAmount_) public payable onlyOwner {
        require(payable(msg.sender).send(withdrawAmount_));
    }
}
