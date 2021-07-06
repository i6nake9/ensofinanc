pragma solidity ^0.8.0;

import '../ecosystem/openzeppelin/access/Ownable.sol';
import "../ecosystem/openzeppelin/token/ERC1155/IERC1155.sol";
import "../interfaces/ILiquidityMigration.sol";

/**
 * @title Claimable
 */
contract Claimable is Ownable {

    enum State {
        Pending,
        Active,
        Closed
    }

    State private _state;
    
    address public migration;
    address public collection; // update()

    mapping (uint8=>bool) public claimed; // protocol = false/true

    event StateChange(uint8 old, uint8 updated);

    /**
    * @dev Require particular state
    */
    modifier onlyState(State state_) {
        require(state() == state_, "Claimable#onlyState: ONLY_STATE_ALLOWED");
        _;
    }

    // assumption is enum ID will be the same as collection ID
    constructor(address _migration, address _collection){
        collection = _collection;
        migration = _migration;
    }

    function claim(address _strategy)
        public
        onlyState(State.Active)
    {
        (uint256 amount, , uint8 protocol ) = ILiquidityMigration(migration).getStake(msg.sender, _strategy);
        require(!claimed[protocol], "Claimable: already claimed");
        require(amount > 0, "Claimable: Has not staked");
        require(IERC1155(collection).balanceOf(address(this), protocol) > 0, "Claimable: no NFTs left");
        claimed[protocol] = true;
        IERC1155(collection).safeTransferFrom(address(this), msg.sender, protocol, 1, "");
    }

    function stateChange(State state_)
        public
        onlyOwner
    {
        //emit StateChange(_state, state_);
        _state = state_;
    }


    // user specific
    //function claimed(address protocol) {}
    
    // overall
    //function available(address protocol) {}

    /*
        Keep track
    */

    /**
     * @return The current state of the escrow.
     */
    function state() public view virtual returns (State) {
        return _state;
    }
}

/*
    1. mint to this address

*/
