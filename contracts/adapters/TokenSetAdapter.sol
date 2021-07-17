//SPDX-License-Identifier: GPL-3.0-or-later

import { SafeERC20, IERC20 } from "../ecosystem/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IAdapter } from "../interfaces/IAdapter.sol";

interface ISetToken {
    function getComponents() external view returns (address[] memory);
}

interface ISetModule {
    function redeem(address _setToken, uint256 _quantity, address _to) external;
}


pragma solidity 0.8.2;

/// @title Token Sets Vampire Attack Contract
/// @author Enso.finance (github.com/amateur-dev)
/// @notice Adapter for redeeming the underlying assets from Token Sets

contract TokenSetAdapter is IAdapter {

    function _outputTokens(address _lp) 
        internal 
        view 
        returns (address[] memory outputs) 
    {
        outputs = ISetToken(_lp).getComponents();
    }

    function encodeExecute(address _lp, address _amount) 
        public
        override
        view
        onlyWhitelisted(_lp)
        returns(Call memory call)
    {
        call = Call(
            payable(address(setModule)),
            abi.encodeWithSelector(
                setModule.redeem.selector, 
                _lp,
                _amount,
                generic
            ),
            0
        );
    }
}
