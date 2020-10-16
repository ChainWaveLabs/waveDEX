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
        address trader;
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

    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date

    )

    uint public nextOrderId;
    uint public nextTradeId;

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


    function createLimitOrder(bytes32 ticker, uint amount, uint price, Side side) tokenNotDai(ticker) tokenApproved(ticker) external {
        if(side == Side.SELL){
            require(traderBalances[msg.sender][ticker] >= amount, 'Token balance too low');
        } else{
            require(traderBalances[msg.sender][DAI] >= amount * price, 'DAI balance too low');
        }

        Order [] storage orders = orderBook[ticker][uint(side)];

        orders.push(
            Order(
                nextOrderId,
                msg.sender,
                side,
                ticker,
                amount,
                0,
                price,
                now
            )
        )

        uint i = orders.length -1;

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

    createMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side,
    ) tokenApproved(ticket) tokenNotDai(ticker) external{
        if(side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'Token balance too low');
        }

        Order[] storge orders = orderBook[ticker][uint(side == Side.BUY ? side.SELL : side.BUY)];
        uint i;
        uint unfilled = amount

        while(i < orders.length && unfilled > 0){
            uint liquidity = orders[i].amount - orders[i].filled;
            uint matched = (unfilled > liquidity) ? liquidity : unfilled;
            unfilled -= matched;
            orders[i].filled += matched;

            emit NewTrade(
               nextTradeId,
               orders[i].id,
               ticker,
               orders[i].trader,
               msg.sender,
               matched,
               orders[i].price,
               now
            );

            if(side == side.SELL){
                traderBalances[msg.sender][ticker] -= matched;
                traderBalances[msg.sender][DAI] += matched * orders[i].price;

                traderBalances[orders[i].trader][ticker] += matched;
                traderBalances[orders[i].trader][DAI] -= matched * orders[i].price;
            } 

            if(side == side.BUY){
                require(traderBalances[msg.sender][DAI] >= matched * orders[i].price, 'Dai balance too low');
                traderBalances[msg.sender][ticker] += matched;
                traderBalances[msg.sender][DAI] -= matched * orders[i].price;

                traderBalances[orders[i].trader][ticker] -= matched;
                traderBalances[orders[i].trader][DAI] += matched * orders[i].price;
            } 

            nextTradeId++;
            i++;
        }
        //remove filled orders

        uint j = 0;

        while(j < orders.length && orders[i].filled == orders[i].amount){
            for(uint k = j; k< orders.length -1; k++){
                orders[k] = orders[k+1];
                orders.pop();
                j++;
            }
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

    modifier tokenNotDai(ticker){
      require(ticker != DAI, 'Cannot trade DAI');
        _;
    }
}