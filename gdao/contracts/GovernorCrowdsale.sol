// contracts/GovernorCrowdsale.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/access/roles/CapperRole.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/TimedCrowdsale.sol";


contract GovernorCrowdsale is CappedCrowdsale, TimedCrowdsale, CapperRole {

    using SafeMath for uint256;

    mapping(address => uint256) private _contributions;
    mapping(address => uint256) private _caps;
    mapping(address => bool) private whitelist;
    
    uint256 private _individualDefaultCap;

constructor (
    uint256 rate,
    address payable wallet,
    IERC20 token,
    uint256 openingTime,
    uint256 closingTime,
    uint256 cap,
    uint256 individualCap
    ) 
    public 
    Crowdsale(rate, wallet, token)
    TimedCrowdsale(openingTime, closingTime)
    CappedCrowdsale(cap)
    {
         _individualDefaultCap = individualCap;
    }

    /**
     * @dev Sets a specific beneficiary's maximum contribution.
     * @param beneficiary Address to be capped
     * @param cap Wei limit for individual contribution
     */
    function setCap(address beneficiary, uint256 cap) external onlyCapper {
        _caps[beneficiary] = cap;
    }
    
    /**
     * @dev Adds addresseto whitelist.
     * @param beneficiary Address list to whitelist
     */
    function addWhitelist(address beneficiary) external onlyCapper{
        whitelist[beneficiary] = true;
    }

    /**
     * @dev Adds multipled addresses to whitelist.
     * @param beneficiary Address list to whitelist
     */
    function addManyWhitelist(address[] calldata beneficiary) external onlyCapper{
        for (uint i = 0; i < beneficiary.length; i++){
            whitelist[beneficiary[i]] = true;
        }
    }

    /**
     * @dev Removes address from whitelist.
     * @param beneficiary Address to remove from whitelist
     */
    function removeWhitelist(address beneficiary) external onlyCapper{
        whitelist[beneficiary] = false;
    }

    /**
     * @dev Returns if address is whitelisted.
     * @param beneficiary Address whose whitelist status is checked
     * @return true if whitelisted, false if not
     */
    function isWhitelisted(address beneficiary) public view returns (bool){
        return whitelist[beneficiary] == true;
    }

    /**
     * @dev Returns the cap of a specific beneficiary.
     * @param beneficiary Address whose cap is to be checked
     * @return Current cap for individual beneficiary
     */
    function getCap(address beneficiary) public view returns (uint256) {
        uint256 cap = _caps[beneficiary];
        if (cap == 0) {
            cap = _individualDefaultCap;
        }
        return cap;
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary) public view returns (uint256) {
        return _contributions[beneficiary];
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        // solhint-disable-next-line max-line-length
        require(whitelist[beneficiary], "Governor LGE: Address not whitelisted");
        require(_contributions[beneficiary].add(weiAmount) <= getCap(beneficiary), "Governor LGE: beneficiary's cap exceeded");
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    }
}
