// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockUniswapRouter {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        return (amountTokenDesired, msg.value, 1000);
    }

    function WETH() external pure returns (address) {
        return address(0);
    }
} 