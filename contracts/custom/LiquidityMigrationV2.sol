//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import { SafeERC20, IERC20 } from "../ecosystem/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@enso/contracts/contracts/interfaces/IStrategyProxyFactory.sol";
import "@enso/contracts/contracts/interfaces/IStrategyController.sol";
import "@enso/contracts/contracts/helpers/StrategyTypes.sol";
import "../interfaces/IAdapter.sol";
import "./interfaces/IMigrationController.sol";
import "./interfaces/ILiquidityMigrationV2.sol";
import "../helpers/Timelocked.sol";
import "./Migrator.sol";


contract LiquidityMigrationV2 is ILiquidityMigrationV2, Migrator, Timelocked, StrategyTypes {
    using SafeERC20 for IERC20;

    address public controller;
    address public migrationCoordinator;

    mapping (address => bool) public adapters; // adapter -> bool
    mapping (address => uint256) public stakedCount; // adapter -> user count
    mapping (address => address) public strategies; // lp -> enso strategy
    mapping (address => mapping (address => uint256)) public staked; // user -> lp -> stake

    event Staked(address adapter, address strategy, uint256 amount, address account);
    event Migrated(address adapter, address lp, address strategy, address account);
    event Created(address adapter, address lp, address strategy, address account);
    event Refunded(address lp, uint256 amount, address account);

    /**
    * @dev Require adapter registered
    */
    modifier onlyRegistered(address adapter) {
        require(adapters[adapter], "Not registered");
        _;
    }

    /**
    * @dev Require adapter allows lp
    */
    modifier onlyWhitelisted(address adapter, address lp) {
        require(IAdapter(adapter).isWhitelisted(lp), "Not whitelist");
        _;
    }

    constructor(
        address[] memory adapters_,
        uint256 unlock_,
        uint256 modify_
    )
        Timelocked(unlock_, modify_, msg.sender)
    {
        for (uint256 i = 0; i < adapters_.length; i++) {
            adapters[adapters_[i]] = true;
        }
    }

    function setStrategy(address lp, address strategy) external onlyOwner {
        require(
            IStrategyController(controller).initialized(strategy),
            "Not enso strategy"
        );
        if (strategies[lp] != address(0)) {
          // This value can be changed as long as no migration is in progress
          require(IERC20(strategies[lp]).balanceOf(address(this)) == 0, "Already set");
        }
        strategies[lp] = strategy;
    }

    function setStake(address user, address lp, address adapter, uint256 amount) external override {
        require(msg.sender == migrationCoordinator, "Wrong sender");
        _stake(user, lp, adapter, amount);
    }

    function stake(
        address lp,
        address adapter,
        uint256 amount
    )
        external
    {
        require(amount > 0, "No amount");
        IERC20(lp).safeTransferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, lp, adapter, amount);
    }

    function buyAndStake(
        address lp,
        address adapter,
        address exchange,
        uint256 minAmountOut,
        uint256 deadline
    )
        external
        payable
    {
        require(msg.value > 0, "No value");
        _buyAndStake(lp, msg.value, adapter, exchange, minAmountOut, deadline);
    }

    function batchMigrate(
        address[] memory users,
        address lp
    )
        external
        override
        onlyOwner
        onlyUnlocked
    {
        address strategy = strategies[lp];
        require(strategy != address(0), "Strategy not initialized");
        uint256 totalBalance;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 userBalance = staked[user][lp];
            require(userBalance > 0, "No stake");
            totalBalance += userBalance;
            delete staked[user][lp];
            staked[user][strategy] = userBalance;
        }
        uint256 strategyBalanceBefore = IStrategy(strategy).balanceOf(address(this));
        IERC20(lp).safeTransfer(controller, totalBalance);
        IMigrationController(controller).migrate(IStrategy(strategy), IERC20(lp), totalBalance);
        uint256 strategyBalanceAfter = IStrategy(strategy).balanceOf(address(this));
        assert((strategyBalanceAfter - strategyBalanceBefore) == totalBalance);
    }

    function withdraw(address lp) external {
        uint256 amount = staked[msg.sender][lp];
        require(amount > 0, "No stake");
        delete staked[msg.sender][lp];

        IERC20(lp).safeTransfer(msg.sender, amount);
        emit Refunded(lp, amount, msg.sender);
    }

    function claim(address lp) external {
        address strategy = strategies[lp];
        // If strategy is not set, user should not have any balance staked
        uint256 amount = staked[msg.sender][strategy];
        require(amount > 0, "No claim");
        delete staked[msg.sender][strategy];

        IERC20(strategy).safeTransfer(msg.sender, amount);
        emit Migrated(address(0), lp, strategy, msg.sender);
    }

    function _stake(
        address user,
        address lp,
        address adapter,
        uint256 amount
    )
        internal
        onlyRegistered(adapter)
        onlyWhitelisted(adapter, lp)
    {
        staked[user][lp] += amount;
        stakedCount[adapter] += 1;
        emit Staked(adapter, lp, amount, user);
    }

    function _buyAndStake(
        address lp,
        uint256 amount,
        address adapter,
        address exchange,
        uint256 minAmountOut,
        uint256 deadline
    )
        internal
    {
        uint256 balanceBefore = IERC20(lp).balanceOf(address(this));
        IAdapter(adapter).buy{value: amount}(lp, exchange, minAmountOut, deadline);
        uint256 amountAdded = IERC20(lp).balanceOf(address(this)) - balanceBefore;
        _stake(msg.sender, lp, adapter, amountAdded);
    }

    function updateController(address newController)
        external
        onlyOwner
    {
        require(controller != newController, "Controller already exists");
        controller = newController;
    }

    function updateCoordinator(address newCoordinator)
        external
        onlyOwner
    {
        require(migrationCoordinator != newCoordinator, "Coordinator already exists");
        migrationCoordinator = newCoordinator;
    }

    function addAdapter(address adapter)
        external
        onlyOwner
    {
        require(!adapters[adapter], "Adapter already exists");
        adapters[adapter] = true;
    }

    function removeAdapter(address adapter)
        external
        onlyOwner
    {
        require(adapters[adapter], "Adapter does not exist");
        adapters[adapter] = false;
    }

    function hasStaked(address account, address lp)
        external
        view
        returns(bool)
    {
        return staked[account][lp] > 0;
    }

    function getStakeCount(address adapter)
        external
        view
        returns(uint256)
    {
        return stakedCount[adapter];
    }
}
