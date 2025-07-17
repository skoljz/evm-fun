// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PumpToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function WETH() external pure returns (address);
}

contract EvmFun is ReentrancyGuard, Ownable {
    struct SaleInfo {
        mapping(address => uint256) contributions;
        mapping(address => bool) refunded;
    
        address token;
        uint256 cap;
        uint256 raised;
        bool listed;
        address[] contributors;
        uint256 refundPool;
        uint256 listingTime;
        uint256 refundDeadline;
    }

    mapping(address => SaleInfo) public sales;
    address public uniswapRouter;
    uint256 public refundPercent = 50;
    uint256 public refundDuration = 7 days;

    event TokenCreated(address indexed token, address indexed creator, uint256 cap);
    event TokenListed(address indexed token, uint256 liquidity);
    event Refunded(address indexed user, address indexed token, uint256 amount);

    constructor(address _uniswapRouter) Ownable(msg.sender) {
        uniswapRouter = _uniswapRouter;
    }

    function createToken(string memory name, string memory symbol, uint256 cap, uint256 initialSupply) external returns (address) {
        require(cap > 0, "Cap must be positive");
        PumpToken token = new PumpToken(name, symbol, initialSupply, address(this));

        sales[address(token)].token = address(token);
        sales[address(token)].cap = cap;

        emit TokenCreated(address(token), msg.sender, cap);

        return address(token);
    }

    function buy(address token) external payable nonReentrant {
        SaleInfo storage sale = sales[token];

        require(sale.token != address(0), "Token not found");
        require(!sale.listed, "Already listed");
        require(msg.value > 0, "Zero value");
        require(sale.raised + msg.value <= sale.cap, "Cap exceeded");

        if (sale.contributions[msg.sender] == 0) {
            sale.contributors.push(msg.sender);
        }

        sale.raised += msg.value;
        sale.contributions[msg.sender] += msg.value;

        PumpToken(token).transfer(msg.sender, msg.value);

        if (sale.raised == sale.cap) {
            _listOnUniswap(token);
        }
    }

    function _listOnUniswap(address token) internal {
        SaleInfo storage sale = sales[token];
        require(!sale.listed, "Already listed");

        sale.listed = true;
        sale.listingTime = block.timestamp;
        sale.refundDeadline = block.timestamp + refundDuration;
        sale.refundPool = (sale.raised * refundPercent) / 100;

        uint256 ethForUniswap = sale.raised - sale.refundPool;
        uint256 tokenAmount = PumpToken(token).balanceOf(address(this));
        PumpToken(token).approve(uniswapRouter, tokenAmount);
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);

        router.addLiquidityETH{value: ethForUniswap}(
            token,
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp + 600
        );

        emit TokenListed(token, tokenAmount);
    }

    function claimRefund(address token) external nonReentrant {
        SaleInfo storage sale = sales[token];
        require(sale.listed, "Not listed yet");
        require(!sale.refunded[msg.sender], "Already refunded");

        uint256 contrib = sale.contributions[msg.sender];
        require(contrib > 0, "No contribution");

        uint256 refund = (contrib * refundPercent) / 100;
        sale.refunded[msg.sender] = true;
        sale.contributions[msg.sender] = 0;
        sale.refundPool -= refund;
        (bool sent, ) = msg.sender.call{value: refund}("");
        require(sent, "Refund failed");

        emit Refunded(msg.sender, token, refund);
    }

    function withdrawUnclaimedRefund(address token) external onlyOwner {
        SaleInfo storage sale = sales[token];

        require(sale.listed, "Not listed");
        require(block.timestamp > sale.refundDeadline, "Refund period not over");

        uint256 amount = sale.refundPool;
        sale.refundPool = 0;
        (bool sent, ) = owner().call{value: amount}("");

        require(sent, "Withdraw failed");
    }

    receive() external payable {}
} 