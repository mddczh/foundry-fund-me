// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;

    address alice = makeAddr("alice");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 1000 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(alice, STARTING_BALANCE);
    }

    function testUserCanFundInteractions() external {
        uint256 preAliceBalance = alice.balance;
        uint256 preOwnerBalance = fundMe.getOwner().balance;

        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();

        address funder0 = fundMe.getFunder(0);
        assertEq(funder0, msg.sender);

        address funder1 = fundMe.getFunder(1);
        assertEq(funder1, alice);

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 afterAliceBalance = alice.balance;
        uint256 afterOwnerBalance = fundMe.getOwner().balance;

        assertEq(address(fundMe).balance, 0);
        assertEq(preAliceBalance - SEND_VALUE, afterAliceBalance);
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);
    }
}
