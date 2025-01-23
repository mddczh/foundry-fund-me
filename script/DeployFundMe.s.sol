// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelpConfig} from "./HelpConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelpConfig helpConfig = new HelpConfig();
        address ethUsdPriceConfig = helpConfig.activeNetworkConfig();
        // befoe startBroadcast, not a real tx
        vm.startBroadcast();
        // after startBroadcast, real tx, make the txs.msg.sender = this.msg.sender not address(this)

        // startBroadcast() ===> us -> ??? -> DeployFundMe -> FundMe (fundMe.owner = us)
        FundMe fundMe = new FundMe(ethUsdPriceConfig);
        vm.stopBroadcast();
        return fundMe;
    }
}
