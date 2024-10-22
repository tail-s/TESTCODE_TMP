// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolShareReserve {

    // Structs
    struct DistributionConfig {
        Schema schema;
        address destination;
        uint256 percentage;
    }

    // Enums
    enum Schema { ADDITIONAL_REVENUE, PROTOCOL_RESERVES }
    enum IncomeType { SPREAD, OTHER } // Add other income types as needed

    // Functions
    function initialize(address _accessControlManager, uint256 _loopsLimit) external;
    function setPoolRegistry(address _poolRegistry) external;
    function addOrUpdateDistributionConfigs(DistributionConfig[] calldata configs) external;
    function removeDistributionConfig(Schema schema, address destination) external;
    function releaseFunds(address comptroller, address[] calldata assets) external;
    function getUnreleasedFunds(address comptroller, Schema schema, address destination, address asset) external view returns (uint256);
    function totalDistributions() external view returns (uint256);
    function getPercentageDistribution(address destination, Schema schema) external view returns (uint256);
    function updateAssetsState(address comptroller, address asset, IncomeType incomeType) external;
}
