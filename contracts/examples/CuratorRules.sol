pragma solidity ^0.4.3;

import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";

contract CuratorRules is Rules {
    modifier boardIsConfigured (address _board) {
        if (isConfigured[_board]) {
          _;
        }
    }

    function CuratorRules (address _registry, address[] _curators) {
        registry = OpenRegistry(_registry);
        curators[address(this)] = _curators;
    }

    function hasWon(uint _proposalID) boardIsConfigured(msg.sender) public constant returns (bool) {
        BoardRoom board = BoardRoom(msg.sender);

        uint nay = board.positionWeightOf(_proposalID, 0);
        uint yea = board.positionWeightOf(_proposalID, 1);
        uint totalVoters = board.numVoters(_proposalID);

        for(uint i = 0; i < curators[msg.sender].length; i++){
          var (position, weight, created) = board.voteOf(_proposalID, curators[msg.sender][i]);
          if (position == 0){
            return false;
          }
        }

        if(totalVoters > 0 && yea > nay ) {
            return true;
        }

        return false;
    }

    function configureBoard(address _board) public {
      if(!isConfigured[_board]){
        curators[_board] = curators[address(this)];
        for(uint i = 0 ; i < curators[_board].length ; i++){
          isCurator[_board][curators[_board][i]] = true;
        }
        isConfigured[_board] = true;
      }
    }

    function addCurator (address _curator) public {
        BoardRoom board = BoardRoom(msg.sender);

        curators[msg.sender].push(_curator);
        isCurator[msg.sender][_curator] = true;
    }

    function removeCurator (address _curator) public {
        BoardRoom board = BoardRoom(msg.sender);
        isCurator[msg.sender][_curator] = false;

        for(uint i = 0; i < curators[msg.sender].length; i++){
            if (curators[msg.sender][i] == _curator) {
                delete curators[msg.sender][i];
            }
        }
    }

    function canVote(address _sender, uint _proposalID) boardIsConfigured(msg.sender) public constant returns (bool) {
        BoardRoom board = BoardRoom(msg.sender);

        uint created = board.createdOn(_proposalID);
        uint debatePeriod = board.debatePeriodOf(_proposalID);

        if(registry.isMember(_sender)
          && now < created + debatePeriod
          && !board.hasVoted(_proposalID, _sender)) {
            return true;
        }
    }

    function canPropose(address _sender) boardIsConfigured(msg.sender) public constant returns (bool) {
        if(registry.isMember(_sender)) {
            return true;
        }
    }

    function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint) {
        return 1;
    }

    OpenRegistry public registry;
    mapping(address => address[]) public curators;
    mapping(address => bool) public isConfigured;
    mapping(address => mapping(address => bool)) public isCurator;
}
