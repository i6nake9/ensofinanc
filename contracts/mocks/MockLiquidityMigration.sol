//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "../LiquidityMigration.sol";

contract MockLiquidityMigration {

    bool public staked;
    uint256 public protocol;

    function set(bool _staked, uint256 _protocol) 
        public
    {
        staked = _staked;
        protocol = _protocol;
    }

    function hasStaked(address account, address strategyToken) 
        public
        view
        returns(bool, uint256)
    {
        return(staked, protocol);
    }
}