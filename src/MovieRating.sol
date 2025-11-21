// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MovieFanSBT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MovieRating {
    MovieFanSBT public movieFanSBT;

    IERC20 public popcornToken;

    uint256 public constant REWARD_PER_RATING = 10 * 10**18;

    // 用电影ID映射到评分列表
    mapping(string => uint16[]) public ratingsByMovie;

    mapping(string => mapping(address => bool)) public hasRated;


    uint16 public constant SCALING_FACTOR = 100;

    // 事件，当有新评分时触发
    event NewRating(address indexed user, string movieId, uint8 rating);
    // 奖励发放事件
    event RewardPaid(address indexed user, uint256 amount);

    constructor(address _sbtAddress, address _tokenAddress) {
        movieFanSBT = MovieFanSBT(_sbtAddress);
        popcornToken = IERC20(_tokenAddress);
    }

    modifier onlySBTHolder() {
        require(
            movieFanSBT.isMovieFan(msg.sender),
            "Only Movie Fan SBT holders can rate movies"
        );
        _;
    }

    // 对电影评分
    function rateMovie(string memory _movieId, uint8 _rating) external onlySBTHolder {
        require(_rating >= 1 && _rating <= 10, "Rating must be 1-10");
        // 简单的防刷机制
        require(!hasRated[_movieId][msg.sender], "You have already rated this movie");
        
        ratingsByMovie[_movieId].push(_rating*SCALING_FACTOR);
        hasRated[_movieId][msg.sender] = true; // 标记已评分

        movieFanSBT.increaseTotalRatings(msg.sender);
        
        // 发放奖励代币 (需要合约预先存入足够的代币)
        require(popcornToken.balanceOf(address(this)) >= REWARD_PER_RATING, "Insufficient reward balance");
        popcornToken.transfer(msg.sender, REWARD_PER_RATING);

        emit NewRating(msg.sender, _movieId, _rating);
        emit RewardPaid(msg.sender, REWARD_PER_RATING);
    }

    // 获取电影的平均评分
    function getAverageRating(string memory _movieId) public view returns (uint) {
        uint16[] memory ratings = ratingsByMovie[_movieId];
        if (ratings.length == 0) {
            return 0;
        }
        
        uint total = 0;
        for (uint i = 0; i < ratings.length; i++) {
            total += ratings[i];
        }
        return total / ratings.length;
    }
    
    // 管理员充值奖励池的功能
    function fundRewardPool(uint256 _amount) external {
        popcornToken.transferFrom(msg.sender, address(this), _amount);
    }
}
