// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MovieRating} from "../src/MovieRating.sol";
import {MovieFanSBT} from "../src/MovieFanSBT.sol";
import {PopcornToken} from "../src/PopcornToken.sol";
import {MovieHypeMarket} from "../src/MovieHypeMarket.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // deploy token
        PopcornToken popcorn = new PopcornToken();

        MovieFanSBT movieFanSBT = new MovieFanSBT(msg.sender);

        MovieRating movieRating = new MovieRating(address(movieFanSBT), address(popcorn));
        movieFanSBT.setRatingContract(address(movieRating));

        // 预先铸造一些代币用于奖励
        popcorn.mint(address(movieRating), 1000000 * 10**18);

        MovieHypeMarket movieHypeMarket = new MovieHypeMarket(address(popcorn));


        vm.stopBroadcast();
    }
}