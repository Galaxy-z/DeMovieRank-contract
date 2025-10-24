// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SimpleMovieRating} from "../src/SimpleMovieRating.sol";

contract SimpleMovieRatingScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new SimpleMovieRating();
        vm.stopBroadcast();
    }
}