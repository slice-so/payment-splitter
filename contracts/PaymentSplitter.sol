// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Payment} from "./structs/Payment.sol";
import {IPaymentSplitter} from "./interfaces/IPaymentSplitter.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

/// @title One-liner contract description
/// @author Dom-Mac <@zerohex_eth>
/// @notice Additional description
contract PaymentSplitter is ERC1155, IPaymentSplitter {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => Payment) public payments;
    uint256 public paymentCount;

    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeCastLib for uint256;

    /*//////////////////////////////////////////////////////////////
                            WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new payment intend
     *
     * @param token Address of the token to be used for the payment, or 0x0 for ETH
     * @param receiver Address of the receiver of the payment
     * @param targetAmount Amount of the payment
     *
     * @return paymentId Id of the created payment
     */
    function createPayment(address token, address receiver, uint256 targetAmount) public returns (uint256 paymentId) {
        unchecked {
            paymentId = ++paymentCount;

            if (targetAmount == 0) {
                revert AmountNotValid();
            }

            if (receiver == address(0)) {
                revert ReceiverNotValid();
            }

            payments[paymentCount] = Payment({
                isPaid: false,
                token: token,
                receiver: receiver,
                targetAmount: targetAmount.toUint128(),
                depositedAmount: 0
            });

            emit PaymentCreated(paymentCount, token, receiver, targetAmount, msg.sender);
        }
    }

    function createPaymentAndDeposit(address token, address receiver, uint256 targetAmount, uint256 depositAmount)
        public
        payable
    {
        uint256 paymentId = createPayment(token, receiver, targetAmount);
        deposit(paymentId, depositAmount);
    }

    function deposit(uint256 paymentId, uint256 amount) public payable {
        Payment memory payment = payments[paymentId];

        _beforeContribute(payment, amount);

        payment.depositedAmount += amount.toUint128();

        payments[paymentId] = payment;

        _mint(msg.sender, paymentId, amount, "");

        if (payment.token == address(0)) {
            if (msg.value != amount) {
                revert AmountNotValid();
            }
        } else {
            if (msg.value != 0) {
                revert EthNotAccepted();
            }
            bool success = IERC20(payment.token).transferFrom(msg.sender, address(this), amount);

            if (!success) {
                revert TransferFailed();
            }
        }

        emit Deposit(msg.sender, paymentId, amount);
    }

    function executePayment(uint256 paymentId) external {
        Payment memory payment = payments[paymentId];

        if (payment.depositedAmount != payment.targetAmount) {
            revert NotEnoughFunds();
        }

        if (payment.isPaid) {
            revert PaymentAlreadyPaid();
        }

        payments[paymentId].isPaid = true;

        if (payment.token == address(0)) {
            payable(payment.receiver).transfer(payment.targetAmount);
        } else {
            bool success = IERC20(payment.token).transfer(payment.receiver, payment.targetAmount);

            if (!success) {
                revert TransferFailed();
            }
        }
    }

    function redeem(uint256 paymentId, uint256 amount) external {
        Payment memory payment = payments[paymentId];

        if (payment.isPaid) {
            revert PaymentAlreadyPaid();
        }

        uint256 balance = balanceOf[msg.sender][paymentId];

        if (balance < amount) {
            revert AmountNotValid();
        }

        _burn(msg.sender, paymentId, amount);
        payments[paymentId].depositedAmount -= amount.toUint128();

        if (payment.token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            bool success = IERC20(payment.token).transfer(msg.sender, amount);

            if (!success) {
                revert TransferFailed();
            }
        }
    }

    //*********************************************************************//
    // ---------------------------- internal ----------------------------- //
    //*********************************************************************//

    function _beforeContribute(Payment memory payment, uint256 amount) internal pure {
        if (payment.targetAmount == 0) {
            revert PaymentNotExists();
        }

        if (payment.isPaid) {
            revert PaymentAlreadyPaid();
        }

        if (amount == 0 || amount > payment.targetAmount - payment.depositedAmount) {
            revert AmountNotValid();
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 /* id */ ) public pure override returns (string memory) {
        return "https://";
    }
}
