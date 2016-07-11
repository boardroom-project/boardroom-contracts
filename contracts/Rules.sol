contract Rules {
  function hasWon(uint _proposalID) constant returns (bool);
  function canVote(address _sender, uint _proposalID) constant returns (bool);
  function canPropose(address _sender) constant returns (bool);
  function votingWeightOf(address _sender, uint _proposalID) constant returns (uint);
}
