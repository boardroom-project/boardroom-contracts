pragma solidity ^0.4.3;

import "dapple/test.sol";
import "BoardRoom.sol";
import "examples/CampaignRules.sol";
import "examples/OpenRegistry.sol";
import "examples/StandardCampaign.sol";
import "OwnedProxy.sol";


contract TestableStandardCampaign is StandardCampaign {
  /// @notice The contract fallback function
  function () payable public {}

  function TestableStandardCampaign(string _name,
    uint256 _expiry,
    uint256 _fundingGoal,
    address _beneficiary,
    address _owner) StandardCampaign(_name,
    _expiry,
    _fundingGoal,
    _beneficiary,
    _owner)
    {
  }

  modifier validRefundClaim(uint256 _contributionID) {
    // get the contribution specified by ID "_contributionID"
    Contribution refundContribution = contributions[_contributionID];

    // if the refund for this contribution has not been claimed
    if(refundsClaimed[_contributionID] == true) { // the refund for this contribution is not claimed
// disabled the following condition (which exists in the original StandardCampaign contract in order
// to be able to test the method with different accounts
//      || refundContribution.sender != msg.sender){ // the contribution sender is the msg.sender
      throw;
    }

    // carry on with refund state changing contract logic
    _;
  }


  function setExpiry(uint _expiry) {
    expiry = _expiry;
  }

  function addTimeToExpiry(uint _timeToAdd) {
    expiry = expiry + _timeToAdd;
  }

  function setFundingGoal(uint256 _fundingGoal) {
    fundingGoal = _fundingGoal;
  }
}

contract MemberProxy {
  /// @notice The contract fallback function
  function () payable public {}

  function newProposal(address _board, string _name, address _proxy, uint _debatePeriod, address _destination, uint _value, bytes _calldata) returns (uint proposalID) {
    return BoardRoom(_board).newProposal(_name, _proxy, _debatePeriod, _destination, _value, _calldata);
  }

  function vote(address _board, uint _proposalID, uint _position) returns (uint voteWeight) {
    return BoardRoom(_board).vote(_proposalID, _position);
  }

  function execute(address _board, uint _proposalID, bytes _calldata) {
    return BoardRoom(_board).execute(_proposalID, _calldata);
  }

  function newCampaign(string _name,
    uint256 _expiry,
    uint256 _fundingGoal,
    address _beneficiary) returns (address) {
    return address(new StandardCampaign(_name, _expiry, _fundingGoal, _beneficiary, address(this)));
  }

  function newTestableCampaign(string _name,
    uint256 _expiry,
    uint256 _fundingGoal,
    address _beneficiary) returns (address) {
    return address(new TestableStandardCampaign(_name, _expiry, _fundingGoal, _beneficiary, address(this)));
  }

  function newContribution(address _campaign, uint256 _value) returns (uint) {
    StandardCampaign target = StandardCampaign(_campaign);
    return target.contributeMsgValue.value(_value)();
  }
}


// dealing with these issues:
// https://github.com/nexusdev/dapple/issues/344

contract CampaignRulesTest is Test {
  OpenRegistry registry;
  OwnedProxy proxy;
  CampaignRules rules;
  BoardRoom board;
  MemberProxy member1;

  StandardCampaign target;
  string campaignName = "Make America Great Again";
  string standardCampaignContributeMethodABI = "contributeMsgValue():(uint256 contributionID)";
  string standardCampaignPayoutMethodABI = "payoutToBeneficiary():(uint256 amountClaimed)";

  function setUp() {
    member1 = new MemberProxy();
    registry = new OpenRegistry();
    registry.register(address(member1));
    board = new BoardRoom(address(rules));
  }

  function test_campaignRules() {
    uint256 expiry = now + 1 weeks;
    uint256 fundingGoal = 1000;
    address destinationAccount = address(new MemberProxy());

    MemberProxy memberA = new MemberProxy();
    registry.register(address(memberA));

    if(memberA.send(1000)){
    }
    address beneficiary = address(memberA);
    // start new campaign
    target = StandardCampaign(memberA.newCampaign(campaignName, expiry, fundingGoal, beneficiary));

    rules = new CampaignRules(address(target));
    board = new BoardRoom(address(rules));
    if(board.send(1000)){
    }

    OwnedProxy proxy = new OwnedProxy(address(board));

    if (proxy.send(600)) {
    }

    assertEq(target.stage(), uint256(0));
    assertEq(target.amountRaised(), uint256(0));
    assertEq(target.fundingGoal(), fundingGoal);
    assertEq(target.expiry(), expiry);
    assertEq(target.beneficiary(), beneficiary);
    assertEq(target.totalContributions(), uint256(0));
    assertEq(target.owner(), address(memberA));

    MemberProxy memberB = new MemberProxy();
    registry.register(address(memberB));
    MemberProxy memberC = new MemberProxy();
    registry.register(address(memberC));
    MemberProxy memberD = new MemberProxy();
    registry.register(address(memberD));
    if(memberB.send(1000)){
    }
   if(memberC.send(1000)){
    }
   if(memberD.send(1000)){
    }
    assertEq(target.balance, 0);
    assertEq(memberA.newContribution(address(target), 250), uint256(0));
    assertEq(uint256(target.balance), uint256(250));
    assertEq(uint256(memberA.balance), uint256(750));

    assertEq(memberB.newContribution(address(target), 249), uint256(1));
    assertEq(uint256(target.balance), uint256(499));
    assertEq(uint256(memberB.balance), uint256(751));


    assertEq(memberB.newProposal(address(board), "Some Awesome Sauce Proposal", address(proxy), 30, target, 400, ""), 0);

    assertEq(rules.votingWeightOf(address(memberA),0), 250);
    assertEq(rules.votingWeightOf(address(memberB),0), 249);

    memberA.vote(address(board),0,1);
    memberB.vote(address(board),0,0);
    assertEq(board.numVoters(0), 2);
    assertEq(proxy.balance, 600);
    memberA.execute(address(board), 0, "");
    assertEq(proxy.balance, 200);
    assertEq(target.balance, 899);

  }

  function test_CampaignRulesFail() {
    uint256 expiry = now + 1 weeks;
    uint256 fundingGoal = 1000;

    address destinationAccount = address(new MemberProxy());

    MemberProxy memberA = new MemberProxy();
    registry.register(address(memberA));
    if(memberA.send(1000)){
    }


    address beneficiary = address(memberA);
    // start new campaign
    target = StandardCampaign(memberA.newCampaign(campaignName, expiry, fundingGoal, beneficiary));

    rules = new CampaignRules(address(target));
    board = new BoardRoom(address(rules));
    if(board.send(1000)){
    }

    OwnedProxy proxy = new OwnedProxy(address(board));

    if (proxy.send(600)) {
    }

    assertEq(target.stage(), uint256(0));
    assertEq(target.amountRaised(), uint256(0));
    assertEq(target.fundingGoal(), fundingGoal);
    assertEq(target.expiry(), expiry);
    assertEq(target.beneficiary(), beneficiary);
    assertEq(target.totalContributions(), uint256(0));
    assertEq(target.owner(), address(memberA));

    MemberProxy memberB = new MemberProxy();
    registry.register(address(memberB));
    MemberProxy memberC = new MemberProxy();
    registry.register(address(memberC));
    MemberProxy memberD = new MemberProxy();
    registry.register(address(memberD));
    if(memberB.send(1000)){
    }
   if(memberC.send(1000)){
    }
   if(memberD.send(1000)){
    }
    assertEq(target.balance, 0);
    assertEq(memberA.newContribution(address(target), 250), uint256(0));
    assertEq(uint256(target.balance), uint256(250));
    assertEq(uint256(memberA.balance), uint256(750));

    assertEq(memberB.newContribution(address(target), 249), uint256(1));
    assertEq(uint256(target.balance), uint256(499));
    assertEq(uint256(memberB.balance), uint256(751));


    assertEq(memberB.newProposal(address(board), "Some Awesome Sauce Proposal", address(proxy), 30, target, 400, ""), 0);

    assertEq(rules.votingWeightOf(address(memberA),0), 250);
    assertEq(rules.votingWeightOf(address(memberB),0), 249);

    memberA.vote(address(board),0,0);
    memberB.vote(address(board),0,1);
    assertEq(board.numVoters(0), 2);
    assertEq(proxy.balance, 600);
    memberA.execute(address(board), 0, "");
    assertEq(proxy.balance, 600);
    assertEq(target.balance, 499);

  }

}
