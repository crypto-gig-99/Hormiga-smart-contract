// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IMATAccessManager {
    function isBornAllowed(address _caller, uint256 _gene)
        external
        view
        returns (bool);

    function isEvolveAllowed(
        address _caller,
        uint256 _gene,
        uint256 _nftId
    ) external view returns (bool);

    function isBreedAllowed(
        address _caller,
        uint256 _nftId1,
        uint256 _nftId2
    ) external view returns (bool);

    function isDestroyAllowed(address _caller, uint256 _nftId)
        external
        view
        returns (bool);
}
