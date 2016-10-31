pragma solidity ^0.4.3;

import "Rules.sol";
import "BoardRoom.sol";

contract MultiSigRules is Rules {
  function MultiSigRules (address[] _signatories) {
    signatories = _signatories;

    for(uint i = 0; i < signatories.length; i++){
      isSignatory[signatories[i]] = true;
    }
  }

  function hasWon(uint _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);
    uint256 yea = board.positionWeightOf(_proposalID, 1);
    uint256 totalVoters = board.numVoters(_proposalID);

    if(yea == totalVoters) {
      return true;
    }
  }

  function canVote(address _sender, uint _proposalID) public constant returns (bool) {
    if (isSignatory[_sender]) {
      return true;
    }
  }

  function canPropose(address _sender) public constant returns (bool) {
    if (isSignatory[_sender]) {
      return true;
    }
  }

  function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint) {
    if (isSignatory[_sender]) {
      return 1;
    }
  }

  mapping(address => bool) isSignatory;
  address[] public signatories;
}
