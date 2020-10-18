pragma solidity 0.6.3;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockDAI is ERC20  {
    constructor() ERC20('DAI', 'Dai Stablecoin') public {}
    
    event NewMint(
        address indexed to,
        uint amount,
        uint date
    );

    function faucet(address to, uint amount) external {
        _mint(to, amount);
        emit NewMint(
            to,
            amount,
            now
        );
    }
}