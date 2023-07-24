// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/console2.sol";
import "./helper/Setup.sol";
import {PaymentSplitter} from "contracts/PaymentSplitter.sol";
import {ERC20PresetFixedSupply} from "@openzeppelin/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract PaymentSplitterTest is Setup, PaymentSplitter {
    //*********************************************************************//
    // ----------------------------- storage ----------------------------- //
    //*********************************************************************//

    PaymentSplitter public paymentSplitter;

    address public constant ETH = address(0);
    ERC20PresetFixedSupply public DAI;

    address seller = 0x4D5d7d63989BBE6358a3352A2449d59Aa5A08267;
    uint256 paymentAmount = 1000;
    uint256 amount = 1000;

    //*********************************************************************//
    // ------------------------------ setup ------------------------------ //
    //*********************************************************************//

    function setUp() public virtual override {
        Setup.setUp();
        paymentSplitter = new PaymentSplitter();

        DAI = new ERC20PresetFixedSupply("DAI", "DAI", 100 ether, _user);
        hevm.prank(_user);
        DAI.approve(address(paymentSplitter), type(uint256).max);
    }

    //*********************************************************************//
    // ------------------------------ tests ------------------------------ //
    //*********************************************************************//

    function testDeploy() public {
        assertTrue(address(paymentSplitter) != address(0));
    }

    function testCreatePayment__ETH() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        (bool isPaid, address token, address receiver, uint128 targetAmount, uint128 depositedAmount) =
            paymentSplitter.payments(paymentId);

        assertTrue(!isPaid);
        assertTrue(token == ETH);
        assertTrue(receiver == seller);
        assertTrue(targetAmount == paymentAmount);
        assertTrue(depositedAmount == 0);
    }

    function testCreatePayment__ERC20() public {
        uint256 paymentId = paymentSplitter.createPayment(address(DAI), seller, paymentAmount);

        (bool isPaid, address token, address receiver, uint128 targetAmount, uint128 depositedAmount) =
            paymentSplitter.payments(paymentId);

        assertTrue(!isPaid);
        assertTrue(token == address(DAI));
        assertTrue(receiver == seller);
        assertTrue(targetAmount == paymentAmount);
        assertTrue(depositedAmount == 0);
    }

    function testCreatePayment__Event() public {
        hevm.expectEmit(true, true, true, true);
        emit PaymentCreated(1, ETH, seller, paymentAmount, address(this));
        paymentSplitter.createPayment(ETH, seller, paymentAmount);
    }

    function testCreatePayment__Revert() public {
        /// @notice zero `targetAmount`
        paymentAmount = 0;
        hevm.expectRevert(AmountNotValid.selector);
        paymentSplitter.createPayment(ETH, seller, paymentAmount);

        /// @notice zero `receiver`
        seller = address(0);
        paymentAmount = 1000;
        hevm.expectRevert(ReceiverNotValid.selector);
        paymentSplitter.createPayment(ETH, seller, paymentAmount);

        /// @notice overflow on targetAmount > uint128
        // TODO: fix this
        // paymentAmount = type(uint128).max + 1;
        // hevm.expectRevert();
        // paymentSplitter.createPayment(ETH, seller, paymentAmount);
    }

    function testDeposit__ETH() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        (bool isPaid, address token, address receiver, uint128 targetAmount, uint128 depositedAmount) =
            paymentSplitter.payments(paymentId);

        assertTrue(!isPaid);
        assertTrue(token == ETH);
        assertTrue(receiver == seller);
        assertTrue(targetAmount == paymentAmount);
        assertTrue(depositedAmount == amount);

        assertTrue(address(paymentSplitter).balance == amount);
        assertTrue(paymentSplitter.balanceOf(_user, paymentId) == amount);
    }

    function testDeposit__ERC20() public {
        uint256 paymentId = paymentSplitter.createPayment(address(DAI), seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.deposit(paymentId, amount);

        (bool isPaid, address token, address receiver, uint128 targetAmount, uint128 depositedAmount) =
            paymentSplitter.payments(paymentId);

        assertTrue(!isPaid);
        assertTrue(token == address(DAI));
        assertTrue(receiver == seller);
        assertTrue(targetAmount == paymentAmount);
        assertTrue(depositedAmount == amount);

        assertTrue(DAI.balanceOf(address(paymentSplitter)) == amount);
        assertTrue(paymentSplitter.balanceOf(_user, paymentId) == amount);
    }

    function testDeposit__Revert() public {
        uint256 paymentId = 1;

        hevm.startPrank(_user);

        /// @notice non existing `paymentId`
        hevm.expectRevert(InvalidPaymentId.selector);
        paymentSplitter.deposit{value: amount}(1, amount);

        paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        /// @notice zero `amount`
        amount = 0;
        hevm.expectRevert(AmountNotValid.selector);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        /// @notice `amount` is greater than `targetAmount`
        amount = paymentAmount + 1;
        hevm.expectRevert(AmountNotValid.selector);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        /// @notice `paymentId` is already paid
        amount = 1000;
        paymentSplitter.deposit{value: amount}(paymentId, amount);
        paymentSplitter.executePayment(paymentId);
        hevm.expectRevert(AmountNotValid.selector);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        /// @notice payment is not in ETH and `msg` value is not zero
        paymentId = paymentSplitter.createPayment(address(DAI), seller, paymentAmount);
        hevm.expectRevert(EthNotAccepted.selector);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        hevm.stopPrank();
    }

    function testDeposit__Multiple() public {
        paymentAmount *= 2;
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.deposit{value: amount}(paymentId, amount);
        hevm.prank(_user);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        (bool isPaid, address token, address receiver, uint128 targetAmount, uint128 depositedAmount) =
            paymentSplitter.payments(paymentId);

        assertTrue(!isPaid);
        assertTrue(token == ETH);
        assertTrue(receiver == seller);
        assertTrue(targetAmount == paymentAmount);
        assertTrue(depositedAmount == amount * 2);

        assertTrue(address(paymentSplitter).balance == amount * 2);
        assertTrue(paymentSplitter.balanceOf(_user, paymentId) == amount * 2);
    }

    function testDeposit__Event() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.prank(_user);
        hevm.expectEmit(true, true, true, true);
        emit Deposit(_user, paymentId, amount);
        paymentSplitter.deposit{value: amount}(paymentId, amount);
    }

    function testCreatePaymentAndDeposit__ETH() public {
        hevm.prank(_user);
        uint256 paymentId = paymentSplitter.createPaymentAndDeposit{value: amount}(ETH, seller, paymentAmount, amount);

        (bool isPaid, address token, address receiver, uint128 targetAmount, uint128 depositedAmount) =
            paymentSplitter.payments(paymentId);

        assertTrue(!isPaid);
        assertTrue(token == ETH);
        assertTrue(receiver == seller);
        assertTrue(targetAmount == paymentAmount);
        assertTrue(depositedAmount == amount);

        assertTrue(address(paymentSplitter).balance == amount);
        assertTrue(paymentSplitter.balanceOf(_user, paymentId) == amount);
    }

    function testCreatePaymentAndDeposit__ERC20() public {
        hevm.prank(_user);
        uint256 paymentId = paymentSplitter.createPaymentAndDeposit(address(DAI), seller, paymentAmount, amount);

        (bool isPaid, address token, address receiver, uint128 targetAmount, uint128 depositedAmount) =
            paymentSplitter.payments(paymentId);

        assertTrue(!isPaid);
        assertTrue(token == address(DAI));
        assertTrue(receiver == seller);
        assertTrue(targetAmount == paymentAmount);
        assertTrue(depositedAmount == amount);

        assertTrue(DAI.balanceOf(address(paymentSplitter)) == amount);
        assertTrue(paymentSplitter.balanceOf(_user, paymentId) == amount);
    }

    function testExecutePayment__ETH() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.deposit{value: amount}(paymentId, amount);
        paymentSplitter.executePayment(paymentId);

        (bool isPaid,,,, uint128 depositedAmount) = paymentSplitter.payments(paymentId);

        assertTrue(isPaid);
        assertTrue(address(paymentSplitter).balance == 0);
        assertTrue(address(seller).balance == depositedAmount);
    }

    function testExecutePayment__ERC20() public {
        uint256 paymentId = paymentSplitter.createPayment(address(DAI), seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.deposit(paymentId, amount);
        paymentSplitter.executePayment(paymentId);

        (bool isPaid,,,, uint128 depositedAmount) = paymentSplitter.payments(paymentId);

        assertTrue(isPaid);
        assertTrue(DAI.balanceOf(address(paymentSplitter)) == 0);
        assertTrue(DAI.balanceOf(address(seller)) == depositedAmount);
    }

    function testExecutePayment__Revert() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);
        amount -= 100;

        hevm.startPrank(_user);

        paymentSplitter.deposit{value: amount}(paymentId, amount);

        /// @notice payment not fully funded
        hevm.expectRevert(NotEnoughFunds.selector);
        paymentSplitter.executePayment(paymentId);

        /// @notice payment already executed
        paymentSplitter.deposit{value: 100}(paymentId, 100);
        paymentSplitter.executePayment(paymentId);
        hevm.expectRevert(PaymentAlreadyExecuted.selector);
        paymentSplitter.executePayment(paymentId);

        hevm.stopPrank();
    }

    function testExecutePayment__Event() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.deposit{value: amount}(paymentId, amount);
        hevm.expectEmit(true, true, true, true);
        emit PaymentExecuted(paymentId, seller, amount, address(this));
        paymentSplitter.executePayment(paymentId);
    }

    function testDepositAndExecutePayment__ETH() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.depositAndExecutePayment{value: amount}(paymentId);

        (bool isPaid,,,, uint128 depositedAmount) = paymentSplitter.payments(paymentId);

        assertTrue(isPaid);
        assertTrue(address(paymentSplitter).balance == 0);
        assertTrue(address(seller).balance == depositedAmount);
    }

    function testDepositAndExecutePayment__ERC20() public {
        uint256 paymentId = paymentSplitter.createPayment(address(DAI), seller, paymentAmount);

        hevm.prank(_user);
        paymentSplitter.depositAndExecutePayment(paymentId);

        (bool isPaid,,,, uint128 depositedAmount) = paymentSplitter.payments(paymentId);

        assertTrue(isPaid);
        assertTrue(DAI.balanceOf(address(paymentSplitter)) == 0);
        assertTrue(DAI.balanceOf(address(seller)) == depositedAmount);
    }

    function testWithdraw__ETH() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.startPrank(_user);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        paymentSplitter.withdraw(paymentId, amount);
        (,,,, uint128 depositedAmount) = paymentSplitter.payments(paymentId);
        hevm.stopPrank();

        assertTrue(address(paymentSplitter).balance == 0);
        assertTrue(address(_user).balance == 100 ether);
        assertTrue(paymentSplitter.balanceOf(_user, paymentId) == 0);
        assertTrue(depositedAmount == 0);
    }

    function testWithdraw__ERC20() public {
        uint256 paymentId = paymentSplitter.createPayment(address(DAI), seller, paymentAmount);

        hevm.startPrank(_user);
        paymentSplitter.deposit(paymentId, amount);

        paymentSplitter.withdraw(paymentId, amount);
        (,,,, uint128 depositedAmount) = paymentSplitter.payments(paymentId);
        hevm.stopPrank();

        assertTrue(DAI.balanceOf(address(paymentSplitter)) == 0);
        assertTrue(DAI.balanceOf(address(_user)) == 100 ether);
        assertTrue(paymentSplitter.balanceOf(_user, paymentId) == 0);
        assertTrue(depositedAmount == 0);
    }

    function testWithdraw__Revert() public {
        uint256 paymentId = paymentSplitter.createPayment(ETH, seller, paymentAmount);

        hevm.startPrank(_user);
        paymentSplitter.deposit{value: amount}(paymentId, amount);

        /// @notice `amount` is greater than `depositedAmount`
        hevm.expectRevert(AmountNotValid.selector);
        paymentSplitter.withdraw(paymentId, amount + 1);

        /// @notice payment already executed
        paymentSplitter.executePayment(paymentId);
        hevm.expectRevert(PaymentAlreadyExecuted.selector);
        paymentSplitter.withdraw(paymentId, amount);

        hevm.stopPrank();
    }
}
