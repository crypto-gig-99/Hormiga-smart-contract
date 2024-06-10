// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NativeToken is ERC20, Ownable {    

    constructor() ERC20("NativeToken", "Native") {
        _mint(
            msg.sender, 
            100000000000000000000000000
        );
    }
}
