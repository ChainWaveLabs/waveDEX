pragma solidity ^0.6.3;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20Detailed.sol';

contract MockYFI is ERC20 {
    constructor() ERC20('YFI', 'YFI token', 18) public {};

    function faucet(address to, uint amount) external {
        _mint(to, amount);
    }
}