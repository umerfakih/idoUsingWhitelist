// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ido is Ownable,ReentrancyGuard{
    using SafeMath for uint256;
    uint256 tokenConversion = 1 / 0.5; // token rate 2 token for 1 dollar
    IERC20 busdToken;
    IERC20 Token;
    uint256 public roundDetail;                  // 0 means pool is not started 1 round1 active and 2 means public sale is active
    uint256 public totalSold;                   // total token purchased by users 
    uint256 public totalTokenClaimed;           // total token claimed by users
    uint256 public totalUsdCommited;            // total usd commited by user
    uint256 public startTime;                   // round 1 start time
    uint256 allocation = 40 * 10 ** 18;         // 40 usd for whitelisted wallets
    uint256 public endTime;                     // round 1 end time
    bool public publicRoundActive =true;        //public round status
    uint256 public idoTokenAllocation = 10000000 * 10 **18;     // total token allocated to buy
    struct userInfo {
        uint256 purchased;
        uint256 alreadyClaimed;
        uint256 remainingTokenClaim;
        uint256 usdCommited;
    }
    mapping(address => userInfo) public users;

    bytes32 root;                               //root hash of whitelisted wallets

    event buyRound1(address indexed user,address indexed admin , uint256 amount);
    event buyPublicRound(address indexed user,address indexed admin,uint256 amount);
    event claimed(address indexed user,uint256 amount);

    constructor(address _busdToken,address _Token,uint256 _startTime,bytes32 _root){
        busdToken = IERC20(_busdToken);
        Token = IERC20(_Token);
        startTime = _startTime;
        root = _root;
    }

        // whitelisted round only whitelisted wallet can buy
    function round1(uint256 _amount , bytes32[] calldata proof) external {
        userInfo storage user = users[msg.sender];
        if(block.timestamp > startTime){
            endTime = startTime.add(1800); // after 30 mins this pool wil end
            roundDetail = 1;
        }
        require(checkWhitelistedOrNot(proof,keccak256(abi.encodePacked(msg.sender))),"you are not whitelisted");  //checking user address is whitelisted or not
        require(block.timestamp >= startTime,"pool is not started yet");
        require(block.timestamp <= endTime,"pool is endede");
        require(busdToken.balanceOf(msg.sender) >= _amount,"you dont have enough busd");
        require(_amount <= allocation.mul(10 ** 18),"please send allocated amount only");
        require(user.usdCommited.add(_amount) <= allocation,"you have exceed your allocation limit");
        require(totalSold.add(_amount) <= idoTokenAllocation);
        busdToken.transferFrom(msg.sender,address(this),_amount);
        user.purchased = _amount.mul(tokenConversion).add(user.purchased);
        user.remainingTokenClaim = _amount.mul(tokenConversion).add(user.remainingTokenClaim);
        user.usdCommited = user.usdCommited.add(_amount);
        totalSold = _amount.mul(tokenConversion).add(totalSold);
        totalUsdCommited = totalUsdCommited.add(_amount);
        emit buyRound1(msg.sender,address(this),_amount);
    }

    // public round any wallet can buy any amount
    function PublicRound(uint256 _amount) external {
        userInfo storage user = users[msg.sender];
        require(block.timestamp > endTime,"pool is not started yet"); //start when round1 end
        require(publicRoundActive,"this pool is ended");
        require(busdToken.balanceOf(msg.sender) >= _amount,"please send enough busd");
        require(totalSold.add(_amount) <= idoTokenAllocation);
        roundDetail = 2;
        busdToken.transferFrom(msg.sender,address(this),_amount);
        user.purchased = _amount.mul(tokenConversion).add(user.purchased);
        user.remainingTokenClaim = _amount.mul(tokenConversion).add(user.remainingTokenClaim);
        user.usdCommited = user.usdCommited.add(_amount);
        totalSold = _amount.mul(tokenConversion).add(totalSold);
        totalUsdCommited = totalUsdCommited.add(_amount);
        emit buyPublicRound(msg.sender,address(this),_amount);
    }
    // close publicRound
    function endPublicSale() external onlyOwner{
        publicRoundActive = false;
        roundDetail = 0;
    }

    // user can claim their token
    function claim() external nonReentrant {
        userInfo storage user = users[msg.sender];
        require(block.timestamp >= startTime.add(24 * 10 ** 18),"claim is not started yet");
        require(user.purchased > 0,"you didnt purchased token");
        require(user.remainingTokenClaim != 0,"you have already claimed");
        require(Token.balanceOf(address(this))>= user.remainingTokenClaim,"not enough token in contract");
        Token.transfer(msg.sender,user.remainingTokenClaim); 
        user.alreadyClaimed = user.remainingTokenClaim;
        user.remainingTokenClaim = 0;
        totalTokenClaimed = totalTokenClaimed.add(user.alreadyClaimed);
        emit claimed(msg.sender,user.remainingTokenClaim);
    }
    //owner can add token
    function addToken(uint256 _amount) external  onlyOwner{
        require(Token.balanceOf(msg.sender) >= _amount);
        Token.transferFrom(msg.sender,address(this),_amount);
        idoTokenAllocation = _amount;

    }
    //owner withdraw busd
    function BusdWithdraw() external onlyOwner {
        require(busdToken.balanceOf(address(this)) > 0);
        busdToken.transfer(msg.sender,busdToken.balanceOf(address(this)));
    }
    //for frontend data display
    function frontendView() public view returns(uint256 _totalPurchased,uint256 _alreadyClaimed,uint256 _remainingtoClaim,uint256 _usdCommited){
        userInfo storage user = users[msg.sender];
        _totalPurchased = user.purchased;
        _alreadyClaimed = user.alreadyClaimed;
        _remainingtoClaim = user.remainingTokenClaim;
        _usdCommited = user.usdCommited;
    }
        //can check whitelisted or not
      function checkWhitelistedOrNot(bytes32[] calldata proof,bytes32 leaf) public view returns(bool){
        return MerkleProof.verify(proof,root,leaf);
    }
    //owner can withdraw reamining token
    function withdrawRemainingTOken() external onlyOwner{
        require(Token.balanceOf(address(this)) > 0);
        totalTokenClaimed = totalTokenClaimed.add(Token.balanceOf(address(this)));
        Token.transfer(msg.sender,Token.balanceOf(address(this)));
    }
    
}