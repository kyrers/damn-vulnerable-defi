Forked from the [original](https://github.com/tinchoabbate/damn-vulnerable-defi) repo built by [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz), this repository will contain my solutions and explanations for each challenge, in it's respective file.

[Unstoppable](#unstopabble)

[Naive Receiver](#naive-receiver)

[Truster](#truster)

[Side Entrance](#side-entrance)

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

## TRUSTER

So far, this is the most to the point challenge. We have to drain `1000000 DVL` from the `TrusterLenderPool`. 

Looking at the `flashloan(...)` function we immediately see that it has two strange parameters: `address target` and `bytes calldata data`. Examining further we find that this is a classic flashloan function except that before checking that the loan is repaid, it unexpectedly calls the `target` address using the `data` parameters. Well, this is obviously our way in. 

Since no checks are performed, we can simply say that we want to borrow `0 DVL` tokens, the `target` is the `DVL` token contract and that the `data` is a call to the `approve(...)` function, which allows us to approve a transfer from the pool to ourselves of any amount of the pool `DVL` tokens.
So two transactions are needed: one to call `flashloan(...)` in order to sneak in that `approve(...)` transaction, and another to `transferFrom()` to send the `DVL`tokens to ourselves.

To do this in one transaction, we just need to deploy a contract that does the attack for us. You'll find the `TrusterAttacker` contract in the same folder as the other challenge contracts.

## SIDE-ENTRANCE

Once again, we have a `1000 ether` pool that provides free flashloans. Our job is to drain the pool.

Looking at the `SideEntranceLenderPool` contract we can see that it allows users to `deposit` and `withdraw` funds from the pool. Of course, it also allows us to use the `flashloan(...)` function to request a flashloan.

Aside from repaying the flashloan, this `flashloan(...)` function also requires that the borrower implement the `IFlashLoanEtherReceiver` interface, which has the function `execute()` responsible for handling the flashloan funds.

So one thing is for sure, we need to implement an attacker contract that ask for the flashloan and receives it in the `execute()` function. But what do we do with it? Remember the `deposit(...)` and `withdraw(...)` functions? We just `deposit` the funds back in the pool, which will make the flashloan successful and set the funds as the property of our attacker contract, which in turn means we can `withdraw` those funds from the pool. All that's left to do is send the withdrawn funds from our contract to our wallet.


###### kyrers
