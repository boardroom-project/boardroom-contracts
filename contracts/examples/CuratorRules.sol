import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";

contract CuratorRules is Rules {
    function CuratorRules (address _registry, address[] _curators){
        registry = OpenRegistry(_registry);
        owner = msg.sender;
        curators = _curators;
        for(uint i = 0; i < _curators.length; i++){
          isCurator[_curators[i]] = true;
        }
    }

    function hasWon(uint _proposalID) constant returns (bool) {
        uint nay = board.positionWeightOf(_proposalID, 0);
        uint yea = board.positionWeightOf(_proposalID, 1);
        uint totalVoters = board.numVoters(_proposalID);

        for(uint i = 0; i < curators.length; i++){
          var (position, weight, created) = board.voteOf(_proposalID, curators[i]);
          if (position == 0){
            return false;
          }
        }

        if(totalVoters > 0 && yea > nay ) {
            return true;
        }

        return false;
    }

    function setup(address _board) {
        if (msg.sender == owner) {
            board = BoardRoom(_board);
        }
    }

    function addCurator (address _curator){
        if (msg.sender == address(board)){
          curators.push(_curator);
          isCurator[_curator] = true;
        }
    }

    function removeCurator (address _curator) {
        if (msg.sender == address(board)){
            isCurator[_curator] = false;

            for(uint i = 0; i < curators.length; i++){
                if (curators[i] == _curator) {
                    delete curators[i];
                }
            }
        }
    }

    function canVote(address _sender, uint _proposalID) constant returns (bool) {
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

    address owner;
    BoardRoom board;
    OpenRegistry public registry;
    address[] curators;
    mapping(address => bool) public isCurator;
}
