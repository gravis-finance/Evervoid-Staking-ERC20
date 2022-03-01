//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMintableToken.sol";

contract GravisStaking is Ownable {
    using SafeCast for uint256;
    using SafeCast for int256;

    IERC20 public grvx;

    IMintableToken public fuel;

    uint256 public fuelPerGrvxPerSecond;
    uint256 public lockPeriod;

    mapping(address => uint256) public stakeOf;
    mapping(address => uint256) public lockOf;

    uint256 public totalStakes;

    uint256 public lastRewardDistribution;

    uint256 private constant MAGNITUDE = 2**128;

    uint256 private _magnifiedRewardPerShare;

    mapping(address => int256) private _magnifiedRewardCorrections;

    mapping(address => uint256) private _withdrawnRewardOf;

    constructor(
        IERC20 grvx_,
        IMintableToken fuel_,
        uint256 rewardStart_,
        uint256 fuelPerGrvxPerYear_,
        uint256 lockPeriod_
    ) {
        if (rewardStart_ != 0) {
            require(rewardStart_ >= block.timestamp, "Reward start too early");
        } else {
            rewardStart_ = block.timestamp;
        }

        grvx = grvx_;
        fuel = fuel_;
        lastRewardDistribution = rewardStart_;
        fuelPerGrvxPerSecond = fuelPerGrvxPerYear_ / (365 days);
        lockPeriod = lockPeriod_;
    }

    // PUBLIC FUNCTIONS

    function stake(uint256 amount) external {
        _distributeRewards();

        grvx.transferFrom(msg.sender, address(this), amount);

        if (stakeOf[msg.sender] == 0) {
            lockOf[msg.sender] = block.timestamp + lockPeriod;
        }

        stakeOf[msg.sender] += amount;
        totalStakes += amount;
        _magnifiedRewardCorrections[msg.sender] -= (
            (_magnifiedRewardPerShare * amount).toInt256()
        );
    }

    function unstake(uint256 amount) external {
        require(block.timestamp > lockOf[msg.sender], "Tokens still locked");

        _distributeRewards();

        stakeOf[msg.sender] -= amount;

        totalStakes -= amount;
        _magnifiedRewardCorrections[msg.sender] += (
            (_magnifiedRewardPerShare * amount).toInt256()
        );

        grvx.transfer(msg.sender, amount);
    }

    function claimReward() external {
        _distributeRewards();

        uint256 reward = _rewardOf(msg.sender, _magnifiedRewardPerShare);
        _withdrawnRewardOf[msg.sender] += reward;
        fuel.mint(msg.sender, reward);
    }

    // RESTRICTED FUNCTIONS

    function setFuelPerGrvxPerYear(uint256 fuelPerGrvxPerYear_, uint256 lockPeriod_)
        external
        onlyOwner
    {
        _distributeRewards();

        fuelPerGrvxPerSecond = fuelPerGrvxPerYear_ / (365 days);
        lockPeriod = lockPeriod_;
    }

    // VIEW FUNCTIONS

    function rewardOf(address account) public view returns (uint256) {
        uint256 currentRewardPerShare = _magnifiedRewardPerShare;
        if (block.timestamp > lastRewardDistribution && totalStakes > 0) {
            currentRewardPerShare +=
                (fuelPerGrvxPerSecond *
                    (block.timestamp - lastRewardDistribution) *
                    MAGNITUDE) /
                10**18;
        }
        return _rewardOf(account, currentRewardPerShare);
    }

    function _rewardOf(address account, uint256 currentRewardPerShare)
        private
        view
        returns (uint256)
    {
        uint256 accumulatedReward = ((
            (currentRewardPerShare * stakeOf[account]).toInt256()
        ) + _magnifiedRewardCorrections[account]).toUint256() / MAGNITUDE;
        return accumulatedReward - _withdrawnRewardOf[account];
    }

    // INTERNAL FUNCTIONS

    function _distributeRewards() private {
        if (block.timestamp > lastRewardDistribution) {
            if (totalStakes > 0) {
                _magnifiedRewardPerShare +=
                    (fuelPerGrvxPerSecond *
                        (block.timestamp - lastRewardDistribution) *
                        MAGNITUDE) /
                    10**18;
            }
            lastRewardDistribution = block.timestamp;
        }
    }
}
