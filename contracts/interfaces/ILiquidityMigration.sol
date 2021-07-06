// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

interface ILiquidityMigration {
    function stakeLpTokens(address strategyToken, uint256 amount, uint8 protocol) external;
    function stakeLpTokens(address ensoStrategy, address strategyToken, uint8 protocol, bytes memory migrationData, uint256 minimumAmount) external;
    function hasStaked(address account, address strategyToken) external returns(bool, uint256);
}