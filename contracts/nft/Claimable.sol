pragma solidity ^0.8.0;

import "../interfaces/ILiquidityMigration.sol";
import "../ecosystem/openzeppelin/access/Ownable.sol";
import "../interfaces/IRoot1155.sol";

contract Claimable is Ownable {

    enum State {
        Pending,
        Active,
        Closed
    }
    State public _state;

    address public migration;
    address public collection;

    mapping (uint256 => bool) public claimed;

    event Claimed(address indexed account, uint256 protocol);
    event StateChange(uint8 changed);

    /**
    * @dev Require particular state
    */
    modifier onlyState(State state_) {
        require(state() == state_, "Claimable#onlyState: ONLY_STATE_ALLOWED");
        _;
    }

    /* assumption is enum ID will be the same as collection ID, 
     * and no further collections will be added whilst active
    */
    constructor(address _migration, address _collection){
        collection = _collection;
        migration = _migration;
    }

    function claim(address _strategy)
        public
        onlyState(State.Active)
    {
        (bool staked, uint256 protocol) = ILiquidityMigration(migration).hasStaked(msg.sender, _strategy);
        require(staked, "Claimable: Has not staked");
        require(!claimed[protocol], "Claimable: already claimed");
        require(IERC1155(collection).balanceOf(address(this), protocol) > 0, "Claimable: no NFTs left");
        claimed[protocol] = true;
        IERC1155(collection).safeTransferFrom(address(this), msg.sender, protocol, 1, "");
    }
    
    function master() 
        public
        onlyState(State.Active)
    {
        require(!claimed[max()], "Claimable#master: claimed");
        for (uint256 i = 0; i < max(); i++) {
            require(claimed[i], "Claimable#master: not all");
        }
        IERC1155(collection).safeTransferFrom(address(this), msg.sender, max(), 1, "");
    }

    function wipe() 
        public
        onlyOwner
    {
        _stateChange(State.Closed);
        for (uint256 i = 0; i < max(); i++) {
            IRoot1155(collection).
            burn(
                address(this), 
                i, 
                IERC1155(collection).balanceOf(address(this), i)
            );
        }
    }

    function stateChange(State state_)
        public
        onlyOwner
    {
        _stateChange(state_);
    }

    function _stateChange(State state_) 
        private
    {
        require(_state != state_, "Claimable#changeState: current");
        _state = state_;
        emit StateChange(uint8(_state));
    }

    function max() 
        public
        view
        returns (uint256)
    {
        return IRoot1155(collection).getMaxTokenID();
    }

    /**
     * @return The current state of the escrow.
     */
    function state() public view virtual returns (State) {
        return _state;
    }
}