//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import { SafeERC20, IERC20 } from "../ecosystem/openzeppelin/token/ERC20/utils/SafeERC20.sol";


contract MockLiquidityMigration {
    using SafeERC20 for IERC20;

    struct Stake {
        uint256 amount;
        uint256 protocol;
    }

    mapping (address => mapping (address => Stake)) public stakes;

    function stake(address strategyToken, uint256 amount, uint256 protocol) 
        public
    {
        IERC20(strategyToken).safeTransferFrom(msg.sender, address(this), amount);
        Stake storage stake = stakes[msg.sender][strategyToken];
        stake.amount += amount;
        stake.protocol = protocol;
    }

    function hasStaked(address account, address strategyToken) 
        public
        view
        returns(bool, uint256)
    {
        Stake storage stake = stakes[account][strategyToken];
        return(
            stake.amount > 0,
            stake.protocol
        );
    }
}