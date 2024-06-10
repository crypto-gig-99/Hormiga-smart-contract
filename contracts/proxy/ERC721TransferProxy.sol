// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../access/Ownable.sol";
import "../ERC/ERC721/IERC721.sol";
import "../lifecycle/Pausable.sol";

contract ERC721TransferProxy is Ownable, Pausable {
    mapping(address => bool) whilelists;

    modifier onlyWhilelist() {
        require(
            whilelists[_msgSender()],
            "Error: only whilelist can call proxy"
        );
        _;
    }

    function setWhilelist(address _user, bool _isWhilelist) public onlyOwner {
        whilelists[_user] = _isWhilelist;
    }

    function erc721TransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external onlyWhilelist whenNotPaused {
        token.transferFrom(from, to, tokenId);
    }
}
