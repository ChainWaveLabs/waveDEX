const DAI = artifacts.require('mocks/MockDAI.sol');
const BAT = artifacts.require('mocks/MockBAT.sol');
const YFI = artifacts.require('mocks/MockYFI.sol');
const CWV = artifacts.require('mocks/ChainwaveToken.sol');

contract ('ChainwaveDex', () => {
    let dai,bat,yfi,cwv;
    beforeEach(async()=>{
        
        ([dai,bat,yfi,cwv] = await Promise.all([
            DAI.new(),
            BAT.new(),
            YFI.new(),
            CWV.new()
        ]));
    })
})