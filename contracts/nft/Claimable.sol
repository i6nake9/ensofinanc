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
    State private _state;

    address public migration;
    address public collection;

    mapping (address => mapping (uint256 => bool)) claimed;

    event Claimed(address indexed account, uint256 protocol);
    event StateChange(uint8 changed);
    event Migration(address migration);
    event Collection(address collection);

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

    /**
     * @notice claim NFT for staking LP
     * @param _strategyToken address of strategy
     */
    function claim(address _strategyToken)
        public
        onlyState(State.Active)
    {
        (bool staked, uint256 protocol) = ILiquidityMigration(migration).hasStaked(msg.sender, _strategyToken);
        require(staked, "Claimable: Has not staked");
        require(!claimed[msg.sender][protocol], "Claimable: already claimed");
        require(IERC1155(collection).balanceOf(address(this), protocol) > 0, "Claimable: no NFTs left");
        claimed[msg.sender][protocol] = true;
        IERC1155(collection).safeTransferFrom(address(this), msg.sender, protocol, 1, "");
    }
    
    /**
     * @notice you wanna be a masta good old boi?
     */
    function master() 
        public
        onlyState(State.Active)
    {
        require(!claimed[msg.sender][max()], "Claimable#master: claimed");
        for (uint256 i = 0; i < max(); i++) {
            require(claimed[msg.sender][i], "Claimable#master: not all");
            require(IERC1155(collection).balanceOf(msg.sender, i) > 0, "Claimable#master: not holding");
        }
        IERC1155(collection).safeTransferFrom(address(this), msg.sender, max(), 1, "");
    }

    /**
     * @notice we wipe it, and burn all - should have got in already
     */
    function wipe(uint256 _start, uint256 _end, uint8 _id)
        public
        onlyOwner
    {
        require(_end <= max(), "Claimable#Wipe: out of bounds");
        for (uint256 start = _start; start < _end; start++) {
            IRoot1155(collection).
            burn(
                address(this), 
                start,
                IERC1155(collection).balanceOf(address(this), _id)
            );
        }
    }

    /**
     * @notice emergency from deployer change state
     * @param state_ to change to
     */
    function stateChange(State state_)
        public
        onlyOwner
    {
        _stateChange(state_);
    }

    /**
     * @notice emergency from deployer change migration
     * @param _migration to change to
     */
    function updateMigration(address _migration)
        public
        onlyOwner
    {
        require(_migration != migration, 'Claimable#UpdateMigration: exists');
        migration = _migration;
        emit Migration(migration);
    }

    /**
     * @notice emergency from deployer change migration
     * @param _collection to change to
     */
    function updateCollection(address _collection)
        public
        onlyOwner
    {
        require(_collection != collection, 'Claimable#UpdateCollection: exists');
        collection = _collection;
        emit Collection(collection);
    }

    /**
     * @return max claimable
     */
    function max() 
        public
        view
        returns (uint256)
    {
        return IRoot1155(collection).getMaxTokenID();
    }

    /**
     * @return current state.
     */
    function state() public view virtual returns (State) {
        return _state;
    }

    function _stateChange(State state_) 
        private
    {
        require(_state != state_, "Claimable#changeState: current");
        _state = state_;
        emit StateChange(uint8(_state));
    }
}