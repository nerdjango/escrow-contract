// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Escrow{
    using ECDSA for bytes32;

    struct SupplyOrder {
        address client;
        address supplier;
        uint amount;
        bool supplyFulfilled;
        bool supplyReceived;
        bool completed;
        bool cancelled;
    }

    uint nonce = 0;

    mapping(bytes32 => SupplyOrder) userSupplyOrders;

    SupplyOrder[] supplyOrder;

    function fundContractForSupplyOrder(address _supplier) public payable returns (bytes32 message) {
        require(msg.value>0, "Insufficient amount");
        supplyOrder.push(SupplyOrder(msg.sender, _supplier, msg.value, false, false, false, false));
        message=keccak256(abi.encodePacked(msg.value, nonce));
        userSupplyOrders[message]=SupplyOrder(msg.sender, _supplier, msg.value, false, false, false, false);
        nonce++;
    }

    function checkOrder(bytes32 _msg) public view returns(SupplyOrder memory order) {
        order = userSupplyOrders[_msg];
    }

    function cancelOrder(bytes32 _msg) public orderIsActive(_msg) {
        require(userSupplyOrders[_msg].supplyFulfilled==false);
        require(userSupplyOrders[_msg].client==msg.sender);

        userSupplyOrders[_msg].cancelled=true;
    }

    function confirmFulfilment(bytes32 _msg) public orderIsActive(_msg) {
        require(userSupplyOrders[_msg].supplier==msg.sender);

        userSupplyOrders[_msg].supplyFulfilled=true;
    }

    function confirmReceipt(bytes32 _msg) public orderIsActive(_msg) {
        require(userSupplyOrders[_msg].client==msg.sender);

        userSupplyOrders[_msg].supplyReceived=true;
    }

    function receivePayment(
        bytes memory _signature,
        bytes32 _msg
    ) public checkSignature(_signature, _msg) {
        payable(msg.sender).transfer(userSupplyOrders[_msg].amount);
    }

    function verify(
        bytes memory _signature,
        bytes32 _msg
    ) public view orderIsActive(_msg) returns (bool) {
        require(userSupplyOrders[_msg].supplyReceived==true);
        require(userSupplyOrders[_msg].supplier==msg.sender);

        bool valid = userSupplyOrders[_msg].client ==
            _msg.toEthSignedMessageHash().recover(_signature);
        if (!valid) {
            return false;
        }
        return true;
    }

    modifier checkSignature(
        bytes memory _signature,
        bytes32 _msg
    ) {
        require(
            verify(_signature, _msg),
            "Invalid signature"
        );
        _;
    }

    modifier orderIsActive(
        bytes32 _msg
    ) {
        require(userSupplyOrders[_msg].completed==false);
        require(userSupplyOrders[_msg].cancelled==false);
        _;
    }

}