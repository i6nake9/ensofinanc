//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import { SafeERC20, IERC20 } from "../ecosystem/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./AbstractAdapter.sol";

interface ISetToken {
    function moduleStates(address _module) external view returns (uint);
    function getComponents() external view returns (address[] memory);
}

interface ISetModule {
    function redeem(address _setToken, uint256 _quantity, address _to) external;
}

/// @title Token Sets Vampire Attack Contract
/// @author Enso.finance (github.com/EnsoFinance)
/// @notice Adapter for redeeming the underlying assets from Token Sets

contract TokenSetAdapter is AbstractAdapter {
    using SafeERC20 for IERC20;

    address public generic;
    ISetModule public setModule;
    ISetModule public debtSetModule;

    constructor(
        ISetModule setModule_,
        ISetModule debtSetModule_,
        address generic_,
        address owner_
    ) AbstractAdapter(owner_)
    {
        setModule = setModule_;
        debtSetModule = debtSetModule_;
        generic = generic_;
    }

    function outputTokens(address _lp)
        public
        view
        override
        returns (address[] memory outputs)
    {
        outputs = ISetToken(_lp).getComponents();
    }

    function encodeExecute(address _lp, uint256 _amount)
        public
        override
        view
        onlyWhitelisted(_lp)
        returns(Call memory call)
    {

        // we are getting the _lp over in this fx call
        // if the _lp is a debt one then we will have to redeem in the debtSetModule
        // otherwise it should call the setModule
        // the way to do it is that we should get the modules from the _lp and if that array debtSetModule, use that else confirm that it has the setModule and then use that.
        ISetModule module;
        if (ISetToken(_lp).moduleStates(address(setModule)) == 2) {
            require (ISetToken(_lp).moduleStates(address(debtSetModule)) == 0);
            module = setModule;
        } else if (ISetToken(_lp).moduleStates(address(debtSetModule)) == 2) {
            require (ISetToken(_lp).moduleStates(address(setModule)) == 0);
            module = debtSetModule;
        }
        call = Call(
            payable(address(module)),
            abi.encodeWithSelector(
                module.redeem.selector,
                _lp,
                _amount,
                generic
            ),
            0
        );
    }
}
