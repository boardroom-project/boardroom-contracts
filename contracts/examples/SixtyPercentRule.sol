import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";

contract SixtyPercentRule is Rules {
    function SixtyPercentRule (address _registry){
        registry = OpenRegistry(_registry);
    }

    function hasWon(uint _proposalID) constant returns (bool) {
        BoardRoom board = BoardRoom(msg.sender);
        uint nay = board.positionWeightOf(_proposalID, 0);
        uint yea = board.positionWeightOf(_proposalID, 1);

        if(yea*10 > (nay + yea)*6 && (nay + yea)*10 > registry.numMembers()*5) {
            return true;
        }
        return false;
    }

    function canVote(address _sender, uint _proposalID) constant returns (bool) {
        return true;
    }

    function canPropose(address _sender) constant returns (bool) {
        return true;
    }

    function votingWeightOf(address _sender, uint _proposalID) constant returns (uint) {
        return 1;
    }
    OpenRegistry public registry;
}
