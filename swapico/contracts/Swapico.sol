// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Swapico {

    address public immutable synthetico;
    address public immutable authentico;
    uint256 public immutable inicio;
    
    event purchased(address indexed _purchaser, uint256 indexed _tokens);
    
    constructor(address _synthetico, address _authentico, uint256 _inicio) public {
        synthetico = _synthetico;
        authentico = _authentico;
        inicio = _inicio;
    }
    
    function purchase(uint256 amount) public {
        require(block.timestamp >= inicio, 'purchase: too soon');
        require(IERC20(synthetico).balanceOf(address(msg.sender)) >= amount, 'purchase: insufficient balance');
        require(IERC20(authentico).balanceOf(address(this)) >= amount, 'purchase: insufficient liquidity');
        _purchase(amount);
    }
    
    function _purchase(uint256 _amount) internal {
        IERC20(synthetico).burnFrom(msg.sender, _amount);
        IERC20(authentico).transfer(msg.sender, _amount);
        
        emit purchased(msg.sender, _amount);
    }
}
