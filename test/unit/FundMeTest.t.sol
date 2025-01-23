// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
// or import {Test} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address alice = makeAddr("alice");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 1000 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // This function is called before each test
        // us -> FundMeTest -> FundMe (fundMe.owner = FundMeTest)
        // fundMe = new FundMe();

        // us -> FundMeTest -> DeployFundMe(run) -> FundMe (fundMe.owner = us)
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(alice, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testMinimumDollarIsFive() external view {
        assertEq(fundMe.getMinimumUSD(), 5e18);
    }

    function testOwnerIsMsgSender() external view {
        assertEq(address(fundMe.getOwner()), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() external view {
        if (block.chainid == 11155111) {
            assertEq(fundMe.getVersion(), 4);
        } else if (block.chainid == 1) {
            assertEq(fundMe.getVersion(), 6);
        }
    }

    function testFundFailsWithoutEnoughETH() external {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value
    }

    function testFundUpdatesFundDataStructure() external funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() external funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);
    }

    function testOnlyOwnerCanWithdraw() external funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() external funded {
        // arrange
        address owner = fundMe.getOwner();
        uint256 startingFunderBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = owner.balance;

        // act
        vm.prank(owner);
        fundMe.withdraw();

        uint256 endingFunderBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = owner.balance;

        // assert
        assertEq(endingFunderBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFunderBalance);
    }

    function testWithdrawFromMultipleFundersCheaper() external funded {
        // arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            // hoax = vm.prank + vm.deal
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        address owner = fundMe.getOwner();
        uint256 startingFunderBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = owner.balance;

        uint256 gasStart = gasleft();
        
        // act
        vm.txGasPrice(GAS_PRICE);
        vm.prank(owner);
        fundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();

        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consumed: %d gas", gasUsed);

        uint256 endingFunderBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = owner.balance;

        // assert
        assertEq(endingFunderBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFunderBalance);
        assertEq(endingOwnerBalance - startingOwnerBalance, (numberOfFunders + 1) * SEND_VALUE);
    }

    function testWithdrawFromMultipleFunders() external funded {
        // arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            // hoax = vm.prank + vm.deal
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        address owner = fundMe.getOwner();
        uint256 startingFunderBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = owner.balance;

        uint256 gasStart = gasleft();
        // act
        vm.txGasPrice(GAS_PRICE);
        vm.prank(owner);
        fundMe.withdraw();
        uint256 gasEnd = gasleft();

        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consumed: %d gas", gasUsed);

        uint256 endingFunderBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = owner.balance;

        // assert
        assertEq(endingFunderBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFunderBalance);
        assertEq(endingOwnerBalance - startingOwnerBalance, (numberOfFunders + 1) * SEND_VALUE);
    }
}
