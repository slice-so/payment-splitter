// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "forge-std/Script.sol";
import {CREATE3Factory} from "create3-factory/CREATE3Factory.sol";
import {MyContract} from "contracts/MyContract.sol";

contract DeployScript is Script {
    CREATE3Factory create3Factory = CREATE3Factory(0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf);
    bytes32 salt = keccak256(bytes(vm.envString("SALT")));
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (MyContract myContract) {
        vm.startBroadcast(deployerPrivateKey);

        myContract = MyContract(create3Factory.deploy(salt, bytes.concat(type(MyContract).creationCode)));

        vm.stopBroadcast();
    }
}
