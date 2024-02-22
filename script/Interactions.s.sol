// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Fund
// Withdraw

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

// Foundry script for Funding
// This contract has a fundFundMe function that sends a specified amount of eth to the FundMe contract by calling its fund function 
// The run function retrieves the most recently deployed FundMe contract and calls fundFund me on it
contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        // type cast mostRecentlyDeployed to payable since we are sending value here
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VALUE);
        
    }
    // we will have our run function call our fundFundMe function
    function run() external {
        // Looks inside the broadcast folder based off the chain id and grabs the most recently deployed contract from that file
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentlyDeployed);
    }
}

// Foundry script for Withdrawing
// This contract has a withdrawFundMe function that calls the withdraw function of the FundMe contract, which withdraws all funds from it
// The run function retrieves the most recently deployed FundMe contract and calls withdrawFundMe on it
contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        // type cast mostRecentlyDeployed to payable since we are sending value here
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdrew FundMe balance");
    }
    // we will have our run function call our fundFundMe function
    function run() external {
        // Looks inside the broadcast folder based off the chain id and grabs the most recently deployed contract from that file
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentlyDeployed);
    }
}
