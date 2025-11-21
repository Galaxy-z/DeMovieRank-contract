// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PopcornToken is ERC20 {
    constructor() ERC20("PopcornToken", "POP") {
        // 铸造 100万个代币给部署者
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    // 测试用的水龙头功能
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}