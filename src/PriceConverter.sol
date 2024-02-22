// SPDX-License-Identifier: MIT

// getPrice function interacts with the Chainlink price feed contract (passed as an argument) to get the latest price of ETH in USD 
// The price is returned as a uint256 after multiplying the original price by 10000000000 to match the decimal place of msg.value
// getConversionRate function takes in the amount of ETH and the Chainlink price feed contract as arguments. First it gets the price of ETH in USD using the `getPrice` function. Then it calculates the equivalent amount in USD of the provided ETH amount (by multiplying the price of ETH by the ETH amount and dividing by 1e18) and returns it as a uint256 USD equivalent amount 

pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are used for reusable code that can be linked to a contract during deployment
// Libraries are gas-efficient: library code is executed in the context of the calling contract and data doesn't need to be copied to the library contract
// Library code is reusable: allows you to write reusable code - the same library can be used in multiple contracts without duplicating the code
// Libraries cannot be storage: makes them lightweight and focused on providing utility function
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // For a function to interact with a contract, you need address + ABI
        // Sepolia ETH / USD Address
        // https://docs.chain.link/data-feeds/price-feeds/addresses
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Price of ETH in terms of USD
        // 2000.00000000
        // currently the value does not match the decimal place of 'msg.value'
         // types are different as well - int256 vs uint256 of msg.value, need to typecast
        return uint256(price * 10000000000);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        // 1 ETH
        // 2000_000000000000000000 
        uint256 ethPrice = getPrice(priceFeed);
        // (2000_000000000000000000 * 1_000000000000000000) / 1e18;
        // $2000 = 1 ETH
        // always multiple before you divide, since only whole numbers work in solidity
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}