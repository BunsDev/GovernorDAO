
// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';

contract SynLPToken is ERC20, ERC20Burnable {
    string public name;
    string public symbol;
    uint8 public decimals;
    constructor() public {
        name = "synthetic GDAO-ETH LP V2";
        symbol = "sLP";
        decimals = 18;
        _mint(msg.sender, 6710*1e18);
    }
}