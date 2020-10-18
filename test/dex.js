const { assert } = require("console");
const { expectRevert} = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const Dai = artifacts.require('mocks/MockDAI.sol');
const Bat = artifacts.require('mocks/MockBAT.sol');
const Yfi = artifacts.require('mocks/MockYFI.sol');
const Cwv = artifacts.require('mocks/ChainwaveToken.sol');
const DEX = artifacts.require('ChainwaveDex.sol');

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

    it('Should deposit tokens', async()=>{
      
        const amount = web3.utils.toWei('100');
        await dex.deposit(amount, DAI, {from:trader1})
        const balance = await dex.traderBalances(trader1,DAI);
        console.log("bal aft", balance.toString());
        assert(balance.toString() === amount);
    })

    it('Should Not deposit tokens if token doesnt exist', async()=>{
     await expectRevert(
         dex.deposit(
             web3.utils.toWei('100'),
             web3.utils.fromAscii('FAKE TOKEN'), 
             {from: trader1}
         ),
         'This token does not exist'
     )
    })

    it('Should Withdraw tokens', async()=>{
    
        const amount = web3.utils.toWei('100');
        await dex.deposit(amount, DAI, {from:trader1});
        await dex.withdraw(amount, DAI, {from:trader1});

        const [balanceDex, balanceDai] = await Promise.all([
            dex.traderBalances(trader1,DAI),
            dex.balanceOf(trader1)
        ]);
        assert(balanceDex.isZero());
        assert(balanceDex.toString() === web3.utils.toWei('1000'));
    })

    it('Should NOT withdraw if token does not exist', async()=>{
        await expectRevert(
            dex.withdraw(
                web3.utils.toWei('100'),
                web3.utils.fromAscii('FAKE TOKEN'), 
                {from: trader1}
            ),
            'This token does not exist'
        )
    })

    it('Should NOT withdraw if trader balance is less than amount to withdraw (too low)', async()=>{
        const amount = web3.utils.toWei('100');
        await dex.deposit(amount, DAI, {from:trader1});

        await expectRevert(
            dex.withdraw(
                web3.utils.toWei('1000'),
                DAI, 
                {from: trader1}
            ),
            'Balance too low'
        )
    });
})