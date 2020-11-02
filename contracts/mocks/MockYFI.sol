pragma solidity ^0.6.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockYFI is ERC20 {
    constructor() public ERC20("YFI", "YFI token") {}

    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
