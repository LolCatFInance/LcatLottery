// SPDX-License-Identifier: unlicensed
pragma solidity ^ 0.8.0;
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
contract LcatLottery is Ownable,ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
   address payable LolcatToken;
   uint256 public RoundCount;
   uint256 public TransferFee;
   mapping (uint256=>mapping(uint256=>address)) public Ticket;
   mapping (address=>mapping(uint256=>uint256[])) public UserTickets;
   mapping (uint256=>uint256) TicketCount;
   event DrawCompeleted(uint256 indexed Round,address Winner,uint256 Amount);
   IERC20 public Lcat=IERC20(LolcatToken);
   struct RoundInfo{
       uint256 round;
       uint256 Starttime;
       uint256 EndTime;
       uint256 Drawtime;
       uint256 TotalTicket;
       uint256 TicketPrice;
       uint256 PlatformRewardShare;
       uint256 UserRewardShare;
       bool Iscompeleted;
       address winner;
       
   }
   receive() external payable {}
   
       
   function UserTotalTickets(address _UserAddress)public view returns(uint256){
       return UserTickets[_UserAddress][RoundCount].length;
   }
   function SetToken(address payable _TokenAddress)public onlyOwner{
       LolcatToken=_TokenAddress;
       Lcat=IERC20(_TokenAddress);
   }
   function SetTransferFee(uint256 _Fee)public onlyOwner{
       TransferFee=_Fee;
   }
   function setticketcount(uint256 lottery,uint256 Amount)internal{
       Lottery[lottery].TotalTicket=Amount;
   }
   RoundInfo[] public Lottery;

   function NewRound(uint256 TicketPrice,uint256 EndTime,uint256 DrawTime,uint256 Userrewardshare,uint256 PlatformRewardShare)public onlyOwner{
       //just set predefined null address for winners array.
      address winners=address(0);
      Lottery.push(RoundInfo(RoundCount++,block.timestamp,block.timestamp.add(EndTime),block.timestamp.add(DrawTime),0,TicketPrice,PlatformRewardShare,Userrewardshare,false,winners));
      RoundCount=Lottery.length.sub(1);
      Lottery[RoundCount].TotalTicket=1;
   }
    function ParticipateLottery(uint256 _Amount)public nonReentrant returns(uint256[] memory,uint256,uint256){
      RoundInfo memory LotteryId=Lottery[RoundCount];
      Lcat.transferFrom(msg.sender,address(this),_Amount);
      require(_Amount.div(1000).mul(TransferFee)>=LotteryId.TicketPrice);
      require(LotteryId.Starttime<=block.timestamp&&LotteryId.EndTime>=block.timestamp,"participation time ended");
       uint256 TotalTicketCount=(_Amount.div(1000).mul(TransferFee)).div(LotteryId.TicketPrice);
       uint256[] memory FinalTickets = new uint256[](TotalTicketCount);
       uint256 LotteryTotalTickets=LotteryId.TotalTicket;
       for (uint i=0; i<TotalTicketCount; i++) {
        Ticket[RoundCount][LotteryTotalTickets]=msg.sender;
        UserTickets[msg.sender][RoundCount].push(LotteryTotalTickets);
        FinalTickets[i]=LotteryTotalTickets;
        LotteryTotalTickets++;
       }
       setticketcount(RoundCount,LotteryTotalTickets);
      // return FinalTickets;
      return (FinalTickets,LotteryTotalTickets,TotalTicketCount);
   }
   function Draw(uint256 RoundId) public onlyOwner{
       RoundInfo storage LotteryId=Lottery[RoundId];
       require(LotteryId.Iscompeleted==false,"Round Draw Compeleted");
       require(LotteryId.Drawtime<=block.timestamp,"Draw Time Not Reached Yet");
       uint256 random=uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,block.coinbase)))%LotteryId.TotalTicket;
       address Winner=Ticket[RoundId][random];
       uint256 TotalReward=LotteryId.TotalTicket.sub(1).mul(LotteryId.TicketPrice).div(1000);
       require(Winner!=address(0));
       Lcat.transfer(Winner,TotalReward.mul(LotteryId.UserRewardShare));
       Lcat.transfer(owner(),TotalReward.mul(LotteryId.PlatformRewardShare));
       LotteryId.Iscompeleted=true;
       LotteryId.winner=Winner;
       emit DrawCompeleted(RoundId,Winner,TotalReward);
   }
    //withdraw any token send wrongly to contract
 function RescueLossToken(address _address,uint256 Amount,address Recipient) public onlyOwner{
     require(_address!=LolcatToken,"You Cant Withdraw Lcat Token");//Prevent Contract Access To Lcat Token Withdraw
     IERC20(_address).transfer(Recipient,Amount);
 }
 function RescueBnb()public onlyOwner{
     payable(address(owner())).transfer(address(this).balance);
 }
}