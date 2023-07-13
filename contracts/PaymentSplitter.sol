// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./interfaces/IPaymentSplitter.sol";
// import "@openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

/// @title One-liner contract description
/// @author Dom-Mac <@zerohex_eth>
/// @notice Additional description
contract PaymentSplitter is IPaymentSplitter {

  //*********************************************************************//
  // ---------------------------- storage ------------------------------ //
  //*********************************************************************//
  struct Payment {
    bool isPaid;
    address token;
    address receiver;
    uint256 amount;
    uint256 paidAmount;
  }

  mapping(uint256 => Payment) public payments;
  uint256 public paymentCount = 1;
  
  // constructor() ERC1155("https://") {
  // }

  //*********************************************************************//
  // ---------------------------- external ----------------------------- //
  //*********************************************************************//

  function createPaymentSplitter(address token_, address receiver_, uint256 amount_) external {
    if (amount_ == 0) {
      revert AmountNotValid();
    }
    if (receiver_ == address(0)) {
      revert ReceiverNotValid();
    }

    payments[paymentCount] = Payment(false, token_, receiver_, amount_, 0);
    ++paymentCount;

    emit PaymentSplitterCreated(paymentCount, token_, receiver_, amount_, msg.sender);
  }

  function contributeToPayment(uint256 paymentId_, uint256 amount_) external payable {
    Payment memory payment = payments[paymentId_];

    _beforeContribute(payment, amount_);

    payment.paidAmount += amount_;

    payments[paymentId_] = payment;

    // _mint(msg.sender, paymentId_, amount_, "");

    if (payment.token == address(0)) {
      if (msg.value != amount_) {
        revert AmountNotValid();
      }
    } else {
      bool success = IERC20(payment.token).transferFrom(msg.sender, address(this), amount_);

      if (!success || payment.paidAmount + amount_ > payment.amount) {
        revert AmountNotValid(); // TODO: better error handling
      }
    }

    emit Deposit(msg.sender, paymentId_, amount_);
  }

  function executePayment(uint256 paymentId_) external {
    Payment memory payment = payments[paymentId_];

    if (payment.paidAmount != payment.amount) {
      revert AmountNotValid();
    }

    if (payment.isPaid) {
      revert PaymentAlreadyPaid();
    }

    payments[paymentId_].isPaid = true;

    if (payment.token == address(0)) {
      payable(payment.receiver).transfer(payment.amount);
    } else {
      bool success = IERC20(payment.token).transfer(payment.receiver, payment.amount);

      if (!success) {
        revert AmountNotValid(); // TODO: better error handling
      }
    }
  }

  //*********************************************************************//
  // ---------------------------- internal ----------------------------- //
  //*********************************************************************//

  function _beforeContribute(Payment memory payment_, uint256 amount_) internal pure {
      if (payment_.amount == 0) {
      revert PaymentNotExists();
    }

    if (payment_.isPaid) {
      revert PaymentAlreadyPaid();
    }

    if (amount_ == 0) {
      revert AmountNotValid();
    }

    if (amount_ > payment_.amount - payment_.paidAmount) {
      revert AmountNotValid();
    }
  }
}
