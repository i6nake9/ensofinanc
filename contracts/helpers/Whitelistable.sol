import "../helpers/Ownable.sol";


// SPDX-License-Identifier: WTFPL

pragma solidity 0.8.2;

abstract contract Whitelistable is Ownable {

    mapping(address => bool) public whitelisted;
    
    mapping (address => uint256) public count;
    mapping (address => mapping (address => bool)) public underlying;

    event Added(address token);
    event Removed(address token);

    /**
    * @dev Require adapter registered
    */
    modifier onlyWhitelisted(address _lp) {
        require(whitelisted[_lp], "Whitelistable#onlyWhitelisted: not whitelisted lp");
        _;
    }

    /**
    * @dev add pool token to whitelist
    * @param _lp pool address
    */
    function add(address _lp) 
        public 
        onlyOwner 
    {
        _add(_lp);
        addToUnderlyingTokenMapping(_lp);
    }

    /**
    * @dev batch add pool token to whitelist
    * @param _tokens[] array of pool address
    */
    function addBatch(address[] memory _tokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _add(_tokens[i]);
            addToUnderlyingTokenMapping(_tokens[i]);
        }
    }

    /**
    * @dev remove pool token from whitelist
    * @param _lp pool address
    */
    function remove(address _lp) 
        public
        onlyOwner
    {
        _remove(_lp);
        removeFromUnderlyingTokenMapping(_lp);
    }

    /**
    * @dev batch remove pool token from whitelist
    * @param _tokens[] array of pool address
    */
    function removeBatch(address[] memory _tokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _remove(_tokens[i]);
            removeFromUnderlyingTokenMapping(_tokens[i]);
        }
    }

    function _add(address _lp) 
        internal
    {
        require(!whitelisted[_lp], 'Whitelistable#_add: exists');
        whitelisted[_lp] = true;
        emit Added(_lp);
    }

    function _remove(address _lp) 
        internal
    {
        require(whitelisted[_lp], 'Whitelistable#_remove: not exist');
        whitelisted[_lp] = false;
        emit Removed(_lp);
    }
}
