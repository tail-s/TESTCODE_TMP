// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShortFall {

    // Functions
    function initialize(
        address riskFund_,
        uint256 minimumPoolBadDebt_,
        address accessControlManager_
    ) external;

    function placeBid(
        address comptroller,
        uint256 bidBps,
        uint256 auctionStartBlockOrTimestamp
    ) external;

    function closeAuction(address comptroller) external;

    function startAuction(address comptroller) external;

    function restartAuction(address comptroller) external;

    function updateNextBidderBlockLimit(uint256 nextBidderBlockOrTimestampLimit_) external;

    function updateIncentiveBps(uint256 incentiveBps_) external;

    function updateMinimumPoolBadDebt(uint256 minimumPoolBadDebt_) external;

    function updateWaitForFirstBidder(uint256 waitForFirstBidder_) external;

    function updatePoolRegistry(address poolRegistry_) external;

    function pauseAuctions() external;

    // Additional getter functions if needed
    function getCurrentMinimumPoolBadDebt() external view returns (uint256);
    function getCurrentIncentiveBps() external view returns (uint256);
    function areAuctionsPaused() external view returns (bool);
}
