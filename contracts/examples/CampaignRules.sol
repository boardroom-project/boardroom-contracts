pragma solidity ^0.4.3;

import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";
import "examples/StandardCampaign.sol";

contract CampaignRules is Rules {

    function CampaignRules (address _campaignAddr) {
        campaignAddr = _campaignAddr;
    }

    function hasWon(uint _proposalID) public constant returns (bool){
        BoardRoom board = BoardRoom(msg.sender);

        uint nay = board.positionWeightOf(_proposalID, 0);
        uint yea = board.positionWeightOf(_proposalID, 1);
        uint totalVoters = board.numVoters(_proposalID);

        if(totalVoters > 0 && yea > nay) {
            return true;
        }
    }

    function canVote(address _sender, uint _proposalID) public constant returns (bool) {
        BoardRoom board = BoardRoom(msg.sender);

        uint created = board.createdOn(_proposalID);
        uint debatePeriod = board.debatePeriodOf(_proposalID);

        var (contributionSender, contributionValue, contributionCreated) = StandardCampaign(campaignAddr).contributions(StandardCampaign(campaignAddr).contributionsBySender(_sender, 0));

        if(_sender == contributionSender
          && contributionValue > 0
          && now < created + debatePeriod) {
            return true;
        }
    }

    function canPropose(address _sender) public constant returns (bool) {
        var (contributionSender, contributionValue, contributionCreated) = StandardCampaign(campaignAddr).contributions(StandardCampaign(campaignAddr).contributionsBySender(_sender, 0));

        if(_sender == contributionSender
          && contributionValue > 0) {
            return true;
        }
    }

    function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint) {
        var (contributionSender, contributionValue, contributionCreated) = StandardCampaign(campaignAddr).contributions(StandardCampaign(campaignAddr).contributionsBySender(_sender, 0));

        return contributionValue;
    }

    address public campaignAddr;
}
