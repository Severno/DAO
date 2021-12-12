// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";

contract ERC20 is IERC20Interface {
    string private _name;
    string private _symbol;

    uint256 private _totalSupply;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint256)
    {
        return _balances[tokenOwner];
    }

    function transfer(address to, uint256 value)
        external
        payable
        override
        returns (bool success)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(from, to, amount);

        uint256 currentAllowance = _allowances[from][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );

        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[tokenOwner][spender];
    }

    function _transfer(
        address sender,
        address to,
        uint256 amount
    ) internal {
        uint256 senderBalance = _balances[sender];

        require(
            senderBalance >= amount,
            "ERC20: Transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        _balances[to] += amount;

        emit Transfer(sender, to, amount);
    }

    function _approve(
        address from,
        address to,
        uint256 amount
    ) internal {
        _allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }
}
