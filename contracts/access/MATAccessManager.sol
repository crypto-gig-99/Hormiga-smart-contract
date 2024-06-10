// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IMATAccessManager.sol";
import "./Ownable.sol";

contract MATAccessManager is IMATAccessManager, Ownable {
    bool publicAll;
    bool bornPublicAll;
    bool evolvePublicAll;
    bool breedPublicAll;
    bool destroyPublicAll;

    mapping(address => bool) bornWhilelist;
    mapping(address => bool) evolveWhilelist;
    mapping(address => bool) breedWhilelist;
    mapping(address => bool) destroyWhilelist;

    function setPublicAll(bool _publicAll) public onlyOwner {
        publicAll = _publicAll;
    }

    function setBornWhilelist(address _to, bool _isWhilelist) public onlyOwner {
        bornWhilelist[_to] = _isWhilelist;
    }

    function setEvolveWhilelist(address _to, bool _isWhilelist)
        public
        onlyOwner
    {
        evolveWhilelist[_to] = _isWhilelist;
    }

    function setBreedWhilelist(address _to, bool _isWhilelist)
        public
        onlyOwner
    {
        breedWhilelist[_to] = _isWhilelist;
    }

    function setDestroyWhilelist(address _to, bool _isWhilelist)
        public
        onlyOwner
    {
        destroyWhilelist[_to] = _isWhilelist;
    }

    function setBornPublicAll(bool _bornPublicAll) public onlyOwner {
        bornPublicAll = _bornPublicAll;
    }

    function setEvolvePublicAll(bool _evolvePublicAll) public onlyOwner {
        evolvePublicAll = _evolvePublicAll;
    }

    function setBreedPublicAll(bool _breedPublicAll) public onlyOwner {
        breedPublicAll = _breedPublicAll;
    }

    function setDestroyPublicAll(bool _destroyPublicAll) public onlyOwner {
        destroyPublicAll = _destroyPublicAll;
    }

    function isBornAllowed(address _caller, uint256 _gene)
        external
        view
        override
        returns (bool)
    {
        //TODO: can check _gene validation
        return publicAll || bornPublicAll || bornWhilelist[_caller];
    }

    function isEvolveAllowed(
        address _caller,
        uint256 _gene,
        uint256 _nftId
    ) external view override returns (bool) {
        //TODO: can check _gene and _nftId validation
        return publicAll || bornPublicAll || evolveWhilelist[_caller];
    }

    function isBreedAllowed(
        address _caller,
        uint256 _nftId1,
        uint256 _nftId2
    ) external view override returns (bool) {
        //TODO: can check _gene and _nftId validation
        return publicAll || bornPublicAll || breedWhilelist[_caller];
    }

    function isDestroyAllowed(address _caller, uint256 _nftId)
        external
        view
        override
        returns (bool)
    {
        //TODO: can check _gene and _nftId validation
        return publicAll || bornPublicAll || destroyWhilelist[_caller];
    }
}
