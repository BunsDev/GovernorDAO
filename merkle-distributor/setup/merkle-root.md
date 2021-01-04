# Merkle Root

### Generate Merkle Root

Now, you have your dependencies, so you will be able to run a simple test to ensure the current inputs generate a merkle root you will then verify. **Run the following command to generate the merkle root.**

```bash
$ yarn generate:example
```

{% hint style="info" %}
For a quick primer on Cryptographic Hash Functions visit my post [here](https://soliditywiz.medium.com/cryptographic-hash-function-beaa2408260).
{% endhint %}

### Test Merkle Root

After generating the merkle root, be sure to save the results in a file named result\_example.json. This has already been done for you, but it is encouraged to practice doing this for yourself to ensure it works as you understand it should. After storing your results in a .json, **run the following command to verify that the root contains the claims** listed in the claims\_example.json.

```bash
$ yarn verify:example
```

{% hint style="info" %}
Recommend reviewing the structural design underlying Merkle Trees: [here](https://soliditywiz.medium.com/merkle-hash-trees-explained-ea384f2af7e8).
{% endhint %}

