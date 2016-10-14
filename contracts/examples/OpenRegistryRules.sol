import "OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";

contract OpenRegistryRules is Rules {
  function OpenRegistryRules(address _registry){
    registry = OpenRegistry(_registry);
  }

  function hasWon(uint _proposalID) constant returns (bool) {
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
    return 1;
  }

  OpenRegistry public registry;
}
