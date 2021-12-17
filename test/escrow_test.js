const truffleAssert = require("truffle-assertions")
const Web3 = require('web3');

let web3 = new Web3(Web3.givenProvider || 'http://127.0.0.1:9545');

const Escrow = artifacts.require("Escrow");

require('dotenv').config();

contract("Escrow", accounts => {
    it("should allow supplier to receive payment for supply.", async() => {
        let escrow = await Escrow.deployed()
        let tx = await escrow.fundContractForSupplyOrder(accounts[1], { from: accounts[0], value: 1000 })
            //funded contract with 1000wei
        let message = tx.logs[0].args.message

        client_pk = process.env.PRIVATE_KEY

        let signed = await web3.eth.accounts.sign(message, client_pk)

        await escrow.confirmFulfilment(message, { from: accounts[1] }) //supplier confirms that goods hve been sent
        await escrow.confirmReceipt(message) // client confirms that goods have been received

        await truffleAssert.reverts(escrow.receivePayment(signed.signature, message)) // reverts as user is not supplier
        await truffleAssert.passes(escrow.receivePayment(signed.signature, message, { from: accounts[1] }))
    })
})