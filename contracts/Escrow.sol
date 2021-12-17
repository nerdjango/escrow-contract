// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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

    event SupplyOrderCreated(address supplier, bytes32 message);
    uint nonce = 0;
    mapping(bytes32 => SupplyOrder) public userSupplyOrders; 
    SupplyOrder[] supplyOrder;

    function fundContractForSupplyOrder(address _supplier) external payable returns (bytes32 message) {
        require(msg.value>0, "Insufficient amount");
        supplyOrder.push(SupplyOrder(msg.sender, _supplier, msg.value, false, false, false, false));
        message=keccak256(abi.encodePacked(msg.value, address(this), nonce));
        userSupplyOrders[message]=SupplyOrder(msg.sender, _supplier, msg.value, false, false, false, false);
        nonce++;
        emit SupplyOrderCreated(_supplier, message);
    }

    function checkOrder(bytes32 _msg) external view returns(SupplyOrder memory order) {
        order = userSupplyOrders[_msg];
    }

    function cancelOrder(bytes32 _msg) external orderIsActive(_msg) {
        require(userSupplyOrders[_msg].supplyFulfilled==false, "This order cannot be cancelled as the order has already been fulfilled by the supplier");
        require(userSupplyOrders[_msg].client==msg.sender, "You're not the client for this order");

        userSupplyOrders[_msg].cancelled=true;
    }

    function confirmFulfilment(bytes32 _msg) external orderIsActive(_msg) isSupplier(_msg) {

        userSupplyOrders[_msg].supplyFulfilled=true;
    }

    function confirmReceipt(bytes32 _msg) external orderIsActive(_msg) {
        require(userSupplyOrders[_msg].client==msg.sender, "You're not the client for this order");

        userSupplyOrders[_msg].supplyReceived=true;
    }

    function receivePayment(
        bytes memory _signature,
        bytes32 _msg
    ) external checkSignature(_signature, _msg) isSupplier(_msg) {
        userSupplyOrders[_msg].completed=true;
        payable(msg.sender).transfer(userSupplyOrders[_msg].amount);
    }

    function _verify(
        bytes memory _signature,
        bytes32 _msg
    ) private view orderIsActive(_msg) returns (bool) {
        require(userSupplyOrders[_msg].supplyReceived==true, "You cannot redeem this contract until the client confirms receipt");

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
            _verify(_signature, _msg),
            "Invalid signature"
        );
        _;
    }

    modifier orderIsActive(
        bytes32 _msg
    ) {
        require(userSupplyOrders[_msg].completed==false, "This order has been completed");
        require(userSupplyOrders[_msg].cancelled==false, "This order has been cancelled");
        _;
    }

    modifier isSupplier(
        bytes32 _msg
    ) {
        require(userSupplyOrders[_msg].supplier==msg.sender, "You're not the supplier for this order");
        _;
    }

}