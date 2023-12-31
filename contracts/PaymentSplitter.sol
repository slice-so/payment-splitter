// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Payment} from "./structs/Payment.sol";
import {IPaymentSplitter} from "./interfaces/IPaymentSplitter.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

/// @title One-liner contract description
/// @author Dom-Mac <@zerohex_eth>
/// @notice When deposited amount strictly equals target amount execution is enabled
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
     * @param token Address of the `token` to be used for the payment, or 0x0 for ETH
     * @param receiver Address of the `receiver` of the payment
     * @param targetAmount Amount due to the `receiver`
     *
     * @return paymentId Id of the created payment
     */
    function createPayment(address token, address receiver, uint256 targetAmount) public returns (uint256 paymentId) {
        unchecked {
            paymentId = ++paymentCount;
        }

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

    /**
     * @notice Deposits `amount` to the payment with id `paymentId`
     *
     * @param paymentId Id of the payment
     * @param amount Amount to be deposited
     */
    function deposit(uint256 paymentId, uint256 amount) public payable {
        Payment memory payment = payments[paymentId];

        if (payment.token == address(0)) {
            amount = msg.value;
        }

        _beforeContribute(payment, amount);

        /**
         * @dev deposited `amount` cannot overflow as amount is always lower
         *      than `targetAmount - depositedAmount`
         */
        unchecked {
            payments[paymentId].depositedAmount += amount.toUint128();
        }

        _mint(msg.sender, paymentId, amount, "");

        if (payment.token != address(0)) {
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

    /**
     * @notice Creates a new payment intend and deposits `depositAmount` to it
     *        in the same transaction
     * @dev `msg.value` is used as `depositAmount` if `token` is ETH
     */
    function createPaymentAndDeposit(address token, address receiver, uint256 targetAmount, uint256 depositAmount)
        public
        payable
        returns (uint256 paymentId)
    {
        paymentId = createPayment(token, receiver, targetAmount);
        deposit(paymentId, depositAmount);
    }

    /**
     * @notice Executes the payment with id `paymentId`
     *
     * @param paymentId Id of the payment
     */
    function executePayment(uint256 paymentId) public {
        Payment memory payment = payments[paymentId];

        if (payment.depositedAmount != payment.targetAmount) {
            revert NotEnoughFunds();
        }

        if (payment.isPaid) {
            revert PaymentAlreadyExecuted();
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

        emit PaymentExecuted(paymentId, payment.receiver, payment.targetAmount, msg.sender);
    }

    /**
     * @notice Deposits remaining amount to be payed
     *         to the payment with id `paymentId`
     *         and executes it in the same transaction
     *
     * @param paymentId Id of the payment
     */
    function depositAndExecutePayment(uint256 paymentId) external payable {
        uint256 amount;
        /**
         * @dev deposited `amount` cannot underflow as `targetAmount` is always lower
         *      than `depositedAmount`
         */
        Payment memory payment = payments[paymentId];
        unchecked {
            amount = payment.targetAmount - payment.depositedAmount;
        }
        deposit(paymentId, amount);
        executePayment(paymentId);
    }

    /**
     * @notice Withdraws `amount` from the payment with id `paymentId`
     *         and burns the same amount of ERC1155
     *
     * @param paymentId Id of the payment
     * @param amount Amount to be withdrawn
     */
    function withdraw(uint256 paymentId, uint256 amount) external {
        Payment memory payment = payments[paymentId];

        if (payment.isPaid) {
            revert PaymentAlreadyExecuted();
        }

        if (balanceOf[msg.sender][paymentId] < amount) {
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
            revert InvalidPaymentId();
        }

        unchecked {
            if (amount == 0 || amount > payment.targetAmount - payment.depositedAmount) {
                revert AmountNotValid();
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 /* id */ ) public pure override returns (string memory) {
        return "https://";
    }
}
