Forked from the [original](https://github.com/tinchoabbate/damn-vulnerable-defi) repo built by [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz), this repository will contain my solutions and explanations for each challenge, in it's respective file.

[Unstoppable](#unstopabble)
[Naive Receiver](#naive-receiver)

## UNSTOPPABLE

If you're like me, your first instinct might be to drain the `pool`. 
However, as you read through the contracts, you'll hopefully realize that there's a much easier way to stop the `pool` from giving out `flashloans`.

Let's start with the `ReceiverUnstoppable` contract. It has two functions `receiveTokens(...)` which, as the comment says, will be called during the execution of the `executeFlashLoan(...)` function. Looking at the `executeFlashLoan(...)` function, we can see that it must be called by the `owner` and that it will in turn call the `flashLoan(...)` function of the `UnstoppableLender` contract, so let's go to that function.
The `flashLoan(...)` function first checks that the loan amount is higher than 0 but not greater than the pool token balance. It then checks that the `poolBalance` value corresponds to the actual amount of tokens the pool has. Only after does it execute the flashloan and check that it has been repaid.

So, the `flashLoan(...)` function will revert in case the loan amount is invalid or the loan isn't repaid. These make sense. 
However it will fail in one extra scenario - if the actual amount of tokens in the pool differs from the stateful `poolBalance` value, which raises the question: where is the `poolBalance` value updated? 
It's in the `depositTokens(...)` function of the `pool`, which  was intended as the only way users would deposit tokens in the pool. But, considering our balance of `100 DVL` tokens, what's stopping us from using `transfer` to deposit `1 DVL` token in the pool? 

## NAIVE-RECEIVER

Ok, so we're told exactly what to do: Drain `FlashLoanReceiver` funds.
If you look at the contract is has three functions, but only `receiveEther(...)` actually does something - it receives the flashloan and pays it back. As the comment says, this function is called while the `NaiveReceiverLenderPool` contract `flashLoan(...)` function is executed. Let's take a look.

We can see that the `flashLoan(...)` function checks that there's enough ETH in the pool for the requested flashloan amount. Then, it checks that the borrower is a contract. Finally, it verifies if the flashloan plus the fixed fee of `1 ether` has been paid back.
Do you see the issue? The `borrower` is passed as a parameter! This means that we can say that the borrower is the `FlashLoanReceiver` contract and request a flashloan of `0 ether`, which will cost the `FlashLoanReceiver` `1 ether` in fees. Do this enough times and the receiver is drained!

To do this in one transaction, we just need to deploy a contract that does the attack for us. You'll find the `Attacker` contract in the same folder as the other challenge contracts.

###### kyrers
