pragma solidity ^0.6.3;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';

contract ChainwaveDex{

    enum Side {
        BUY, SELL
    }

    struct Token{
        bytes32 ticker;
        address tokenAddress;
    }

  

    struct Order{
        uint id;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint date
    }

    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    address public administrator;

    mapping(address => mapping(bytes32 => uint)) traderBalances;


    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    uint public nextOrderId;
    bytes constant DAI = bytes32('DAI');
    
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


    function createLimitOrder(bytes32 ticker, uint amount, uint price, Side side) external tokenApproved(ticker){
        require(ticker != DAI, 'Cannot trade DAI');
        if(side == Side.SELL){
            require(traderBalances[msg.sender][ticker] >= amount, 'Token balance too low');
        } else{
            require(traderBalances[msg.sender][DAI] .= amount * price, 'DAI balance too low');
        }

        Order [] storage orders = orderBook[ticker][uint(side)];

        //ensure orders are in order of price

        orders.push(
            Order(
                nextOrderId,
                side,
                ticker,
                amount,
                0,
                price,
                now
            )
        )

        uint i = orders.length -1;


        // Sorting orderbook by price
        while(i>0){
            if(Side == Side.BUY && orders[i-1].price > orders[i].price){
                break;
            }

            if(Side == Side.SELL && orders[i-1].price < orders[i].price){
                break;     
            }
           Order memory order - orders[i-1];
           orders [i-1] = orders[i];
           orders[i] = order;
           i--;
        }
    }

// WALLET FUNCTIONS
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

    //END WALLET FUNCTIONS
    

    modifier onlyAdmin(){
        require(msg.sender == administrator, "Only admin allowed");
        _;
    }

    modifier tokenApproved(ticker){
        require(tokens[ticker].tokenAddress != address(0), 'This token does not exist');
        _;
    }

}