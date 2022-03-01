# Gravis Evervoid Staking ERC20

This contract provides ERC20 token stacking for the award in ERC20 tokens.
ERC20 Stacking URL: https://evervo.id/resources/grvx-staking/

## Deployment And Configuration

### Compile

Copy `.env.example` to a new file called `.env` and fill the values in it.

```
npx hardhat compile
```

### Test

```
npx hardhat test
```

### Deploy GRVX Staking

Copy file `example.env` to `.env` and replace empty address variables with correct values. Then run:

```
npx hardhat run scripts/deploy-grvx.ts --network [Your Network]
```

## GRVX Staking

This contracts allows users to stake GRVX and get FUEL rewards.

### Stake

This function is used to stake GRVX to contract. Approval for staked amount should be given in prior.

```jsx
function stake(uint256 amount)
```

**Parameters**

-   uint256 amount - amount of GRVX (as wei) being staked

### Unstake

This function is used to unstake previously staked GRVX. Amount should not exceed stake size. Rewards are collected separately.

```jsx
function unstake(uint256 amount)
```

**Parameters**

-   uint256 amount - amount of GRVX (as wei) being unstaked

### Claim Reward

This function is used to claim accumulated reward of the user.

```jsx
function claimReward()
```

### Reward Of

This view function returns current reward amount for a given user.

```jsx
function rewardOf(address account) public view returns (uint256)
```

**Parameters**

-   address account - address to get reward for

### Stake Of

This view function returns current stake size for a given user (as wei)

```jsx
function stakeOf(address account) public view returns (uint256)
```

**Parameters**

-   address account - address to get stake for

### Set Reward Per Block

This function sets amount of fuel distributed per block. Can only be called by owner.

```jsx
function setRewardPerBlock(uint256 rewardPerBlock_) external onlyOwner
```

**Parameters**

-   uint256 rewardPerBlock\_ - amount of FUEL (as wei) distributed between stakers per block
