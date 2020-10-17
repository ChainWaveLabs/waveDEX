const Dai = artifacts.require('mocks/MockDAI.sol');
const Bat = artifacts.require('mocks/MockBAT.sol');
const Yfi = artifacts.require('mocks/MockYFI.sol');
const Cwv = artifacts.require('mocks/ChainwaveToken.sol');

const DEX = artifacts.require('ChainwaveDex.sol');

contract ('ChainwaveDex', () => {
    let dai,bat,yfi,cwv;
    const [DAI, BAT, YFI, CWV] = ['DAI', 'BAT', 'YFI', 'CWV'].map(ticker => web3.utils.fromAscii(ticker))
    beforeEach(async()=>{
        ([dai,bat,yfi,cwv] = await Promise.all([
            Dai.new(),
            Bat.new(),
            Yfi.new(),
            Cwv.new()
        ]));

        const dex = await DEX.new();

        await Promise.all([
            dex.addToken(DAI, dai.address),
            dex.addToken(BAT, bat.address),
            dex.addToken(YFI, yfi.address),
            dex.addToken(CWV, cwv.address),
        ])

    })
})