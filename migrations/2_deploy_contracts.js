const Migrations = artifacts.require("Migrations");
const Dai = artifacts.require('mocks/MockDAI.sol');
const Bat = artifacts.require('mocks/MockBAT.sol');
const Yfi = artifacts.require('mocks/MockYFI.sol');
const Cwv = artifacts.require('mocks/ChainwaveToken.sol');
const DEX = artifacts.require('ChainwaveDex.sol');

const [DAI, BAT, YFI, CWV] = ['DAI', 'BAT', 'YFI', 'CWV']
    .map(ticker => web3.utils.fromAscii(ticker))

module.exports = async function (deployer, _network, accounts) {
    const [trader1, trader2, trader3, trader4, _] = accounts;

    await Promise.all(
        [Dai, Bat, Yfi, Cwv, DEX].map(contract => deployer.deploy(contract))
    );

    const [dai, bat, yfi, cwv, dex] = await Promise.all(
        [Dai, Bat, Yfi, Cwv, DEX].map(contract => contract.deployed())
    );

    await Promise.all([
        dex.addToken(DAI, dai.address),
        dex.addToken(BAT, bat.address),
        dex.addToken(YFI, yfi.address),
        dex.addToken(CWV, cwv.address),
    ])

    const amount = web3.utils.toWei('10000');

    const seedTokenBalance = async (token, trader) => {
        await token.faucet(trader, amount);
        await token.approve(dex.address, amount, { from: trader })
        const ticker = await token.name();
        await dex.deposit(amount, web3.utils.fromAscii(ticker), { from: trader })
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

    await Promise.all([
        [dai, bat, yfi, cwv]
            .map(
                token => seedTokenBalance(token, trader3)
            )
    ])

    await Promise.all([
        [dai, bat, yfi, cwv]
            .map(
                token => seedTokenBalance(token, trader4)
            )
    ])
};
