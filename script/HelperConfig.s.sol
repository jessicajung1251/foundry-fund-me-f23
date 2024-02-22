// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Contract has a NetworkConfig struct that holds the address of a price feed contract 
// Also has a NetworkConfig state variable `activeNetworkConfig` that holds the current network's configuration
// Constants, DECIMALS and INITIAL_PRICE are used when creating a mock price feed 
// Constructor checks the current network's chain ID and sets the activeNetworkConfig accordingly
// `GetSepoliaEthConfig` returns a NetworkConfig with the address of the Sepolia price feed
// `MainnetEthConfig` returns a NetworkConfig with the address of the mainnet price feed
// `getOrCreateAnvilEthConfig` checks if a price feed has already been set for the Anvil network. If it has, returns existing NetworkConfig. If not, deploys a new `MockV3Aggregator` contract, sets its address as the price feed in a new NetworkConfig, and returns this new configuration
// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep track of contract address across different chains
// Sepolia ETH/USD
// Mainnet ETH/USD 

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MocksV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil, we deploy mocks
    // Otherwise, grab the existing address from the live network

    NetworkConfig public activeNetworkConfig; 

    // To make contract more readable, we specify magic numbers
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        // 11155111 is the chain id for the local anvil chain
        if (block.chainid == 11155111) {
            activeNetworkConfig = GetSepoliaEthConfig(); 
        // 1 is the chain id for the mainnet
        } else if (block.chainid == 1) {
            activeNetworkConfig = MainnetEthConfig();
        }
         else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function GetSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // pricefeed address 
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function MainnetEthConfig() public pure returns (NetworkConfig memory) {
        // pricefeed address 
        NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // pricefeed address
        // 1. Deploy the mocks
        // 2. Return the mock address 
        // If we call getAnvilEthConfig without this if statement, we will actually create a new pricefeed 
        // If we already deployed one, we don't want to deploy a new one
        // If address is not zero, it means we have already set the price feed
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }


}

