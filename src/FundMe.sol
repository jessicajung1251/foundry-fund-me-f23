// SPDX-License-Identifier: MIT

// Overview: 
// The FundMe.sol contract is a crowdfunding contract that allows users to fund it with ETH and the owner to withdraw the funds 
// PriceConverter.sol is a library that contains functions to convert ETH to USD 
// FundFundMe and WithdrawFundMe contracts (Interactions.s.sol) are scripts that interact with the FundMe contract
// InteractionsTest contract is a test contract that tests the functionality of the FundMe contract using these scripts 
// The DeployFundMe contract is a script that deploys a new FundMe contract and assigns it to the fundMe state variable 
// The MockV3Aggregator contract is a mock contract that simulates the behavior of the Chainlink AggregatorV3Interface contract
// The HelperConfig contract is a utility contract that helps manage different configurations for different ETH networks



pragma solidity ^0.8.0;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 

// for errors it is <contract name>__<error name>
error FundMe__NotOwner();

contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables!

    // add constant so that it no longer takes up a storage spot -> more gas efficient
    // all caps with underscores
    uint256 public constant MINIMUM_USD = 5e18;
    // storage variables can be named with an s_ prefix
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    // variables that we set one time that is outside of the same line it is declared can be marked as immutable -> more gas efficient
    // i_(variable name)
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    // allow only owner to call withdraw function
    // sets the owner of the contract to the address that deploys the contract and initializes the `s_priceFeed` with the address of the `AggregatorV3Interface` contract
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // Fund function allows users to send ETH to the contract
    // Requires that the amount of ETH sent is greater than the MINIMUM_USD converted to ETH
    // Sender's address is addded to the `s_funders` array and the amount sent is added to the `s_addressToAmountFunded` mapping
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD, "did not send enough ETH"); // 1 ETH
        s_funders.push(msg.sender);
        // whatever the sender previously funded + whatever they're additionally funding
        s_addressToAmountFunded[msg.sender] += msg.value;

    }

    // Allow the owner of the contract to withdraw all the funds from the contract
    // They reset the amount funded by each funder to 0 and clear the `s_funders` array
    // Fund are then sent to the owner's address
    function cheaperWithdraw() public onlyOwner {
        // s_funders.length is read from storage once and is stored in memory
        // memory variable is then used in the loop condition, which is more gas-efficient
        uint256 funderslength = s_funders.length; 
        for(uint256 funderIndex = 0; funderIndex < funderslength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, /*bytes memory dataReturned*/)= payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess, "Call failed"); 

    }

    function withdraw() public onlyOwner {
        // starting index, ending index, step amount
        // start at the 0 index, get funder at the 0th funder array, take the address and stick it to mapping, reset the amount they sent us to 0
        // this will iterate all through 0, 1, ... , until we reach the index that is equal to or greater than the length of the array
        // s_funders.length is being called in each iteration of the loop, which is not gas efficient
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // this resets to a brand new address array
        s_funders = new address[](0);

        // withdraw the funds
        // msg.sender = address
        // payable(msg.sender) = payable address

        // transfer -> throws error, max 2300 gas
        //payable(msg.sender).transfer(address(this).balance);
    
        // send -> returns bool, max 2300 gas
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call -> returns bool, no capped gas
        (bool callSuccess, /*bytes memory dataReturned*/)= payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess, "Call failed"); 


    }

    // Returns the version of teh `s_priceFeed` contract
    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }

    // more gas efficient to call error code instead of having a whole string stored and then called
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Must be the owner!");
        if(msg.sender != i_owner) { revert FundMe__NotOwner(); }
        _;
    }

    // what happens when someone sends this contract ETH without calling the fund function
    // if someone sends money without calling the fund function they'll be automatically routed back to fund or if they send not enough funding, get reverted

    // receive()
    receive() external payable {
        fund();
    }
    // fallback()
    fallback() external payable {
        fund();
    }

    // View / pure functions (getters) 
    // using getter functions are a lot more readable and sensical rather than s_variable 
    // private variables are more gas efficient, so we want to only make them public or external view as we need

    // these are getter functions that we can now use to see if these are populated
    // getter functions allow external callers to access the contract's state variables (which are private in this case)

    // checks how much a specific address has contributed to the contract
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    } 
    // gets the address of a funder based on their position in the s_funders array
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    } 
    // used to check who the owner of the contract is
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly