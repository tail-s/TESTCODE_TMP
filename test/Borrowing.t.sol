// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";
import { TokenErrorReporter } from "../src/utils/ErrorReporter.sol";

contract CollateralSupply is Test, Tester {

    address borrower = address(0x1234);
    address borrower2 = address(0x2345);
    address rich_man = address(0x9876);
    uint amount = 10000 * 1e18;
    uint borrowAmount = 100 * 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), borrower, amount);
        deal(address(USDT), borrower2, amount);

        vm.startPrank(borrower);
        USDT.approve(address(vUSDT), amount);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(borrower);
        assertEq(assetsIn[0], address(vUSDT));
        vm.stopPrank();

        vm.startPrank(borrower2);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();
    }

    function test_borrow_checkPause() public {
        Pause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.BORROW), true);
        unPause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.BORROW), false);
    }

    function test_borrow_checkMarket() public {
        vm.startPrank(admin);
        assertEq(gComptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);
        assertEq(gComptroller.isMarketListed(address(vUSDT)), true);
        vm.stopPrank();
    }

    function test_borrow_checkMembership() public {
        vm.startPrank(borrower2);

        bool result = gComptroller.checkMembership(borrower2, address(vUSDT));
        assertEq(result, false);

        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(borrower2);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(borrowAmount);
        result = gComptroller.checkMembership(borrower2, address(vUSDT));
        assertEq(result, true);

        vm.stopPrank();
    }

    function test_borrow_checkBorrowCap() public {
        uint totalBorrow = vUSDD.totalBorrowsCurrent();
        uint borrowCap = gComptroller.borrowCaps(address(vUSDD));
        uint gap = borrowCap - totalBorrow;
        console.log("totalBorrow : ", totalBorrow);
        console.log("borrowCap : ", borrowCap);

        require(borrowCap >= totalBorrow, "borrowCap is less than totalBorrow");

        vm.startPrank(rich_man);
        deal(address(vUSDT), rich_man, 10000000 * 1e18);
        
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("BorrowCapExceeded(address,uint256)")), address(vUSDD), uint256(borrowCap)));
        vUSDD.borrow(gap + 1);
        vUSDT.borrow(vUSDT.balanceOf(borrower));
    }

    function test_borrow_checkLTV() public {
        vm.startPrank(borrower);

        (,,uint shortfall) = gComptroller.getHypotheticalAccountLiquidity(borrower, address(vUSDT), 0, amount);
        console.log("shortfall : ", shortfall);
        assertGt(shortfall, 0);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InsufficientLiquidity()"))));
        vUSDT.borrow(amount);
        vUSDT.borrow(borrowAmount);
    }

    function test_borrow_checkAccrueBlock() public {
        vm.startPrank(borrower);
        vUSDT.borrow(vUSDT.balanceOf(borrower) / 2);
        assertEq(vUSDT.accrualBlockNumber(), block.number);
    }

    function testFail_borrow_checkAmount() public {
        vm.startPrank(borrower);
        deal(address(vUSDT), borrower, 1000000000000000 * 1e18);

        uint totalReserve = vUSDD.totalReserves();
        console.log("totalReserve : ", totalReserve);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("BorrowCashNotAvailable()"))));
        // _getCashPrior() - totalReserves < borrowAmount   
        vUSDD.borrow(USDD.balanceOf(address(vUSDD)) - totalReserve);
        vm.stopPrank();
    }

    function test_borrow_checkOut() public {
        vm.startPrank(borrower);
        vUSDD.borrow(1);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InsufficientLiquidity()"))));
        gComptroller.exitMarket(address(vUSDT));
        vm.stopPrank();
    }

    function test_borrow_simple() public {
        vm.startPrank(borrower);
        vUSDD.borrow(borrowAmount);
        assertEq(USDD.balanceOf(borrower), borrowAmount);
        vm.stopPrank();
    }

    function test_borrow_simpleBehalf() public {
        vm.startPrank(borrower);
        gComptroller.updateDelegate(borrower2, true);
        vm.stopPrank();

        vm.startPrank(borrower2);
        vUSDD.borrowBehalf(borrower, borrowAmount);

        assertEq(USDD.balanceOf(borrower2), borrowAmount);
        assertEq(vUSDD.borrowBalanceCurrent(borrower), borrowAmount);
        vm.stopPrank();
    }
    
}
