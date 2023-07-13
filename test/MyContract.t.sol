// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/console2.sol";
import "./helper/Setup.sol";
import "contracts/MyContract.sol";

contract MyContractTest is Setup {
    //*********************************************************************//
    // ----------------------------- storage ----------------------------- //
    //*********************************************************************//

    MyContract public myContract;

    //*********************************************************************//
    // ------------------------------ setup ------------------------------ //
    //*********************************************************************//

    function setUp() public virtual override {
        Setup.setUp();

        myContract = MyContract(
            _create3Factory.deploy(
                keccak256(bytes("SALT")),
                bytes.concat(
                    type(MyContract).creationCode,
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
