// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "forge-std/Script.sol";
import {CREATE3Factory} from "create3-factory/CREATE3Factory.sol";
import {PaymentSplitter} from "contracts/PaymentSplitter.sol";
import "forge-std/console.sol";

contract DeployScript is Script {
    // CREATE3Factory create3Factory = CREATE3Factory(0x236b01266D06c2E6a91142548d848732BB70B042);
    // bytes32 salt = keccak256(bytes(vm.envString("SALT")));
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (PaymentSplitter myContract) {
        // new PaymentSplitter();
        vm.startBroadcast(deployerPrivateKey);
        // address ps = create3Factory.deploy(salt, bytes.concat(type(PaymentSplitter).creationCode));
        // console.log("arare",ps);
        myContract = new PaymentSplitter();

        vm.stopBroadcast();
    }
}
