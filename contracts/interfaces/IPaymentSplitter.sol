// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IPaymentSplitter {
  //*********************************************************************//
  // ---------------------------- errors ------------------------------- //
  //*********************************************************************//
  error AmountNotValid();
  error ReceiverNotValid();
  error PaymentAlreadyPaid();
  error PaymentNotExists();

  //*********************************************************************//
  // ---------------------------- events ------------------------------- //
  //*********************************************************************//
  event PaymentSplitterCreated(uint256 indexed paymentId_, address token_, address indexed receiver_, uint256 amount_, address indexed creator_);
  event Deposit(address indexed contributor_, uint256 indexed paymentId_, uint256 amount_);
}
