const PaymentProcessor = artifacts.require("PaymentProcessor");
const { shouldFail } = require("openzeppelin-test-helpers");
const { web3tx } = require("./test_common");

contract("PaymentProcessor", accounts => {
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
    const admin = accounts[0];
    const customer1 = accounts[1];
    const customer2 = accounts[2];
    const hacker = accounts[9];
    let chainId;
    let pp;

    before(async () => {
        chainId = await web3.eth.net.getId();
        console.log("chainId is", chainId);
        console.log("customer1 is", customer1);
        console.log("admin is", admin);
    });

    beforeEach(async () => {
        console.log("creating new pp for testing");
        pp = await web3tx(PaymentProcessor.new, "PaymentProcessor.new")(ZERO_ADDRESS);
        console.log(`PaymentProcessor created at ${pp.address}`);
    });

    it("deposit and withdraw ether", async () => {
        await web3tx(pp.depositEther, "depositEther", {
            inLogs: [{
                name: "EtherDepositReceived",
                args: {
                    orderId: "1",
                    amount: web3.utils.toWei("0.1", "ether")
                }
            }]
        })(1, { value: web3.utils.toWei("0.1", "ether"), from: customer1 });
        await web3tx(pp.depositEther, "depositEther", {
            inLogs: [{
                name: "EtherDepositReceived",
                args: {
                    orderId: "2",
                    amount: web3.utils.toWei("0.2", "ether"),
                    intermediaryToken: "0x0000000000000000000000000000000000000000"
                }
            }]
        })(2, { value: web3.utils.toWei("0.2", "ether"), from: customer2 });
        shouldFail(pp.withdrawEther(web3.utils.toWei("0.3", "ether"), admin, { from: hacker }));
        const balanceBefore = new web3.utils.BN(await web3.eth.getBalance(admin));
        let tx = await web3tx(pp.withdrawEther, "withdrawEther", {
            inLogs: [{
                name: "EtherDepositWithdrawn",
                args: {
                    to: admin,
                    amount: web3.utils.toWei("0.3", "ether")
                }
            }]
        })(web3.utils.toWei("0.3", "ether"), admin, { from: admin });
        const balanceAfter = new web3.utils.BN(await web3.eth.getBalance(admin));
        assert.equal(balanceAfter.sub(balanceBefore).add(tx.txCost).toString(), web3.utils.toWei("0.3", "ether"));
    });
});
