pragma solidity ^0.6.3;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockBAT is ERC20 {
    constructor() ERC20('BAT', 'Bat token') public {}

    function faucet(address to, uint amount) external {
        _mint(to, amount);
    }
}