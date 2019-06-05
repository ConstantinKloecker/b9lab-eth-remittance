// const Remittance = artifacts.require("Remittance");
// const truffleAssert = require("truffle-assertions");

// contract("Testing Ownable features of Remittance contract", accounts => {
//     let instance;
//     const [owner, alice, bob, carol] = accounts;

//     beforeEach("Deploying clean Remittance contract", async () => {
//         instance = await Remittance.new({ from: owner });
//     });

//     it("Deployer is contract owner", async () => {
//         assert.equal(await instance.getOwner({ from: owner }), owner, "Deployer should be the owner");
//     });

//     it("Owner can transfer ownership", async () => {
//         let ownership = await instance.changeOwner(alice, { from: owner });
//         assert.equal(await instance.getOwner({ from: owner }), alice, "Alice should be the new owner");
//         truffleAssert.eventEmitted(ownership, "LogNewOwner", (ev) => {
//             return ev.oldOwner === owner && ev.newOwner === alice;
//         });
//     });

//     it("Non-owner can not transfer ownership", async () => {
//         await truffleAssert.fails(
//             instance.changeOwner(alice, { from: alice })
//         );
//     });
// });