// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/console2.sol";
import "./helper/Setup.sol";
import "contracts/PaymentSplitter.sol";

contract PaymentSplitterTest is Setup {
    //*********************************************************************//
    // ----------------------------- storage ----------------------------- //
    //*********************************************************************//

    PaymentSplitter public myContract;

    //*********************************************************************//
    // ------------------------------ setup ------------------------------ //
    //*********************************************************************//

    function setUp() public virtual override {
        Setup.setUp();

        myContract = PaymentSplitter(
            _create3Factory.deploy(
                keccak256(bytes("SALT")),
                bytes.concat(
                    type(PaymentSplitter).creationCode,
                    "" // constructor parameters encoded
                )
            )
        );
    }

    //*********************************************************************//
    // ------------------------------ tests ------------------------------ //
    //*********************************************************************//

    function testDeploy() public {
        assertTrue(address(myContract) != address(0));
    }
}
