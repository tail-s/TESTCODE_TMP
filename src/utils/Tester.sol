// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import { IPoolRegistry } from "../interfaces/IPoolRegistry.sol";
import { IRiskFund } from "../interfaces/IRiskFund.sol";
import { IShortFall } from "../interfaces/IShortFall.sol";
import { IProtocolShareReserve } from "../interfaces/IProtocolShareReserve.sol";
import { IComptroller, Action } from "../interfaces/IComptroller.sol";
import { IVToken } from "../interfaces/IVToken.sol";
import { IPancakeswapV2Router } from "../interfaces/IPancakeswapV2Router.sol";
import { IResilientOracle } from "../interfaces/IResilientOracle.sol";
import { IBEP20 } from "../interfaces/IBEP20.sol";
import { IERC20 } from "../interfaces/IERC20.sol";

interface CheatCodes {
    function createFork(string calldata, uint256) external returns (uint256);
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function startPrank(address) external;
    function stopPrank() external;
}

contract Tester is Test {
    uint256 public constant BLOCK_NUMBER = 43_186_673;
    address DefaultProxyAdmin = 0x6beb6D2695B67FEb73ad4f172E8E2975497187e4;
    address admin = 0x939bD8d64c0A9583A7Dcea9933f7b21697ab6396;
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // BNB Chain Mainnet
    IPoolRegistry poolRegistry = IPoolRegistry(0x9F7b01A536aFA00EF10310A162877fd792cD0666);
    IRiskFund riskFund = IRiskFund(0xdF31a28D68A2AB381D42b380649Ead7ae2A76E42);
    IShortFall shortFall = IShortFall(0xf37530A8a810Fcb501AA0Ecd0B0699388F0F2209);
    IProtocolShareReserve protocolShareReserve = IProtocolShareReserve(0xCa01D5A9A248a830E9D93231e791B1afFed7c446);

    // oracle
    IResilientOracle oracle = IResilientOracle(0x6592b5DE802159F3E74B2486b091D11a8256ab8A);

    // Liquid Staked ETH Pool
    IComptroller comptroller = IComptroller(0xBE609449Eb4D76AD8545f957bBE04b596E8fC529);
    IPancakeswapV2Router swapRouter = IPancakeswapV2Router(0xfb4A3c6D25B4f66C103B4CD0C0D58D24D6b51dC1);
    IBEP20 wstETH = IBEP20(0x26c5e01524d2E6280A48F2c50fF6De7e52E9611C);
    IBEP20 weETH = IBEP20(0x04C0599Ae5A44757c0af6F9eC3b93da8976c150A);
    IBEP20 ETH = IBEP20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    IVToken vwstETH_ = IVToken(0x94180a3948296530024Ef7d60f60B85cfe0422c8);
    IVToken vweETH = IVToken(0xc5b24f347254bD8cF8988913d1fd0F795274900F);
    IVToken vETH = IVToken(0xeCCACF760FEA7943C5b0285BD09F601505A29c05);

    // Pool GameFi
    IComptroller gComptroller = IComptroller(0x1b43ea8622e76627B81665B1eCeBB4867566B963);
    IPancakeswapV2Router gSwapRouter = IPancakeswapV2Router(0x9B15462a79D0948BdDF679E0E5a9841C44aAFB7A);
    IBEP20 RACA = IBEP20(0x12BB890508c125661E03b09EC06E404bc9289040);
    IBEP20 FLOKI = IBEP20(0xfb5B838b6cfEEdC2873aB27866079AC55363D37E);
    IBEP20 USDD = IBEP20(0xd17479997F34dd9156Deef8F95A52D81D265be9c);
    IBEP20 USDT = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    IVToken vRACA = IVToken(0xE5FE5527A5b76C75eedE77FdFA6B80D52444A465);
    IVToken vFLOKI = IVToken(0xc353B7a1E13dDba393B5E120D4169Da7185aA2cb);
    IVToken vUSDD = IVToken(0x9f2FD23bd0A5E08C5f2b9DD6CF9C96Bfb5fA515C);
    IVToken vUSDT = IVToken(0x4978591f17670A846137d9d613e333C38dc68A37);

    function Pause(address Comptroller, address vToken) public {
        IComptroller compt = IComptroller(Comptroller);
        IVToken vtoken = IVToken(vToken);

        vm.startPrank(admin);
        address[] memory marketsList = new address[](1);
        marketsList[0] = vToken;

        Action[] memory actionsList = new Action[](5);
        actionsList[0] = Action.MINT;
        actionsList[1] = Action.REDEEM;
        actionsList[2] = Action.BORROW;
        actionsList[3] = Action.REPAY;
        actionsList[4] = Action.LIQUIDATE;

        compt.setActionsPaused(marketsList, actionsList, true);
        vm.stopPrank();

    }

    function unPause(address Comptroller, address vToken) public {
        
        IComptroller compt = IComptroller(Comptroller);
        IVToken vtoken = IVToken(vToken);

        vm.startPrank(admin);
        address[] memory marketsList = new address[](1);
        marketsList[0] = vToken;

        Action[] memory actionsList = new Action[](5);
        actionsList[0] = Action.MINT;
        actionsList[1] = Action.REDEEM;
        actionsList[2] = Action.BORROW;
        actionsList[3] = Action.REPAY;
        actionsList[4] = Action.LIQUIDATE;

        compt.setActionsPaused(marketsList, actionsList, false);
        vm.stopPrank();
    }

    function isPaused(address Comptroller, address market, Action action) public returns (bool) {
        IComptroller Compt = IComptroller(Comptroller);
        bool paused = Compt.actionPaused(market, action);
        return paused;
    }

    using stdStorage for StdStorage;
    address empty = address(0x3456);
    IVToken NOT_REGISTERED_VTOKEN = IVToken(empty);
    
}