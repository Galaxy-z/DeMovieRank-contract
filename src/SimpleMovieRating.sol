// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleMovieRating {
    // 用电影ID映射到评分列表
    mapping(string => uint8[]) public ratingsByMovie;
    
    // 事件，当有新评分时触发
    event NewRating(address indexed user, string movieId, uint8 rating);

    // 对电影评分
    function rateMovie(string memory _movieId, uint8 _rating) external {
        require(_rating >= 1 && _rating <= 10, "Rating must be 1-10");
        
        ratingsByMovie[_movieId].push(_rating);
        emit NewRating(msg.sender, _movieId, _rating);
    }

    // 获取电影的平均评分
    function getAverageRating(string memory _movieId) public view returns (uint) {
        uint8[] memory ratings = ratingsByMovie[_movieId];
        if (ratings.length == 0) {
            return 0;
        }
        
        uint total = 0;
        for (uint i = 0; i < ratings.length; i++) {
            total += ratings[i];
        }
        return total / ratings.length;
    }
}