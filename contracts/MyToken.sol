// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeCoin is ERC20, ERC20Permit, Ownable {
    uint256 public constant MAX_SUPPLY = 1000000 * (10 ** 9);
    uint256 public immutable VESTING_DURATION = 14 days;
    
    struct VestingInfo {
        address beneficiary;
        uint256 amount;
        bool completed;
        uint256 completionBlock;
        uint256 startTime; // Tambahkan ini
        mapping(uint256 => address) vestedAmountsMap;
    }
    
    // Mapping from user to vesting info.
    mapping (address => VestingInfo) public vestings;
    address[] private users;
    function releaseTokens() external onlyOwner {
        require(block.timestamp > currentVestingStart(), "Must be between vesting start and end.");
        
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!vestings[user].completed) revert("User tidak mengalami vesting.");
            
            uint256 timePassed = block.timestamp - vestings[user].startTime;
            require(timePassed >= VESTING_DURATION, "Vesting duration not elapsed yet");
            
            _mint(user, 1e18);
        }
    }
    function mint() public onlyOwner {
        require(block.timestamp > currentVestingStart(), "Vesting belum selesai");
        
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!vestings[user].completed) revert("User tidak mengalami vesting.");
            
            uint256 timePassed = block.timestamp - vestings[user].startTime;
            require(timePassed >= VESTING_DURATION, "Belum mencapai waktu release token");
            
            _mint(user, 1e18);
        }
    }
    
    function currentVestingStart() public view returns (uint256) {
       return block.timestamp - VESTING_DURATION;
    }
    constructor() ERC20("MemeCoin", "MEME") ERC20Permit("MemeCoin") Ownable(msg.sender) {
        users.push(msg.sender); // Tambahkan owner ke daftar users

        // Buat struct sementara tanpa langsung assign
        VestingInfo storage vesting = vestings[msg.sender];
        vesting.beneficiary = msg.sender;
        vesting.amount = MAX_SUPPLY;
        vesting.completed = false;
        vesting.completionBlock = 0;
        vesting.startTime = block.timestamp;
    }
}
