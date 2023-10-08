// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "forge-std/Script.sol";
import {CREATE3Factory} from "create3-factory/CREATE3Factory.sol";
import {PaymentSplitter} from "contracts/PaymentSplitter.sol";

contract DeployScript is Script {
    CREATE3Factory create3Factory = CREATE3Factory(0x8Ae72A2311A7d225B6CA7B4fdfb355CdBf64E647);
    bytes32 salt = keccak256(bytes(vm.envString("SALT")));
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (PaymentSplitter myContract) {
        vm.startBroadcast(deployerPrivateKey);

        myContract = PaymentSplitter(create3Factory.deploy(salt, bytes.concat(type(PaymentSplitter).creationCode)));

        vm.stopBroadcast();
    }
}
