// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { Tester } from "../src/utils/Tester.sol";
import { Action } from "../src/interfaces/IComptroller.sol";
import { CustomError } from "../src/utils/ErrorReporter.sol";

contract CollateralSupply is Test, Tester {

    address lender = address(0x1234);
    address lender2 = address(0x2345);
    uint amount = 1000 * 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(ETH), lender, amount);
        deal(address(ETH), lender2, amount);

        vm.startPrank(lender);
        ETH.approve(address(vETH), amount);
        vm.stopPrank();

        vm.startPrank(lender2);
        ETH.approve(address(vETH), amount);
        vm.stopPrank();
    }

    function test_supply_checkPause() public {
        Pause(address(comptroller), address(vETH));
        assertEq(isPaused(address(comptroller), address(vETH), Action.MINT), true);
        unPause(address(comptroller), address(vETH));
        assertEq(isPaused(address(comptroller), address(vETH), Action.MINT), false);

        // Simulation
        Pause(address(comptroller), address(vETH));

        vm.startPrank(lender);

        // MINT : 0, REDEEM : 1, BORROW : 2, REPAY : 3, LIQUIDATE : 5
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ActionPaused(address,uint8)")), address(vETH), uint8(0)));
        vETH.mint(amount);
        vm.stopPrank();

        unPause(address(comptroller), address(vETH));

        vm.startPrank(lender);
        vETH.mint(amount);
        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));
        (, uint liquidity,) = comptroller.getAccountLiquidity(lender);
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));
        uint expectedLiquidity = (price * amount * collateralFactorMantissa) / 1e18 / 1e18;
        assertEq(liquidity, expectedLiquidity);
        vm.stopPrank(); 
    }

    function test_supply_checkMarket() public {
        vm.startPrank(admin);
        assertEq(comptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);
        assertEq(comptroller.isMarketListed(address(vETH)), true);
        vm.stopPrank();
    }

    function test_supply_checkAccrueBlock() public {
        vm.startPrank(lender);
        vETH.mint(amount);
        assertEq(vETH.accrualBlockNumber(), block.number);
    }

    function test_supply_simple() public {
        vm.startPrank(lender);
        vETH.mint(amount);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));
        (, uint liquidity,) = comptroller.getAccountLiquidity(lender);
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));
        uint expectedLiquidity = (price * amount * collateralFactorMantissa) / 1e18 / 1e18;
        assertEq(liquidity, expectedLiquidity);
        vm.stopPrank();
    }

    function test_supply_simpleBehalf() public {
        vm.startPrank(lender);
        vETH.mintBehalf(lender2, amount);
        vm.stopPrank();

        vm.startPrank(lender2);
        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));
        (, uint liquidity,) = comptroller.getAccountLiquidity(lender2);
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));
        uint expectedLiquidity = (price * amount * collateralFactorMantissa) / 1e18 / 1e18;
        assertEq(liquidity, expectedLiquidity);
        vm.stopPrank();
    }
    
}
