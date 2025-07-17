// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PumpToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_, address owner_) ERC20(name_, symbol_) Ownable(owner_) {
        _mint(owner_, initialSupply_);
    }
} 