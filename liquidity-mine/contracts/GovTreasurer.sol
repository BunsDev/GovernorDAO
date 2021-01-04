/*
MMMMMMMMMMMMMMMMMMMMMMMMMM
MM::MMMMMM::::::MMMMMM::MM
MMMM::MMM::::::::MMM::MMMM
MMMMM::MMM::::::MMM::MMMMM
MMMMMM::MMM::::MMM::MMMMMM
MMMMMMM::MMM::MMM::MMMMMMM
MMMMMMMM::MMMMMM::MMMMMMMM
MMMMMMMMMM::MMM::MMMMMMMMM
MMMMMMNMMMM::M::MMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMM
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 
// GovTreasurer is the treasurer of GDAO. She may allocate GDAO and she is a fair lady <3
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once GDAO is sufficiently
// distributed and the community can show to govern itself.
contract GovTreasurer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address devaddr;
    address public treasury;
    IERC20 public gdao;
    uint256 public bonusEndBlock;
    uint256 public GDAOPerBlock;


    // INFO | USER VARIABLES
    struct UserInfo {
        uint256 amount;     // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // The pending GDAO entitled to a user is referred to as the pending reward:
        //
        //   pending reward = (user.amount * pool.accGDAOPerShare) - user.rewardDebt - user.taxedAmount
        //
        // Upon deposit and withdraw, the following occur:
        //   1. The pool's `accGDAOPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated and taxed as 'taxedAmount'.
        //   4. User's `rewardDebt` gets updated.
    }

    // INFO | POOL VARIABLES
    struct PoolInfo {
        IERC20 token;           // Address of token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. GDAOs to distribute per block.
        uint256 taxRate;          // Rate at which the LP token is taxed.
        uint256 lastRewardBlock;  // Last block number that GDAOs distribution occurs.
        uint256 accGDAOPerShare; // Accumulated GDAOs per share, times 1e12. See below.
    }

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IERC20 _gdao, address _treasury, uint256 _GDAOPerBlock, uint256 _startBlock, uint256 _bonusEndBlock) public {
        gdao = _gdao;
        treasury = _treasury;
        devaddr = msg.sender;
        GDAOPerBlock = _GDAOPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    // VALIDATION | ELIMINATES POOL DUPLICATION RISK
    function checkPoolDuplicate(IERC20 _token) public view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "add: existing pool?");
        }
    }

    // ADD | NEW TOKEN POOL
    function add(uint256 _allocPoint, IERC20 _token, uint256 _taxRate, bool _withUpdate) public 
        onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            token: _token,
            allocPoint: _allocPoint,
            taxRate: _taxRate,
            lastRewardBlock: lastRewardBlock,
            accGDAOPerShare: 0
        }));
    }

    // UPDATE | ALLOCATION POINT
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // RETURN | REWARD MULTIPLIER OVER GIVEN BLOCK RANGE | INCLUDES START BLOCK
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from >= startBlock ? _from : startBlock;
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // VIEW | PENDING REWARD
    function pendingGDAO(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGDAOPerShare = pool.accGDAOPerShare;
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 GDAOReward = multiplier.mul(GDAOPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accGDAOPerShare = accGDAOPerShare.add(GDAOReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accGDAOPerShare).div(1e12).sub(user.rewardDebt);
    }

    // UPDATE | (ALL) REWARD VARIABLES | BEWARE: HIGH GAS POTENTIAL
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // UPDATE | (ONE POOL) REWARD VARIABLES
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 GDAOReward = multiplier.mul(GDAOPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        safeGDAOTransfer(address(this), GDAOReward);
        pool.accGDAOPerShare = pool.accGDAOPerShare.add(GDAOReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // VALIDATE | AUTHENTICATE _PID
    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "gov: pool exists?");
        _;
    }

    // WITHDRAW | ASSETS (TOKENS) WITH NO REWARDS | EMERGENCY ONLY
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        user.amount = 0;
        user.rewardDebt = 0;
        
        pool.token.safeTransfer(address(msg.sender), user.amount);

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);        
    }

    // DEPOSIT | ASSETS (TOKENS)
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 taxedAmount = _amount.div(pool.taxRate);

        if (user.amount > 0) { // if there are already some amount deposited
            uint256 pending = user.amount.mul(pool.accGDAOPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) { // sends pending rewards, if applicable
                safeGDAOTransfer(msg.sender, pending);
            }
        }
        
        if(_amount > 0) { // if adding more
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount.sub(taxedAmount));
            pool.token.safeTransferFrom(address(msg.sender), address(treasury), taxedAmount);
            user.amount = user.amount.add(_amount.sub(taxedAmount)); // update user.amount = non-taxed amount
        }
        
        user.rewardDebt = user.amount.mul(pool.accGDAOPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount.sub(taxedAmount));
    }

    // WITHDRAW | ASSETS (TOKENS)
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accGDAOPerShare).div(1e12).sub(user.rewardDebt);

        if(pending > 0) { // send pending GDAO rewards
            safeGDAOTransfer(msg.sender, pending);
        }
        
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(address(msg.sender), _amount);
        }
        
        user.rewardDebt = user.amount.mul(pool.accGDAOPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // SAFE TRANSFER FUNCTION | ACCOUNTS FOR ROUNDING ERRORS | ENSURES SUFFICIENT GDAO IN POOLS.
    function safeGDAOTransfer(address _to, uint256 _amount) internal {
        uint256 GDAOBal = gdao.balanceOf(address(this));
        if (_amount > GDAOBal) {
            gdao.transfer(_to, GDAOBal);
        } else {
            gdao.transfer(_to, _amount);
        }
    }

    // UPDATE | DEV ADDRESS | DEV-ONLY
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
