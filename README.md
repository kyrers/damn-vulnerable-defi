Forked from the [original](https://github.com/tinchoabbate/damn-vulnerable-defi) repo built by [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz), this repository will contain my solutions and explanations for each challenge, in it's respective file.

[Unstoppable](#unstopabble)

[Naive Receiver](#naive-receiver)

[Truster](#truster)

[Side Entrance](#side-entrance)

[Rewarder](#rewarder)

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

## REWARDER

The first challenge where things get more complex. However, there are several tips in the challenge description which will provide us with a path to find the exploit.

First we find out that there's a pool offering rewards in 5 day increments to users that deposit `DVL` tokens. We also discover that we have no `DVL` tokens, but that there's a pool offering free flashloans. 

Let's look at the `FlashLoanPool` `flashloan(...)` function. It requires that the borrower is a deployed contract with the `receiveFlashLoan(uint256)` function to handle the flashloan. 
We now have a way of getting the `DVL` tokens, but how do we use them in regards to `TheRewarderPool`?

Looking at the pool the first thing we notice is that it uses three tokens: `LiquidityToken`, `AccountingToken` and `RewardToken`. Again, from the challenge description it becomes obvious that we need to get some `RewardToken` tokens. 

It seems that the only way to mint `RewardToken` is inside the `distributeRewards(...)` function. To execute that code, the function checks that `rewards > 0 && !_hasRetrievedReward(msg.sender)`. Let's find a way to pass this verification.

`hasRetrievedReward(msg.sender)` will return false if we have never received a reward, which is true in our case - easy. `rewards` will be greater than 0 if we have a positive balance of `AccountingToken` tokens considering the last snapshot taken. Ok, so how do we get a positive balance of `AccountingToken` and our snapshot taken?

Snapshots are taken earlier in the `distributeRewards(...)` function execution via a call to `_recordSnapshot()`. However, to execute this call we need to pass the verification `isNewRewardsRound()` which checks that at least 5 days have passed since the last snapshot. This means that we need to wait 5 days before calling `distributeRewards(...)`.

That was easy, but we still need to figure out how to get a positive balance of `AccountingToken`. Looking at the pool we see that `AccountingToken` are minted in the `deposit(...)` function, in proportion to the deposited `LiquidityToken` which is the `DVL` token. We also see that `AccountingToken` are burned in the `withdraw(...)` function which, in addition to sending us our `RewardToken`, sends the `DVL` tokens back to us - allowing us to pay the flashloan.

We know have a clear picture of how to get `RewardToken`, and since we already know how to get our hands in free `DVL` tokens, we have all the information we need.

Let's recap what we know:
1. We know we have to get some amount of `RewardToken` to pass the challenge;
2. The only place where `RewardToken` is minted is in the `TheRewarderPool` `distributeRewards(...)` function;
3. To be able to reach that place of the code, the function needs that the caller:
    - Have a positive balance of `AccountingToken` since the last snapshot;
    - Have never received a reward;
4. To clear the verifications in the previous step, we need to:
    - Wait 5 days;
    - Deposit DVL tokens in the pool;
5. We have no DVL tokens, but we know how to get them for free provided we pay them back - which we can, since we can call the pool `withdraw(...)` function which will give us our `DVL` tokens back after we have successfully gotten our `RewardToken` rewards;

All that's left is implementing a `RewardAttacker` contract that does all the above for us.


###### kyrers
