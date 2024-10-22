// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";
import "forge-std/StdError.sol";

contract CollateralSupply is Test, Tester {

    address withdrawer = address(0x1234);
    address withdrawer2 = address(0x2345);
    uint amount = 10000 * 1e18;
    uint piece = 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), withdrawer, amount);
        deal(address(USDT), withdrawer2, piece);
        deal(address(USDT), admin, amount);

        vm.startPrank(withdrawer);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(withdrawer2);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(admin);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();
    }

    function getExchangeRate() internal returns (uint) {
        // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply.
        uint totalCash = vUSDT.getCash();
        assertEq(totalCash, USDT.balanceOf(address(vUSDT)));

        uint totalBorrows = vUSDT.totalBorrowsCurrent();
        uint totalReserves = vUSDT.totalReserves();
        uint totalSupply = vUSDT.totalSupply();
        uint exchangeRate = 1e18 * (totalCash + totalBorrows  - totalReserves) / totalSupply;
        return exchangeRate;
    }

    function test_withdraw_checkMarket() public {
        vm.startPrank(admin);
        assertEq(gComptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);
        assertEq(gComptroller.isMarketListed(address(vUSDT)), true);
        vm.stopPrank();
    }

    function test_withdraw_checkLTV() public {
        vm.startPrank(withdrawer);
        vUSDT.mint(amount);

        address[] memory vToken = new address[](1);
        vToken[0] = address(vUSDT);
        gComptroller.enterMarkets(vToken);

        uint value = vUSDT.balanceOf(withdrawer);
        
        (,,uint shortfall) = gComptroller.getHypotheticalAccountLiquidity(withdrawer, address(vUSDT), value + 1, 0);
        console.log("shortfall : ", shortfall);
        assertGt(shortfall, 0);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InsufficientLiquidity()"))));
        vUSDT.redeem(value + 1);
    }

    function test_withdraw_checkAccrueBlock() public {
        vm.startPrank(withdrawer);
        vUSDT.mint(amount);
        vUSDT.redeem(vUSDT.balanceOf(withdrawer));
        assertEq(vUSDT.accrualBlockNumber(), block.number);
    }

    function test_withdraw_checkAmount() public {
        vm.startPrank(withdrawer);
        vUSDT.mint(amount);

        uint exchangeRate = vUSDT.exchangeRateCurrent();
        uint vUSDTAmount = vUSDT.balanceOf(withdrawer);
        uint mintTokens = amount * 1e18 / exchangeRate;
        assertEq(vUSDTAmount, mintTokens);

        vm.expectRevert(stdError.arithmeticError);
        vUSDT.redeem(mintTokens + 1);
        vUSDT.redeem(mintTokens);
    }

    function test_withdraw_checkOut() public {
        vm.startPrank(withdrawer);
        vUSDT.mint(amount);
        assertEq(vUSDT.borrowBalanceCurrent(withdrawer), 0);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens); 

        address[] memory assetsIn = gComptroller.getAssetsIn(withdrawer);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(1);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InsufficientLiquidity()"))));
        gComptroller.exitMarket(address(vUSDT));
        vm.stopPrank();
    }

    function test_withdraw_simple() public {
        vm.startPrank(withdrawer);
        vUSDT.mint(amount);

        uint test = getExchangeRate();
        uint exchangeRate = vUSDT.exchangeRateCurrent();
        assertEq(test, exchangeRate);

        uint vUSDTAmount = vUSDT.balanceOf(withdrawer);
        uint mintTokens = amount * 1e18 / exchangeRate;
        assertEq(vUSDTAmount, mintTokens);

        vm.roll(block.number + 1);
        vUSDT.redeem(vUSDT.balanceOf(withdrawer));
        assertEq(vUSDT.balanceOf(withdrawer), 0);

        assert(USDT.balanceOf(withdrawer) > amount);
        vm.stopPrank();
    }

    function test_withdraw_simpleBehalf() public {
        vm.startPrank(withdrawer);
        vUSDT.mint(amount);

        gComptroller.updateDelegate(withdrawer2, true);
        vm.stopPrank();

        vm.roll(block.number + 1);

        vm.startPrank(withdrawer2);
        vUSDT.redeemBehalf(withdrawer, vUSDT.balanceOf(withdrawer));
        assertEq(vUSDT.balanceOf(withdrawer), 0);
        assert(USDT.balanceOf(withdrawer2) > amount);
        vm.stopPrank();
    }

    function test_withdraw_simpleUnderlying() public {

        vm.startPrank(withdrawer2);
        console.log("before redeem USDT : ", USDT.balanceOf(withdrawer2));
        vUSDT.mint(piece);
        
        console.log("before redeem vUSDT : ", vUSDT.balanceOf(withdrawer2));
        
        uint redeemAmount = piece * 9999999 / 10000000;
        console.log("Redeem Amount (in USDT): ", redeemAmount);

        vUSDT.redeemUnderlying(redeemAmount);

        // https://github.com/VenusProtocol/isolated-pools/blob/develop/contracts/VToken.sol
        // Line 977 ~ 979 div_ 및 mul_ 연산과정 후 Line 980에서 round up. 소수점 보정을 위해 redeemToken++. 
        // Core Poll과 다른 이 과정에서 오차 발생 예상
        assertGt(USDT.balanceOf(withdrawer2), redeemAmount);
        
        uint remainingVUSDT = vUSDT.balanceOf(withdrawer2);
        assert(remainingVUSDT > 0);
        vm.stopPrank();

        vm.startPrank(withdrawer);
        vUSDT.mint(amount);

        redeemAmount = amount / 2;
        vUSDT.redeemUnderlying(redeemAmount);

        // 오차 발생
        uint tolerance = 1e10 wei;
        assertApproxEqAbs(USDT.balanceOf(withdrawer), redeemAmount, tolerance);
        assertLt(USDT.balanceOf(withdrawer), redeemAmount + 1e10);
        assertGt(USDT.balanceOf(withdrawer), redeemAmount + 1e9);

        vm.stopPrank();

    }

    function test_withdraw_checkPause() public {
        Pause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REDEEM), true);
        unPause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REDEEM), false);
    }
}
