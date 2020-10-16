pragma solidity ^0.6.3;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';

contract MockYFI is ERC20 {
    constructor() ERC20('YFI', 'YFI token', 18) public {};
}