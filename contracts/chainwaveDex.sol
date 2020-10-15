pragma solidity 0.6.3;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';

contract ChainwaveDex{
    struct Token{
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    address public administrator;

    mapping(address => mapping(bytes32 => uint)) traderBalances;
    
    constructor() public {
        administrator = msg.sender;
    }

    function addToken(
        bytes32 ticker,
        address tokenAddress) onlyAdmin() external{

            tokens[ticker] = Token(ticker,tokenAddress);
            tokenList.push(ticker);

        }
    )


    function deposit(amount, ticker) tokenApproved(ticker)  external {
        IERC20(tokens[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount;
        );
        traderBalances[msg.sender][ticker] +=amount;
    }
    
    function withdraw(amount, ticker) tokenApproved(ticker) external {

        require(traderBalances[msg.sender] >=amount, "Balance too low");

        traderBalances[msg.sender][ticker] -= amount;

        IERC20(tokens[ticker].tokenAddress).transfer(
            msg.sender,
             amount;
        );

    }
    

    modifier onlyAdmin(){
        require(msg.sender == administrator, "Only admin allowed");
        _;
    }

    modifier tokenApproved(ticker){
        require(tokens[ticker].tokenAddress != address(0), 'This token does not exist');
        _;
    }

}