pragma solidity 0.6.3;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract ChainwaveDex{

    using SafeMath for uint;

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
        uint date;
    }

    uint public nextOrderId;
    uint public nextTradeId;
    bytes32 constant DAI = bytes32('DAI');
    bytes32[] public tokenList;
    address public administrator;

    mapping(bytes32 => Token) public tokens;
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
    );
    
    constructor() public {
        administrator = msg.sender;
    }

    function getOrders(bytes32 ticker,Side side)
    external 
    view 
    returns (Order[] memory)
    {
        return orderBook[ticker][uint(side)];
    }

    function getTokens()
    external 
    view 
    returns (Token[] memory)
    {
        Token[] memory _tokens = new Token[](tokenList.length);
        
        for(uint i = 0; i< tokenList.length; i++){
            _tokens[i] = Token(
                tokens[tokenList[i]].ticker,
                tokens[tokenList[i]].tokenAddress
            );
        }
        
        return _tokens;
    }

    function addToken(bytes32 ticker,address tokenAddress) 
    onlyAdmin() 
    external{

            tokens[ticker] = Token(ticker,tokenAddress);
            tokenList.push(ticker);

        }

    function createLimitOrder(
        bytes32 ticker, 
        uint amount, 
        uint price, 
        Side side) 
        tokenNotDai(ticker) 
        tokenApproved(ticker) 
        external {

        if(side == Side.SELL){
            require(traderBalances[msg.sender][ticker] >= amount, 'Token balance too low');
        } else{
            require(traderBalances[msg.sender][DAI] >= amount.mul(price), 'DAI balance too low');
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
        );

        uint i = orders.length > 0 ? orders.length -1 : 0;

        while( i > 0 ){
            if(side == Side.BUY && orders[i-1].price > orders[i].price){
                break;
            }

            if(side == Side.SELL && orders[i-1].price < orders[i].price){
                break;     
            }
           Order memory order = orders[i-1];
           orders [i-1] = orders[i];
           orders[i] = order;
           i = i.sub(1);
        }

        nextOrderId = nextOrderId.add(1);
    }

    function createMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side
    ) 
    tokenApproved(ticker) 
    tokenNotDai(ticker) 
    external {
        if(side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'Token balance too low');
        }

        Order[] storage orders = orderBook[ticker][uint(side == Side.BUY ? Side.SELL : Side.BUY)];
        uint i;
        uint unfilled = amount;

        while(i < orders.length && unfilled > 0){
            uint liquidity = orders[i].amount.sub(orders[i].filled) ;
            uint matched = (unfilled > liquidity) ? liquidity : unfilled;
            unfilled = unfilled.sub(matched);
            orders[i].filled = orders[i].filled.add(matched);

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

            if(side == Side.SELL){
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(matched);
                traderBalances[msg.sender][DAI] =  traderBalances[msg.sender][DAI].add(matched.mul(orders[i].price));

                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].add(matched);
                traderBalances[orders[i].trader][DAI] =  traderBalances[orders[i].trader][DAI].sub(matched.mul(orders[i].price));
            } 

            if(side == Side.BUY){
                require(traderBalances[msg.sender][DAI] >= matched.mul(orders[i].price), 'Dai balance too low');
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(matched);
                traderBalances[msg.sender][DAI] = traderBalances[msg.sender][DAI].sub(matched.mul(orders[i].price)) ;

                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].sub(matched);
                traderBalances[orders[i].trader][DAI] = traderBalances[orders[i].trader][DAI].add(matched.mul(orders[i].price));
            } 

            nextTradeId = nextTradeId.add(1);
            i = i.add(1);

        }
        //remove filled orders

        uint j = 0;

        while(j < orders.length && orders[i].filled == orders[i].amount){
            for(uint k = j; k < orders.length - 1; k++){
                orders[k] = orders[k+1];
                orders.pop();
                j=j.add(1);
            }
        }
    }

// WALLET FUNCTIONS
    // function deposit(uint amount, bytes32 ticker) tokenApproved(ticker) external {
    //     IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender,address(this),amount);
    //     traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
    // }

    function deposit(uint amount,bytes32 ticker)
        tokenApproved(ticker)
        external {
        IERC20(tokens[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
    }
    
    function withdraw(uint amount, bytes32 ticker) tokenApproved(ticker) external {
        require(traderBalances[msg.sender][ticker] >= amount, "Balance too low");
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender,amount);
    }

    //END WALLET FUNCTIONS
    modifier onlyAdmin(){
        require(msg.sender == administrator, "Only admin allowed");
        _;
    }

    modifier tokenApproved(bytes32 ticker){
        require(tokens[ticker].tokenAddress != address(0), 'This token does not exist');
        _;
    }

    modifier tokenNotDai(bytes32 ticker){
      require(ticker != DAI, 'Cannot trade DAI');
        _;
    }
}