// SPDX-License-Identifier: MIT

// 1. Unit
//  - Testing a specific part of of our code
// 2. Integration
//  - Testing how our code works with other parts of our code
// 3. Forked
// - Testing out code on a simulated real environment
// 4. Staging
// - Testing our code in a real environment that is not prod

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    // setUp always runs first
    // Test will always run setup -> function -> set up -> function ... etc.
    function setUp() external {
        // create a new instance of DeployFundMe
        DeployFundMe deployFundMe = new DeployFundMe();
        // run is going to return a FundMe contract
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    // test that the minimum usd is 5
    function testMinimumUSDIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // test that the owner is the message sender
    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // test that the price feed version is accurate
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // expected revert test that the fund function fails when the value sent is less than the minimum usd
    function testFundFailsNotEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        // assert(this tx fails/reverts)
        fundMe.fund(); // send 0 value, which is less than the minimum value -> test will pass since we expected the revert
    }

    // *checks the getter function of `getAddressToAmountFunded`*
    // this checks that the fund function correctly updates the addressToAmountFunded mapping
    // uses the vm.prank function to simulate a transtion from USER
    // calls fund function with a value of SEND_VALUE
    // after function call, it retrieves the amount funded by USER and checks if it is equal to SEND_VALUE
    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        // we are going to use `prank` so that we know exactly who is sending what call
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    // *checks the getter function of `getFunder`*
    // since it goes back to setup after the previous function, the state is reset
    // checks that the fund function correctly adds the sender to the funders array
    // uses the vm.prank to simulate a transaction from USER
    // calls fund function with a value of SEND_VALUE
    // after function call, it retrieves the funder at index 0 and checks if it is equal to USER
    function testAddsFunderToArrayOfFunders() public funded {
        // this should be user, since there's only one funder in the array
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // test the withdraw function from fundme contract
    function testOnlyOwnerCanWithdraw() public funded {
        // fund user with some money (used modifier)
        // then have the user try and withdraw - the user is not the owner, it should revert and test should pass
        vm.expectRevert(); // the next line should revert
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // when working with anvil, the gas price defaults to 0
        // to simulate the transaction with actual gas price, we need to tell our test to use a gas price
        // tx.gasPrice

        // Act
        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // this is what we are testing

        //uint256 gasEnd = gasleft();
        // `tx.gasprice` is built in to solidity, which tells you the current gas price
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log("Gas used: ", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax simulates a transaction from a specific address with a already loaded balance
            hoax(address(i), SEND_VALUE);
            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        // As of solidity v0.8, you can no longer cast explicitly from address to uint256
        // you have to use uint160 -> uint160 essentially has the same number of bytes as an address
        // `uint256 i = uint256(uint160(msg.sender));`
        uint160 numberOfFunders = 10;
        // starting index is 1, since sometimes the 0th index reverts and doesn't let you do stuff with it
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        //vm.prank(fundMe.getOwner());
        // in order to see how much gas this is going to spend, we need to calculate the gas left in this function call before and after
        // gasleft() function is a built-in function that returns the amount of gas left in the current call

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
