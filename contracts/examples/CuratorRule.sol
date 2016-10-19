import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";

contract CuratorRule is Rules {
    function CuratorRule (address _registry){
        registry = OpenRegistry(_registry);
    }

    function hasWon(uint _proposalID) constant returns (bool) {
        BoardRoom board = BoardRoom(msg.sender);
        uint nay = board.positionWeightOf(_proposalID, 0);
        uint yea = board.positionWeightOf(_proposalID, 1);
        uint totalVoters = board.numVoters(_proposalID);
        for(uint i = 0; i < curators.length; i++){
          var (position, weight, created) = board.voteOf(_proposalID,curators[i]);
          if (position == 0){
            return false;
          }
        }
        if(totalVoters > 0 && yea > nay ) {
            return true;
        }
        return false;
    }

    function addCurator (address _curator){
        BoardRoom board = BoardRoom(msg.sender);
        if (registry.isMember(_curator)){
          curators.push(_curator);
          isCurator[_curator] = true;
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
    address[] curators;
    mapping(address => bool) public isCurator;
}
