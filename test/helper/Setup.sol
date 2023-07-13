// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {CREATE3Factory} from "create3-factory/CREATE3Factory.sol";

// Provides common functionality, such as deploying contracts on test setup.
contract Setup is DSTestPlus {
    //*********************************************************************//
    // --------------------- internal stored properties ------------------- //
    //*********************************************************************//
    CREATE3Factory _create3Factory = new CREATE3Factory();
    address internal _user = address(69);

    //*********************************************************************//
    // --------------------------- test setup ---------------------------- //
    //*********************************************************************//

    // Deploys and initializes contracts for testing.
    function setUp() public virtual {
        // ---- general setup ----
        hevm.deal(_user, 100 ether);

        hevm.label(_user, "user");
    }
}
