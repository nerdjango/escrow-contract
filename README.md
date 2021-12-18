# escrow-contract
An escrow payment channel: 
A client wants to pay a supplier for goods. Client goes on your platform (your smart contract) and funds it with the amount and also sets the address of the supplier who can claim the funds.
When supplier wants to receive the escrowed amount, he goes to the smart contract and calls the receivePayment function passing in a signature. He derives the signature by signing a message; and the message signed is a combination of the amount to be received, the contract address and a nonce that increments every time the contract is funded by a client (keeping it simple). 
Now you have to verify that the person calling the receivePayment is a valid supplier and the address recovered from the signature is indeed the address set by the client when he/she funded the escrow.
