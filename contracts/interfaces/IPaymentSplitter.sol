// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IPaymentSplitter {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AmountNotValid();
    error ReceiverNotValid();
    error PaymentAlreadyExecuted();
    error InvalidPaymentId();
    error EthNotAccepted();
    error NotEnoughFunds();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PaymentCreated(
        uint256 indexed paymentId, address token, address indexed receiver, uint256 amount, address indexed creator
    );
    event Deposit(address indexed contributor, uint256 indexed paymentId, uint256 amount);
    event PaymentExecuted(
        uint256 indexed paymentId, address indexed receiver, uint256 amount, address indexed executor
    );

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function createPayment(address token, address receiver, uint256 amount) external returns (uint256 paymentId);

    function createPaymentAndDeposit(address token, address receiver, uint256 amount, uint256 depositAmount)
        external
        payable
        returns (uint256 paymentId);

    function deposit(uint256 paymentId, uint256 amount) external payable;

    function executePayment(uint256 paymentId) external;

    function depositAndExecutePayment(uint256 paymentId) external payable;

    function withdraw(uint256 paymentId, uint256 amount) external;
}
