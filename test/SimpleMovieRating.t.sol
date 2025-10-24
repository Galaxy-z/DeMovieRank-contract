// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SimpleMovieRating} from "../src/SimpleMovieRating.sol";

contract SimpleMovieRatingTest is Test {
    SimpleMovieRating movieRating;

    function setUp() public {
        movieRating = new SimpleMovieRating();
    }

    function testInitialAverageRating() public {
        assertEq(movieRating.getAverageRating("movie1"), 0);
    }

    function testRateMovie() public {
        movieRating.rateMovie("movie1", 7);
        movieRating.rateMovie("movie1", 9);
        assertEq(movieRating.getAverageRating("movie1"), 8);
    }

    function testRateMovieInvalidRating() public {
        vm.expectRevert("Rating must be 1-10");
        movieRating.rateMovie("movie1", 0);

        vm.expectRevert("Rating must be 1-10");
        movieRating.rateMovie("movie1", 11);
    }
}
