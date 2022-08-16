Forked from the [original](https://github.com/tinchoabbate/damn-vulnerable-defi) repo built by [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz), this repository will contain my solutions and explanations for each challenge, in it's respective file.

[Unstoppable](#unstopabble)

## UNSTOPPABLE

If you're like me, your first instinct might be to drain the `pool`. 
However, as you read through the contracts, you'll hopefully realize that there's a much easier way to stop the `pool` from giving out `flashloans`.

Let's start with the `ReceiverUnstoppable` contract. It has two functions `receiveTokens(...)` which, as the comment says, will be called during the execution of the `executeFlashLoan(...)` function. Looking at the `executeFlashLoan(...)` function, we can see that it must be called by the `owner` and that it will in turn call the `flashLoan(...)` function of the `UnstoppableLender` contract, so let's go to that function.
The `flashLoan(...)` function first checks that the loan amount is higher than 0 but not greater than the pool token balance. It then checks that the `poolBalance` value corresponds to the actual amount of tokens the pool has. Only after does it execute the flashloan and check that it has been repaid.

So, the `flashLoan(...)` function will revert in case the loan amount is invalid or the loan isn't repaid. These make sense. 
However it will fail in one extra scenario - if the actual amount of tokens in the pool differs from the stateful `poolBalance` value, which raises the question: where is the `poolBalance` value updated? 
It's in the `depositTokens(...)` function of the `pool`, which  was intended as the only way users would deposit tokens in the pool. But, considering our balance of `100 DVL` tokens, what's stopping us from using `transfer` to deposit `1 DVL` token in the pool? 


###### kyrers
