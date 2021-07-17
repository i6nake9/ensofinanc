//SPDX-License-Identifier: GPL-3.0-or-later

import { IAdapter } from "../interfaces/IAdapter.sol";
// import "../helpers/Whitelistable.sol";

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

contract Adapter is IAdapter {

    address public generic;
    address public module;

    constructor(
        address module_, 
        address generic_,
        address owner_
    )
    {
        module = module_;
        generic = generic_;
        _setOwner(owner_);
    }

    function outputTokens(address _lp) 
        public
        view
        override 
        returns (address[] memory outputs) 
    {
        return _outputTokens(_lp);
    }

    /**
    * @param _lp to view pool token
    * @return if token in whitelist
    */
    function isWhitelisted(address _lp) 
        public
        view
        override
        returns(bool)
    {
        return whitelisted[_lp];
    }

    function add(address _lp)
        public
        onlyOwner
    {
        _addEntry(address _lp);
    }

    function remove(address _lp)
        public
        onlyOwner
    {
        _removeEntry(address _lp);
    }

    function _addEntry(address _lp)
        internal
    {
        _add(_lp);
        _addUnderlying(_lp, outputTokens(_lp););
    }

    function _removeEntry(address _lp) 
        internal
    {
        _remove(_lp);
        _removeUnderlying(_lp);
    }


    
}
