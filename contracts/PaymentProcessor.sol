pragma solidity ^0.5.0;

import { Ownable } from 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import { IERC20 } from 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import { UniswapExchangeInterface } from './uniswap/UniswapExchangeInterface.sol';
import { UniswapFactoryInterface } from './uniswap/UniswapFactoryInterface.sol';

contract PaymentProcessor is Ownable {
    uint256 constant UINT256_MAX = ~uint256(0);

    UniswapFactoryInterface public uniswapFactory;
    address public intermediaryToken;
    UniswapExchangeInterface intermediaryTokenExchange;

    constructor(UniswapFactoryInterface uniswapFactory_)
        public {
        uniswapFactory = uniswapFactory_;
    }

    function setIntermediaryToken(address token)
        onlyOwner
        public {
        intermediaryToken = token;
        if (token != address(0)) {
            intermediaryTokenExchange = UniswapExchangeInterface(uniswapFactory.getExchange(token));
            require(address(intermediaryTokenExchange) != address(0), "The token does not have an exchange");
        } else {
            intermediaryTokenExchange = UniswapExchangeInterface(address(0));
        }
    }

    function depositEther(uint64 orderId)
        payable
        external {
        require(msg.value > 0, "Minimal deposit is 0");
        uint256 amountBought = 0;
        if (intermediaryToken != address(0)) {
            amountBought = intermediaryTokenExchange.ethToTokenSwapInput.value(msg.value)(
                1 /* min_tokens */,
                UINT256_MAX /* deadline */);
        }
        emit EtherDepositReceived(orderId, msg.value, intermediaryToken, amountBought);
    }

    function withdrawEther(uint256 amount, address payable to)
        onlyOwner
        external {
        to.transfer(amount);
        emit EtherDepositWithdrawn(to, amount);
    }

    function withdrawToken(IERC20 token, uint256 amount, address to)
        onlyOwner
        external {
        require(token.transfer(to, amount), "Withdraw token failed");
    }

    function depositToken(uint64 orderId, address depositor, IERC20 inputToken, uint256 amount)
        hasExchange(address(inputToken))
        external {
        require(address(inputToken) != address(0), "Input token cannont be ZERO_ADDRESS");
        UniswapExchangeInterface tokenExchange = UniswapExchangeInterface(uniswapFactory.getExchange(address(inputToken)));
        require(inputToken.allowance(depositor, address(this)) >= amount, "Not enough allowance");
        inputToken.transferFrom(depositor, address(this), amount);
        inputToken.approve(address(tokenExchange), amount);
        uint256 amountBought = 0;
        if (intermediaryToken != address(0)) {
            amountBought = tokenExchange.tokenToTokenSwapInput(
                amount /* (input) tokens_sold */,
                1 /* (output) min_tokens_bought */,
                1 /*  min_eth_bought */,
                UINT256_MAX /* deadline */,
                intermediaryToken /* (input) token_addr */);
        } else {
            amountBought = tokenExchange.tokenToEthSwapInput(
                amount /* tokens_sold */,
                1 /* min_eth */,
                UINT256_MAX /* deadline */);
        }
        emit TokenDepositReceived(orderId, address(inputToken), amount, intermediaryToken, amountBought);
    }

    event EtherDepositReceived(uint64 indexed orderId, uint256 amount, address intermediaryToken, uint256 amountBought);
    event EtherDepositWithdrawn(address to, uint256 amount);
    event TokenDepositReceived(uint64 indexed orderId, address indexed inputToken, uint256 amount, address intermediaryToken, uint256 amountBought);

    modifier hasExchange(address token) {
        address tokenExchange = uniswapFactory.getExchange(token);
        require(tokenExchange != address(0), "Token doesn't have an exchange");
        _;
    }
}