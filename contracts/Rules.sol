pragma solidity ^0.4.3;

contract Rules {
  function hasWon(uint _proposalID) public constant returns (bool);
  function canVote(address _sender, uint _proposalID) public constant returns (bool);
  function canPropose(address _sender) public constant returns (bool);
  function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint);
}
