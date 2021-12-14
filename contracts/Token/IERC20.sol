// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Interface {
    /**
     * @dev Returns the number of existing tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token's name - e.g. "MyToken".
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token's symbol  - e.g. "CRG".
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Allows 'spender' to withdraw from your account multiple times, up to the 'value' amount.
     * If this function is called again it overwrites the current allowance with 'value'.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the recipient account balance.
     */
    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    /**
     * @dev Transfers 'amount' amount of tokens to address 'to', and MUST fire the Transfer event.
     * The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
     */
    function transfer(address to, uint256 amount)
        external
        payable
        returns (bool _success);

    /**
     * @dev Transfers 'amount' amount of tokens from address 'from' to address 'to', and MUST fire the Transfer event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the amount which 'spender' is still allowed to withdraw from 'owner'.
     */
    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev MUST trigger when tokens are transferred, including zero value transfers.
     * A token contract which creates new tokens SHOULD trigger a Transfer event with the 'from' address set to 0x0 when tokens are created.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev MUST trigger on any successful call to approve(address spender, uint256 value).
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}
