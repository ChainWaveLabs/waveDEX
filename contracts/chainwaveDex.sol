pragma solidity 0.6.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ChainwaveDex {
    using SafeMath for uint256;

    enum Side {BUY, SELL}

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    struct Order {
        uint256 id;
        address trader;
        Side side;
        bytes32 ticker;
        uint256 amount;
        uint256 filled;
        uint256 price;
        uint256 date;
    }

    uint256 public nextOrderId;
    uint256 public nextTradeId;
    bytes32 constant DAI = bytes32("DAI");
    bytes32[] public tokenList;
    address public administrator;

    mapping(bytes32 => Token) public tokens;
    mapping(address => mapping(bytes32 => uint256)) public traderBalances;
    mapping(bytes32 => mapping(uint256 => Order[])) public orderBook;

    // event NewTrade(
    //     uint256 tradeId,
    //     uint256 orderId,
    //     bytes32 indexed ticker,
    //     address indexed trader1,
    //     address indexed trader2,
    //     uint256 amount,
    //     uint256 price,
    //     uint256 date
    // );

    constructor() public {
        administrator = msg.sender;
    }

    function getOrders(bytes32 ticker, Side side)
        external
        view
        returns (Order[] memory)
    {
        return orderBook[ticker][uint256(side)];
    }

    function getTokens() external view returns (Token[] memory) {
        Token[] memory _tokens = new Token[](tokenList.length);
        for (uint256 i = 0; i < tokenList.length; i++) {
            _tokens[i] = Token(
                tokens[tokenList[i]].ticker,
                tokens[tokenList[i]].tokenAddress
            );
        }
        return _tokens;
    }

    function addToken(bytes32 ticker, address tokenAddress)
        external
        onlyAdmin()
    {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }

    function createLimitOrder(
        bytes32 ticker,
        uint256 amount,
        uint256 price,
        Side side
    ) external tokenNotDai(ticker) tokenApproved(ticker) {
        if (side == Side.SELL) {
            require(
                traderBalances[msg.sender][ticker] >= amount,
                "Token balance too low"
            );
        } else {
            require(
                traderBalances[msg.sender][DAI] >= amount.mul(price),
                "DAI balance too low"
            );
        }

        Order[] storage orders = orderBook[ticker][uint256(side)];

        orders.push(
            Order(nextOrderId, msg.sender, side, ticker, amount, 0, price, now)
        );

        uint256 i = orders.length > 0 ? orders.length - 1 : 0;

        while (i > 0) {
            if (side == Side.BUY && orders[i - 1].price > orders[i].price) {
                break;
            }

            if (side == Side.SELL && orders[i - 1].price < orders[i].price) {
                break;
            }
            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;
            i = i.sub(1);
        }

        nextOrderId = nextOrderId.add(1);
    }

    function createMarketOrder(
        bytes32 ticker,
        uint256 amount,
        Side side
    ) external tokenApproved(ticker) tokenNotDai(ticker) {
        if (side == Side.SELL) {
            require(
                traderBalances[msg.sender][ticker] >= amount,
                "Token balance too low"
            );
        }

        Order[] storage orders = orderBook[ticker][uint256(
            side == Side.BUY ? Side.SELL : Side.BUY
        )];
        uint256 i;
        uint256 unfilled = amount;

        while (i < orders.length && unfilled > 0) {
            uint256 liquidity = orders[i].amount.sub(orders[i].filled);
            uint256 matched = (unfilled > liquidity) ? liquidity : unfilled;
            unfilled = unfilled.sub(matched);
            orders[i].filled = orders[i].filled.add(matched);

            // emit NewTrade(
            //     nextTradeId,
            //     orders[i].id,
            //     ticker,
            //     orders[i].trader,
            //     msg.sender,
            //     matched,
            //     orders[i].price,
            //     now
            // );

            if (side == Side.SELL) {
                traderBalances[msg.sender][ticker] = traderBalances[msg
                    .sender][ticker]
                    .sub(matched);
                traderBalances[msg.sender][DAI] = traderBalances[msg
                    .sender][DAI]
                    .add(matched.mul(orders[i].price));

                traderBalances[orders[i]
                    .trader][ticker] = traderBalances[orders[i].trader][ticker]
                    .add(matched);
                traderBalances[orders[i].trader][DAI] = traderBalances[orders[i]
                    .trader][DAI]
                    .sub(matched.mul(orders[i].price));
            }

            if (side == Side.BUY) {
                require(
                    traderBalances[msg.sender][DAI] >=
                        matched.mul(orders[i].price),
                    "Dai balance too low"
                );
                traderBalances[msg.sender][ticker] = traderBalances[msg
                    .sender][ticker]
                    .add(matched);
                traderBalances[msg.sender][DAI] = traderBalances[msg
                    .sender][DAI]
                    .sub(matched.mul(orders[i].price));

                traderBalances[orders[i]
                    .trader][ticker] = traderBalances[orders[i].trader][ticker]
                    .sub(matched);
                traderBalances[orders[i].trader][DAI] = traderBalances[orders[i]
                    .trader][DAI]
                    .add(matched.mul(orders[i].price));
            }

            nextTradeId = nextTradeId.add(1);
            i = i.add(1);
        }
        //remove filled orders

        uint256 j = 0;

        while (j < orders.length && orders[j].filled == orders[j].amount) {
            for (uint256 k = j; k < orders.length - 1; k++) {
                orders[k] = orders[k + 1];
                orders.pop();
                j = j.add(1);
            }
        }
    }

    function deposit(uint256 amount, bytes32 ticker)
        external
        tokenApproved(ticker)
    {
        IERC20(tokens[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker]
            .add(amount);
    }

    function withdraw(uint256 amount, bytes32 ticker)
        external
        tokenApproved(ticker)
    {
        require(
            traderBalances[msg.sender][ticker] >= amount,
            "Balance too low"
        );
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker]
            .sub(amount);
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    //END WALLET FUNCTIONS
    modifier onlyAdmin() {
        require(msg.sender == administrator, "Only admin allowed");
        _;
    }

    modifier tokenApproved(bytes32 ticker) {
        require(
            tokens[ticker].tokenAddress != address(0),
            "This token does not exist"
        );
        _;
    }

    modifier tokenNotDai(bytes32 ticker) {
        require(ticker != DAI, "Cannot trade DAI");
        _;
    }
}
