// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MovieHypeMarket
 * @dev 这是一个基于联合曲线(Bonding Curve)的自动做市商合约。
 * 用户可以买卖电影的"热度份额"，价格随供应量线性增长。
 * 这与 MovieRating 合约分离，专注于"热度/投机"市场。
 */
contract MovieHypeMarket {
    IERC20 public popcornToken;

    // 价格增长斜率: 每增加1股，价格增加 0.001 Token
    // 10**15 = 0.001 * 10**18
    uint256 public constant PRICE_SLOPE = 10**15; 

    // 电影ID => 总发行份额 (Supply)
    mapping(string => uint256) public movieSharesSupply;
    
    // 电影ID => 用户地址 => 持有份额
    mapping(string => mapping(address => uint256)) public movieSharesBalance;

    // 电影ID => 用户地址 => 持仓总成本 (用于计算盈亏)
    mapping(string => mapping(address => uint256)) public movieSharesTotalCost;

    // 交易事件
    event Trade(address indexed user, string movieId, bool isBuy, uint256 shareAmount, uint256 tokenAmount, uint256 newSupply);

    constructor(address _tokenAddress) {
        popcornToken = IERC20(_tokenAddress);
    }

    // --- 价格计算公式 (线性曲线 P = slope * supply) ---

    // 计算购买 amount 数量份额所需的总费用
    // Cost = Integral(supply, supply+amount) of (x * slope) dx
    // Discrete Sum = (amount * (2 * supply + amount - 1)) / 2 * slope
    function getBuyPrice(string memory movieId, uint256 amount) public view returns (uint256) {
        uint256 supply = movieSharesSupply[movieId];
        uint256 sum = (amount * (2 * supply + amount - 1)) / 2;
        return sum * PRICE_SLOPE;
    }

    // 计算卖出 amount 数量份额可获得的总返还
    function getSellPrice(string memory movieId, uint256 amount) public view returns (uint256) {
        uint256 supply = movieSharesSupply[movieId];
        if (supply < amount) return 0;
        
        // 卖出时的价格是基于减少后的供应量计算的
        uint256 newSupply = supply - amount;
        uint256 sum = (amount * (2 * newSupply + amount - 1)) / 2;
        return sum * PRICE_SLOPE;
    }

    // --- 交易功能 ---

    // 买入份额 (做多热度)
    function buyShares(string memory movieId, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 price = getBuyPrice(movieId, amount);
        
        // 检查授权和余额
        require(popcornToken.balanceOf(msg.sender) >= price, "Insufficient Popcorn balance");
        require(popcornToken.allowance(msg.sender, address(this)) >= price, "Insufficient allowance");

        // 将用户代币转入合约作为储备金 (TVL)
        popcornToken.transferFrom(msg.sender, address(this), price);

        // 更新用户的总成本
        movieSharesTotalCost[movieId][msg.sender] += price;

        // 更新状态
        movieSharesSupply[movieId] += amount;
        movieSharesBalance[movieId][msg.sender] += amount;

        emit Trade(msg.sender, movieId, true, amount, price, movieSharesSupply[movieId]);
    }

    // 卖出份额 (获利了结)
    function sellShares(string memory movieId, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        uint256 currentBalance = movieSharesBalance[movieId][msg.sender];
        require(currentBalance >= amount, "Insufficient shares");

        uint256 price = getSellPrice(movieId, amount);

        // 更新用户的总成本 (按比例减少成本)
        // 卖出部分对应的成本 = (总成本 * 卖出数量) / 当前持仓总量
        uint256 costRemoved = (movieSharesTotalCost[movieId][msg.sender] * amount) / currentBalance;
        movieSharesTotalCost[movieId][msg.sender] -= costRemoved;

        // 更新状态
        movieSharesSupply[movieId] -= amount;
        movieSharesBalance[movieId][msg.sender] -= amount;

        // 合约将储备金返还给用户
        require(popcornToken.balanceOf(address(this)) >= price, "Contract liquidity error");
        popcornToken.transfer(msg.sender, price);

        emit Trade(msg.sender, movieId, false, amount, price, movieSharesSupply[movieId]);
    }

    // 查询某用户在某电影的持仓
    function getBalance(string memory movieId, address user) external view returns (uint256) {
        return movieSharesBalance[movieId][user];
    }

    // 获取用户盈亏数据的辅助函数
    // 返回: (当前持仓价值, 总投入成本, 盈亏金额)
    function getUserPositionInfo(string memory movieId, address user) external view returns (uint256 value, uint256 cost, int256 pnl) {
        uint256 balance = movieSharesBalance[movieId][user];
        if (balance == 0) {
            return (0, 0, 0);
        }

        // 1. 计算当前持仓如果全部卖出值多少钱
        value = getSellPrice(movieId, balance);
        
        // 2. 获取历史总成本
        cost = movieSharesTotalCost[movieId][user];

        // 3. 计算盈亏 (int256 支持负数)
        pnl = int256(value) - int256(cost);
    }
    
    // 查询某电影的当前热度(总份额)
    function getMovieSupply(string memory movieId) external view returns (uint256) {
        return movieSharesSupply[movieId];
    }
}