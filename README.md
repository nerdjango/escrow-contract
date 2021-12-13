# escrow-contract
An escrow payment channel: 
A client wants to pay a supplier for goods delivered. Client goes on your platform (your smart contract) and funds it with the amount and also sets the address of the supplier who can claim the funds.
When supplier wants to receive the escrowed amount, he goest to the smart contract and calls the receivePayment function passing in a signature. He derives the signature by signing a message; and the message signed is amount to be received only (keeping it simple). 
Now you have to verify that the person calling the receivePayment is a valid supplier and the address recovered from the signature is indeed the address set by the client when he/she funded the escrow.
