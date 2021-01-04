# New Addresses

### Adding: New Addresses

Take note of the new addresses we will manually input upon deployment that are publicly viewable:

{% code title="MerkleDistributor.sol" %}
```javascript
contract MerkleDistributor is IMerkleDistributor {
    using SafeMath for uint256;
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    address public immutable override rewardsAddress;
    address public immutable override burnAddress;
```
{% endcode %}

{% hint style="info" %}
 Note: in order to prevent burning tokens in error, the burnAddress is a multisig address in lieu of  burning tokens directly from the contract itself. This requires trust from your community.
{% endhint %}

### 

