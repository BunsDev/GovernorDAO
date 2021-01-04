# Time Constraints

### Adding: Time Constraints

The following uint256 values represent the predetermined start and end times associated with your contract. This is an optional step, but used in this instance to provide assurance that tokens will not remain in the contract forever as some will not ever claim for one reason or another.

{% code title="MerkleDistributor.sol" %}
```csharp
    uint256 public immutable startTime;
    uint256 public immutable endTime;
    uint256 internal immutable secondsInaDay = 86400;
```
{% endcode %}

{% hint style="info" %}
Note: seconds in a day is defined as the literal seconds in a day, but this may be configured to match your testing environment, for example, suppose 20mins represents one full day. This would require a full day to equal X number of seconds, which is 1,200 seconds in 20min days.
{% endhint %}

