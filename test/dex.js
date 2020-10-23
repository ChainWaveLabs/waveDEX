const { assert } = require("console");
const { expectRevert } = require('@openzeppelin/test-helpers');
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const Dai = artifacts.require('mocks/MockDAI.sol');
const Bat = artifacts.require('mocks/MockBAT.sol');
const Yfi = artifacts.require('mocks/MockYFI.sol');
const Cwv = artifacts.require('mocks/ChainwaveToken.sol');
const DEX = artifacts.require('ChainwaveDex.sol');

const SIDE = {
    BUY: 0,
    SELL: 1
}

contract('ChainwaveDex', (accounts) => {

    let dai, bat, yfi, cwv, dex;

    const [DAI, BAT, YFI, CWV] = ['DAI', 'BAT', 'YFI', 'CWV']
        .map(ticker => web3.utils.fromAscii(ticker))

    const [trader1, trader2] = [accounts[1], accounts[2]];

    beforeEach(async () => {
        ([dai, bat, yfi, cwv] = await Promise.all([
            Dai.new(),
            Bat.new(),
            Yfi.new(),
            Cwv.new()
        ]));

        dex = await DEX.new();

        await Promise.all([
            dex.addToken(DAI, dai.address),
            dex.addToken(BAT, bat.address),
            dex.addToken(YFI, yfi.address),
            dex.addToken(CWV, cwv.address),
        ])

        const amount = web3.utils.toWei('1000');

        const seedTokenBalance = async (token, trader) => {
            await token.faucet(trader, amount);
            await token.approve(dex.address, amount, { from: trader })
        }

        await Promise.all([
            [dai, bat, yfi, cwv]
                .map(
                    token => seedTokenBalance(token, trader1)
                )
        ])

        await Promise.all([
            [dai, bat, yfi, cwv]
                .map(
                    token => seedTokenBalance(token, trader2)
                )
        ])
    })

    it('Should deposit tokens', async () => {

        const amount = web3.utils.toWei('10000');
        await dex.deposit(amount, DAI, { from: trader1 })
        const balance = await dex.traderBalances(trader1, DAI);
        assert(balance.toString() === amount);
    })

    it('Should Not deposit tokens if token doesnt exist', async () => {
        await expectRevert(
            dex.deposit(
                web3.utils.toWei('100'),
                web3.utils.fromAscii('FAKE TOKEN'),
                { from: trader1 }
            ),
            'This token does not exist'
        )
    })

    it('Should Withdraw tokens', async () => {

        const amount = web3.utils.toWei('100');
        await dex.deposit(amount, DAI, { from: trader1 });
        await dex.withdraw(amount, DAI, { from: trader1 });

        const [balanceDex, balanceDai] = await Promise.all([
            dex.traderBalances(trader1, DAI),
            dex.balanceOf(trader1)
        ]);
        assert(balanceDex.isZero());
        assert(balanceDex.toString() === web3.utils.toWei('1000'));
    })

    it('Should NOT withdraw if token does not exist', async () => {
        await expectRevert(
            dex.withdraw(
                web3.utils.toWei('100'),
                web3.utils.fromAscii('FAKE TOKEN'),
                { from: trader1 }
            ),
            'This token does not exist'
        )
    })

    // it('should NOT withdraw tokens if balance too low', async () => {
    //     await dex.deposit(
    //       web3.utils.toWei('100'),
    //       DAI,
    //       {from: trader1}
    //     );

    //     await expectRevert(
    //       dex.withdraw(
    //         web3.utils.toWei('1000'),
    //         DAI,
    //         {from: trader1}
    //       ),
    //       'balance too low'
    //     );
    //   });

    it('should create a limit order', async () => {

        const amount = web3.utils.toWei('10000');
        await dex.deposit(amount, DAI, { from: trader1 });
        await dex.createLimitOrder(
            CWV,
            web3.utils.toWei('10'),
            10,
            SIDE.BUY,
            { from: trader1 }
        );

        let buyOrders = await dex.getOrders(CWV, SIDE.BUY);
        let sellOrders = await dex.getOrders(CWV, SIDE.SELL);

        assert(buyOrders.length === 1);
        assert(buyOrders[0].trader === trader1);
        assert(buyOrders[0].ticker === web3.utils.padRight(CWV, 64));
        assert(buyOrders[0].price === "10");
        assert(buyOrders[0].amount === web3.utils.toWei('10'));
        assert(sellOrders.length === 0);

        await dex.deposit(web3.utils.toWei('200'), DAI, { from: trader2 });
        await dex.createLimitOrder(
            CWV,
            web3.utils.toWei('10'),
            10,
            SIDE.BUY,
            { from: trader2 }
        );

        buyOrders = await dex.getOrders(CWV, SIDE.BUY);
        sellOrders = await dex.getOrders(CWV, SIDE.SELL);

        assert(buyOrders.length === 2);
        assert(buyOrders[0].trader === trader2);
        assert(buyOrders[1].trader === trader1);
        assert(sellOrders.length === 0);

        await dex.deposit(web3.utils.toWei('10'), DAI, { from: trader2 });
        await dex.createLimitOrder(
            CWV,
            web3.utils.toWei('9'),
            10,
            SIDE.BUY,
            { from: trader2 }
        );

        buyOrders = await dex.getOrders(CWV, SIDE.BUY);
        sellOrders = await dex.getOrders(CWV, SIDE.SELL);
        assert(buyOrders.length === 3);
        assert(buyOrders[0].trader === trader2);
        assert(buyOrders[1].trader === trader1);
        assert(buyOrders[2].trader === trader2);
        assert(sellOrders.length === 0);
    });
});