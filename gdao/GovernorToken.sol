// contracts/GovernorToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Burnable.sol";

contract GovernorToken is ERC20, ERC20Burnable {
    string public name;
    string public symbol;
    uint8 public decimals;
    constructor() public {
        name = "Governor";
        symbol = "GDAO";
        decimals = 18;
        _mint(msg.sender, 3000000*1e18);
    }
}