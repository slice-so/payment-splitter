// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IPaymentSplitter {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AmountNotValid();
    error ReceiverNotValid();
    error PaymentAlreadyPaid();
    error PaymentNotExists();
    error EthNotAccepted();
    error NotEnoughFunds();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PaymentCreated(
        uint256 indexed paymentId_, address token_, address indexed receiver_, uint256 amount_, address indexed creator_
    );
    event Deposit(address indexed contributor_, uint256 indexed paymentId_, uint256 amount_);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function createPayment(address token_, address receiver_, uint256 amount_) external returns (uint256 paymentId);

    function createPaymentAndDeposit(address token_, address receiver_, uint256 amount_, uint256 depositAmount_)
        external
        payable;

    function deposit(uint256 paymentId_, uint256 amount_) external payable;

    function executePayment(uint256 paymentId_) external;

    function redeem(uint256 paymentId_, uint256 amount_) external;
}
