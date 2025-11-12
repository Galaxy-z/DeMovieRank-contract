// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MovieRating} from "../src/MovieRating.sol";
import {MovieFanSBT} from "../src/MovieFanSBT.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MovieFanSBT movieFanSBT = new MovieFanSBT(msg.sender);
        new MovieRating(address(movieFanSBT));
        vm.stopBroadcast();
    }
}