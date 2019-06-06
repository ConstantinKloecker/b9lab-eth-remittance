const Remittance = artifacts.require("Remittance");
const truffleAssert = require("truffle-assertions");
//const { promisify } = require('util');

contract("Testing Destroyable features of Remittance contract", accounts => {
    let instance;
    const [owner, alice, bob, carol] = accounts;
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

    ///@notice: doesn't seem to work
    // const waitNBlocks = async (n) => {
    //     const sendAsync = promisify(web3.currentProvider.sendAsync);
    //     await Promise.all(
    //         [...Array(n).keys()].map(i =>
    //             sendAsync({
    //                 jsonrpc: '2.0',
    //                 method: 'evm_mine',
    //                 id: i
    //             })
    //         )
    //     );
    // };

    beforeEach("Deploying clean Remittance contract", async () => {
        instance = await Remittance.new({ from: owner });
    });

    it("Fresh contract's state is set to default", async () => {
        assert.equal(await instance.getBeneficiary.call(), ZERO_ADDRESS, "Fresh contract's beneficiary should be 0 address");
        assert.equal(await instance.getDeadline.call(), 0, "Fresh contract's deadline should be 0");
    });

    it("Owner can initiate destruction", async () => {
        let destruction = await instance.initiateDestruction(owner, { from: owner });
        let tx = await web3.eth.getTransaction(destruction.tx);
        let targetBlock = await tx.blockNumber + 5760;
        assert.equal(await instance.getDeadline({ from: owner }), targetBlock, "Deadline should be qual to targetBlock in contract state");
        assert.equal(await instance.getBeneficiary({ from: owner }), owner, "Owner should be the beneficiary in contract state");
        // truffleAssert.eventEmitted(destruction, "LogDestructionInitiated", (ev) => {
        //     return ev.admin === owner && ev.deadline === targetBlock && ev.beneficiary === owner;
        // });
    });

    it("Non-owner can not initiate destruction", async () => {
        truffleAssert.fails(
            instance.initiateDestruction(alice, { from: alice })
        );
    });

    it("Owner can cancel initiated destruction", async () => {
        await instance.initiateDestruction(owner, { from: owner });
        let cancellation = await instance.cancelDestruction({ from: owner });
        assert.equal(await instance.getDeadline(), 0, "Deadline should be 0");
        truffleAssert.eventEmitted(cancellation, "LogDestructionCanceled", (ev) => {
            return ev.admin === owner;
        });
    });

    it("Non-owner can not cancel initiated destruction", async () => {
        await instance.initiateDestruction(owner, { from: owner });
        await truffleAssert.fails(
            instance.cancelDestruction({ from: alice })
        );
    });

    ///@notice: mining blocks doesn't work
    // it("Destruction can be completed after deadline", async () => {
    //     // extra: get funds into the contract
    //     await instance.initiateDestruction(owner, { from: owner });
    //     await waitNBlocks(5761);
    //     let completion = await instance.completeDestruction({ from: alice });
    //     truffleAssert.eventEmitted(completion, "LogDestructionCompleted", (ev));
    //     // extra: check that owner receives funds from contract
    // });

    it("Destruction can not be completed before deadline", async () => {
        await instance.initiateDestruction(owner, { from: owner });
        await truffleAssert.fails(
            instance.completeDestruction({ from: owner })
        );
    });
});