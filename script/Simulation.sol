// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/Coinflip.sol";
import "../src/CoinflipV2.sol";
import "../src/DauphineToken.sol";
import "../src/Proxy.sol";

contract Simulation is Script {
    address user1;
    address user2;

    Coinflip coinflip;
    DauphineToken dauphinetoken;

    function run() external {
        vm.startBroadcast();

        user1 = vm.addr(7689);
        user2 = vm.addr(7897);

        DauphineToken tokenImpl = new DauphineToken();

        bytes memory tokenInitData = abi.encodeWithSelector(
            DauphineToken.initialize.selector,
            address(this) 
        );

        UUPSProxy tokenProxy = new UUPSProxy(
            address(tokenImpl),
            tokenInitData
        );

        dauphinetoken = DauphineToken(address(tokenProxy));

        console.log("DauphineToken proxy deployed at:", address(dauphinetoken));
        console.log("  DauphineToken owner is:", dauphinetoken.owner());

        Coinflip coinflipImpl = new Coinflip();
        
        bytes memory coinflipInitData = abi.encodeWithSelector(
            Coinflip.initialize.selector,
            address(this),         
            address(dauphinetoken)  
        );

        UUPSProxy coinflipProxy = new UUPSProxy(
            address(coinflipImpl),
            coinflipInitData
        );

        coinflip = Coinflip(address(coinflipProxy));

        console.log("Coinflip proxy deployed at:", address(coinflip));
        console.log("Coinflip owner is:", coinflip.owner());

        // Step 1: user1 plays on V1 and wins
        console.log("---- Playing game on V1 ----");

        vm.stopBroadcast();
        
        vm.prank(user1);

    
        uint8[10] memory guesses = [1,1,1,1,1,1,1,1,1,1];
        coinflip.userInput(guesses, user1);

        console.log("User1's DAU balance after winning on V1:", dauphinetoken.balanceOf(user1));

        // Step 2: Upgrade to V2
        CoinflipV2 coinflipImplV2 = new CoinflipV2();
        console.log("Deployed Coinflip V2 logic at:", address(coinflipImplV2));

        coinflip.upgradeToAndCall(address(coinflipImplV2), "");
        console.log("Upgraded coinflip proxy to V2!");

        CoinflipV2 coinflipV2 = CoinflipV2(address(coinflipProxy));

        // Step 3: user1 plays on V2 and wins
        vm.prank(user1);
        coinflipV2.userInput(guesses, user1);

        console.log("User1's DAU balance after winning on V2:", dauphinetoken.balanceOf(user1));

        // Step 4: user1 transfers some DAU to user2
        console.log("---- Transferring tokens from user1 -> user2 ----");
        vm.prank(user1);
        dauphinetoken.transfer(user2, 3e18);

        console.log("User1's DAU balance:", dauphinetoken.balanceOf(user1));
        console.log("User2's DAU balance:", dauphinetoken.balanceOf(user2));
    }
}