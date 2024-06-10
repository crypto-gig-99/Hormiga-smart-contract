// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IMarketAccessManager.sol";
import "./Ownable.sol";

contract MarketAccessManager is IMarketAccessManager, Ownable {
    bool listingPublicAll;

    mapping(address => bool) listingWhilelist;

    function setListingWhilelist(address _to, bool _isWhilelist)
        public
        onlyOwner
    {
        listingWhilelist[_to] = _isWhilelist;
    }

    function setListingPublicAll(bool _listingPublicAll) public onlyOwner {
        listingPublicAll = _listingPublicAll;
    }

    function isListingAllowed(address _caller)
        external
        view
        override
        returns (bool)
    {
        return listingPublicAll || listingWhilelist[_caller];
    }
}
