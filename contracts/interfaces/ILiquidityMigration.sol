// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

interface ILiquidityMigration {
    function stakeLpTokens(address strategyToken, uint256 amount, uint8 protocol) external;
    function stakeLpTokens(address ensoStrategy, address strategyToken, uint8 protocol, bytes memory migrationData, uint256 minimumAmount) external;
    function getStake(address account, address strategyToken) external view returns(uint256, address, uint8);
}
   /*
    function hasStaked(address _account, address _strategyToken) 
        public
        view
        returns(bool)
    {
       (uint256 amount, , ) = getStake(_account, _strategyToken);
       if(amount > 0){ return true; }
    }
*/