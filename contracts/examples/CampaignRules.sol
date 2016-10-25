import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";
import "examples/StandardCampaign.sol";

contract CampaignRules is Rules{

    function CampaignRules (address _registry, address _campaignAddr){
        registry = OpenRegistry(_registry);
        campaignAddr = _campaignAddr;
    }

    function hasWon(uint _proposalID) constant returns (bool){
        BoardRoom board = BoardRoom(msg.sender);
        var (name, destination, proxy, value, validityHash, executed, debatePeriod, created) = board.proposals(_proposalID);
        uint nay = board.positionWeightOf(_proposalID, 0);
        uint yea = board.positionWeightOf(_proposalID, 1);
        uint totalVoters = board.numVoters(_proposalID);

        if(totalVoters > 0 && yea > nay) {
            return true;
        }
    }

    function canVote(address _sender, uint _proposalID) constant returns (bool) {
        BoardRoom board = BoardRoom(msg.sender);
        var (name, destination, proxy, value, validityHash, executed, debatePeriod, created) = board.proposals(_proposalID);
        if(registry.isMember(_sender) && now < created + debatePeriod) {
            return true;
        }
    }

    function canPropose(address _sender) constant returns (bool) {
        if(registry.isMember(_sender)) {
            return true;
        }
    }

    function votingWeightOf(address _sender, uint _proposalID) constant returns (uint) {
        var (sender, value, created) = StandardCampaign(campaignAddr).contributions(StandardCampaign(campaignAddr).contributionsBySender(_sender, 0));

        return value;
    }

    OpenRegistry public registry;
    address public campaignAddr;
}
