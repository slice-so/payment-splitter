// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

struct Payment {
    bool isPaid;
    address token;
    address receiver;
    uint128 targetAmount;
    uint128 depositedAmount;
}
