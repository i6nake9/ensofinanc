//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "../LiquidityMigration.sol";

contract MockLiquidityMigration is LiquidityMigration {


    // function hasStaked(address account, address strategyToken) 
    //     public
    //     override(LiquidityMigration)
    // {
        
    // }

    constructor(Adapters[] memory acceptedAdapters, EnsoContracts memory contracts) LiquidityMigration(acceptedAdapters, contracts)
    {
        
    }


}