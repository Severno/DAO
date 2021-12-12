// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

contract CRGToken is ERC20 {
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {
        _mint(msg.sender, _totalSupply * (10**_decimals));
    }
}
