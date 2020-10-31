const Migrations = artifacts.require("Migrations");
const Dai = artifacts.require('mocks/MockDAI.sol');
const Bat = artifacts.require('mocks/MockBAT.sol');
const Yfi = artifacts.require('mocks/MockYFI.sol');
const Cwv = artifacts.require('mocks/ChainwaveToken.sol');
const DEX = artifacts.require('ChainwaveDex.sol');

const [DAI, BAT, YFI, CWV] = ['DAI', 'BAT', 'YFI', 'CWV']
.map(ticker => web3.utils.fromAscii(ticker))

module.exports = async function (deployer) {
  deployer.deploy(Migrations);

  await Promise.all(
      [ Dai, Bat, Yfi,Cwv,DEX].map(contract => deployer.deploy(contract))
  );

  const [dai,bat,yfi,cwv, dex] = await Promise.all(
      [Dai, Bat, Yfi,Cwv,DEX].map(contract => contract.deployed())
  );

  await Promise.all([
    dex.addToken(DAI, dai.address),
    dex.addToken(BAT, bat.address),
    dex.addToken(YFI, yfi.address),
    dex.addToken(CWV, cwv.address),
])
};
