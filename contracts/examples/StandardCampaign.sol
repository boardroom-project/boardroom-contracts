pragma solidity ^0.4.3;

import "examples/BalanceClaim.sol";
import "examples/Campaign.sol";

contract StandardCampaign is Campaign {
  enum Stages {
    CrowdfundOperational,
    CrowdfundFailure,
    CrowdfundSuccess
  }

  modifier atStageOr(uint256 _expectedStage) {
    // if stage needs to be changed
    if (stage != _expectedStage) {
      // this is the WeiFund StandardCampaign state machine
      // if the current block timestamp is less than the specified exipry timestamp
      // the campaign is at stage 0, operational state
      if (now < expiry) {
        stage = uint256(Stages.CrowdfundOperational);

      // if the current blocktimestamp is greater than the specified expiry
      // the amount raised is less than the funding goal
      // and funding goal was specified as a value greater than zero
      // the campaign is at stage 1 failure state
      } else if(now >= expiry && amountRaised < fundingGoal && fundingGoal > 0) {
        stage = uint256(Stages.CrowdfundFailure);

      // if the current blocktimestamp is greater than or equal to the specified expiry
      // timestamp the amount raised is greater than or equal to the funding goal
      // then the crowdfund is at stage 2 success state
      } else if(now >= expiry && amountRaised >= fundingGoal) {
        stage = uint256(Stages.CrowdfundSuccess);
      }
    }

    // if the current stage does not equal the expected stage
    // throw an EVM error
    if (stage != _expectedStage) {
      throw;
    }

    // otherwise, carry on with contractual state changing contract logic
    _;
  }

  modifier validRefundClaim(uint256 _contributionID) {
    // get the contribution specified by ID "_contributionID"
    Contribution refundContribution = contributions[_contributionID];

    // if the refund for this contribution has not been claimed
    if(refundsClaimed[_contributionID] == true // the refund for this contribution is not claimed
      || refundContribution.sender != msg.sender){ // the contribution sender is the msg.sender
      throw;
    }

    // carry on with refund state changing contract logic
    _;
  }

  /// @notice check contract invarience, if something is wrong, send beneficiary all funds
  function checkInvarience() internal {
    // the amountRaised value should always equal the contract balance while the
    // crowdfund is in operation, panic and send beneficiary funds in any other case
    if (amountRaised != this.balance && stage == uint256(Stages.CrowdfundOperational)) {
      if (!beneficiary.send(this.balance)) {
        throw;
      }
    }
  }

  /// @notice a fallback function that supports contribution
  function () payable public {
    // allow the fallback function to intake contribtions
    // we are aware this is not currently a contractual best practice
    contributeMsgValue();
  }

  /// @notice send a contribution of a specific value to this campaign
  /// @return The contribution ID as a uint256
  function contributeMsgValue() atStageOr(uint(Stages.CrowdfundOperational)) payable public returns (uint256 contributionID) {
    // create the contribtionID that will be returned by increasing the contributions array length by 1
    // allow the intake of contributions with a msg.value of zero for method simplicity
    contributionID = contributions.length++;

    // define and store the new contribution storing the contribution sender,
    // value and created
    contributions[contributionID] = Contribution({
        sender: msg.sender,
        value: msg.value,
        created: now
    });

    // notate that this msg.sender made contribution with contribution ID
    contributionsBySender[msg.sender].push(contributionID);

    // increase the total amount raised by the contributor
    amountRaised += msg.value;

    // fire the contribution made event
    ContributionMade(msg.sender);

    // check invarience
    checkInvarience();
  }

  /// @notice payout the balance of the campaign to the campaign beneficiary
  /// @return the amount sent to the beneficiary
  function payoutToBeneficiary() atStageOr(uint(Stages.CrowdfundSuccess)) public returns (uint256 amountClaimed) {
    // set the amountClaimed to the balance of the contract for output return
    amountClaimed = this.balance;

    // send the beneficiary the current balance of the contract
    // if the send is unsuccessful, throw an error
    if (!beneficiary.send(this.balance)) {
      throw;
    }

    // fire the beneficiary payout claimed event
    BeneficiaryPayoutClaimed(beneficiary, amountClaimed);

    // check invarience
    checkInvarience();
  }

  /// @notice claim refund owed for contribution at id '_contributionID' returns 'balanceClaim' address
  /// @param _contributionID The contribution ID
  /// @return The address of the balance claim, where the user can get their funds from
  function claimRefundOwed(uint256 _contributionID) atStageOr(uint(Stages.CrowdfundFailure)) validRefundClaim(_contributionID) public returns (address balanceClaim) {
    // state that the refund has been claimed for contribution in question
    refundsClaimed[_contributionID] = true;

    // get the contribution data in question
    Contribution refundContribution = contributions[_contributionID];

    // create a new balance claim contract that will receive the refund
    balanceClaim = address(new BalanceClaim(refundContribution.sender));

    // if the balance claim successfully sent funds of the contribution in question
    // fire the refund payout claimed event or throw an error
    if (balanceClaim.send(refundContribution.value)) {
      RefundPayoutClaimed(balanceClaim, refundContribution.value);
    } else {
      throw;
    }

    // check invarience
    checkInvarience();
  }

  /// @notice the StandardCampaign constructor
  /// @param _name the name of the campaign
  /// @param _expiry the expiry of the campaign as a UNIX timestamp
  /// @param _fundingGoal the funding goal of a campaign specified in wei
  /// @param _beneficiary the beneficiary of the campaign
  /// @param _owner the owner of the campaign
  function StandardCampaign(string _name,
    uint256 _expiry,
    uint256 _fundingGoal,
    address _beneficiary,
    address _owner) public {
    // set the name, expiry, funding goal, beneficiary address and owner
    // of the campaign
    name = _name;
    expiry = _expiry;
    fundingGoal = _fundingGoal;
    beneficiary = _beneficiary;
    owner = _owner;
  }

  /// @notice the total contributions made to the campaign
  /// @return the amount '_amount' of contributions made
  function totalContributions() public constant returns (uint256 amount) {
    // return the contributions array length
    return contributions.length;
  }

  /// @notice the total contributions '_amount' made by sender '_sender'
  /// @param _sender the address of the sender in question
  /// @return the total amount '_amount' of contributions made by '_sender' as a uint256
  function totalContributionsBySender(address _sender) public constant returns (uint256 amount) {
    // return the contributions by specified sender array length
    return contributionsBySender[_sender].length;
  }

  struct Contribution {
    // the address of the sender account that made the contribution
    address sender;

    // the total value of the contribution made by the sender
    uint256 value;

    // the block timestamp at which this contribution was created
    uint256 created;
  }

  uint256 public stage;
  uint256 public fundingGoal;
  uint256 public amountRaised;
  uint256 public expiry;
  address public beneficiary;
  address public owner;
  Contribution[] public contributions;
  mapping(address => uint256[]) public contributionsBySender;
  mapping(uint256 => address) public refundClaimAddress;
  mapping(uint256 => bool) public refundsClaimed;

  string public name;
  string public version = "0.1.0";
  string public contributeMethodABI = "contributeMsgValue():(uint256 contributionID)";
  string public payoutMethodABI = "payoutToBeneficiary():(uint256 amountClaimed)";
  string public refundMethodABI = "claimRefundOwed(uint256 _contributionID):(address balanceClaim)";
}
