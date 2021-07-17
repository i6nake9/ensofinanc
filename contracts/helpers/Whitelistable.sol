import "../helpers/Ownable.sol";


// SPDX-License-Identifier: WTFPL

pragma solidity 0.8.2;

abstract contract Whitelistable is Ownable {

    mapping(address => bool) private whitelisted;
    
    mapping (address => uint256) private count;
    mapping (address => mapping (address => bool)) private underlying;

    event Added(address token);
    event Removed(address token);

    /**
    * @dev Require adapter registered
    */
    modifier onlyWhitelisted(address _lp) {
        require(isWhitelisted(_lp), "Whitelistable#onlyWhitelisted: not whitelisted lp");
        _;
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

    function _add(address _lp)
        internal
    {
        require(!isWhitelisted(_lp), 'Whitelistable#_add: exists');
        whitelisted[_lp] = true;
        emit Added(_lp);
    }

    function _remove(address _lp) 
        internal
    {
        require(isWhitelisted(_lp), 'Whitelistable#_remove: not exist');
        whitelisted[_lp] = false;
        emit Removed(_lp);
    }

    function _addUnderlying(address _lp, address[] memory _underlying) 
        internal
    {
        require(count[_lp] == 0, 'Whitelistable#_addUnderlying: exists');
        for (uint256 i = 0; i < _underlying.length; i++) {
            underlying[_lp][underlying[i]] = true;
        }
        count[_lp] = underlying.length;
    }

    function _removeUnderlying(address _lp, address[] memory _underlying)
        internal
    {
        require(count[_lp] > 0, 'Whitelistable#_removeUnderlying: not exist');
        require(count == _underlying.length, 'Whitelistable#_removeUnderlying: incorrect length');
        for (uint256 i = 0; i < count[_lp]; i++) {
            delete underlying[_lp][_underlying[i]];
        }
        delete count[_lp];
    }
}
