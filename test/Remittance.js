const Remittance = artifacts.require("Remittance");
const truffleAssert = require("truffle-assertions");

const { toBN, toWei } = web3.utils;

contract("Testing main features of Remittance contract", accounts => {
    let instance;
    let [owner, alice, bob, carol] = accounts;
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

    beforeEach("Deploying clean Remittance contract", async () => {
        instance = await Remittance.new({ from: owner });
    });

    it("Users can start a transfer", async () => {
        let secret = web3.utils.asciiToHex("DoNotShareThisPassword");
        let deadline = 6000;
        let amount = 1000;
        let secretHash = await instance.createSecretHash.call(secret, bob, { from: alice });
        let fee = await instance.getFee.call({ from: owner });
        let transfer = await instance.startTransfer(carol, deadline, secretHash, { from: alice, value: amount });
        let tx = await web3.eth.getTransaction(transfer.tx);
        let targetBlock = await tx.blockNumber + deadline;
        // truffleAssert.eventEmitted(transfer, "LogNewTransfer", (ev) => {
        //     return ev.secretHash === secretHash && ev.sender === alice && ev.exchange === carol && ev.amount === (amount - fee) && ev.deadline === targetBlock;
        //     // change value toBn?
        // });

        let fxTransfer = await instance.transferList(secretHash, { from: owner });
        assert.equal(fxTransfer.sender, alice, "Alice should be the sender in the contract's state");
        assert.equal(fxTransfer.amount, amount - fee, "Amount - fee should be the amount in the contract's state");
        assert.equal(fxTransfer.deadline, targetBlock, "Deadline should be targetBlock in the contract's state");
        assert.equal(await web3.eth.getBalance(instance.address), amount, "Contract's balance should be equal to amount");
    });

    it("Users can not start a transfer with invalid input data", async () => {
        let secret = web3.utils.asciiToHex("DoNotShareThisPassword");
        let secretHash = await instance.createSecretHash.call(secret, carol, { from: alice });

        // amount < fee
        await truffleAssert.fails(
            instance.startTransfer(carol, 6000, secretHash, { from: alice, value: 20 })
        );

        // deadline below 5760
        await truffleAssert.fails(
            instance.startTransfer(carol, 5000, secretHash, { from: alice, value: 1000 })
        );

        // deadline above 57600
        await truffleAssert.fails(
            instance.startTransfer(carol, 60000, secretHash, { from: alice, value: 1000 })
        );

        // exchange == address(0)
        await truffleAssert.fails(
            instance.startTransfer(ZERO_ADDRESS, 6000, secretHash, { from: alice, value: 1000 })
        );

        // exchange == msg.sender
        await truffleAssert.fails(
            instance.startTransfer(alice, 6000, secretHash, { from: alice, value: 1000 })
        );

        // already existing secret
        await instance.startTransfer(carol, 6000, secretHash, { from: alice, value: 1000 });
        await truffleAssert.fails(
            instance.startTransfer(carol, 6000, secretHash, { from: alice, value: 1000 })
        );
    });

    it("User can complete a valid transfer", async () => {
        let secret = web3.utils.asciiToHex("DoNotShareThisPassword");
        let secretHash = await instance.createSecretHash.call(secret, carol, { from: alice });
        await instance.startTransfer(carol, 6000, secretHash, { from: alice, value: 1000 });
        let completion = await instance.completeTransfer(secretHash, secret, { from: carol });
        truffleAssert.eventEmitted(completion, "LogTransferCompleted", (ev) => {
            return ev.secretHash === secretHash;
        });
        assert.equal(await instance.balances.call(carol, { from: carol }), 1000 - 100, "Carol's balance should have been updated in the contract's state");
    });

    it("User can not complete a invalid transfer", async () => {
        let secret = web3.utils.asciiToHex("DoNotShareThisPassword");
        let secretHash = await instance.createSecretHash.call(secret, carol, { from: alice });
        await instance.startTransfer(carol, 6000, secretHash, { from: alice, value: 1000 });
        let secret2 = web3.utils.asciiToHex("WrongPassword");
        await truffleAssert.fails(
            instance.completeTransfer(secretHash, secret2, { from: carol })
        );
    });

    // TODO user can resolve transfer with valid conditions

    // TODO user can not resolve transfer with invalid conditions

    it("User can withdraw available balance", async () => {
        let secret = web3.utils.asciiToHex("DoNotShareThisPassword");
        let secretHash = await instance.createSecretHash.call(secret, carol, { from: alice });
        await instance.startTransfer(carol, 6000, secretHash, { from: alice, value: 1000 });
        await instance.completeTransfer(secretHash, secret, { from: carol });
        let withdrawal = await instance.withdraw({ from: carol });
        let balance = await instance.balances.call(carol, { from: carol });
        // truffleAssert.eventEmitted(withdrawal, "LogWithdrawal", (ev) => {
        //     return ev.user === carol && ev.amount === balance;
        //     // toBN?
        // });
    });

    it("User with zero balance cannot withdraw funds", async () => {
        truffleAssert.fails(instance.withdraw({ from: alice }));
    });

    it("Secret is hashed correctly", async () => {
        let secret = web3.utils.asciiToHex("DoNotShareThisPassword");
        let hashedSecret1 = await instance.createSecretHash(secret, alice, { from: owner });
        let hashedSecret2 = await instance.createSecretHash(secret, alice, { from: owner });
        assert.equal(hashedSecret1, hashedSecret2, "Secret hash should be deterministic for the same inputs");

        // let localHash = web3.utils.keccak256("DoNotShareThisPassword", alice);
        // assert.equal(localHash, hashedSecret1, "Local hash should be equal to contract's hash");
    });
});