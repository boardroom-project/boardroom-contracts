pragma solidity ^0.4.3;

import "Rules.sol";
import "Proxy.sol";

contract BoardRoomInterface {
  function newProposal(string _name, address _proxy, uint _debatePeriod, address _destination, uint _value, bytes _calldata) returns (uint proposalID) {}
  function vote(uint _proposalID, uint _position) returns (uint voteWeight) {}
  function execute(uint _proposalID, bytes _calldata) {}
  function changeRules(address _rules) {}

  function voterAddressOf(uint _proposalID, uint _voteID) constant returns (address) {}
  function numVoters(uint _proposalID) constant returns (uint) {}
  function positionWeightOf(uint _proposalID, uint _position) constant returns (uint) {}
  function voteOf(uint _proposalID, address _voter) constant returns (uint, uint, uint) {}
  function hasVoted(uint _proposalID, address _voter) constant returns (bool) {}

  function destinationOf(uint _proposalId) public constant returns (address) {}
  function proxyOf(uint _proposalId) public constant returns (address) {}
  function valueOf(uint _proposalId) public constant returns (uint) {}
  function hashOf(uint _proposalId) public constant returns (bytes32) {}
  function debatePeriodOf(uint _proposalId) public constant returns (uint) {}
  function createdOn(uint _proposalId) public constant returns (uint) {}
  function createdBy(uint _proposalId) public constant returns (address) {}

  event ProposalCreated(uint _proposalID, address _destination, uint _value);
  event VoteCounted(uint _proposalID, uint _position, address _voter);
  event ProposalExecuted(uint _proposalID, address _sender);
}

contract BoardRoom is BoardRoomInterface {

  function BoardRoom(address _rules) {
    rules = Rules(_rules);
  }

  modifier canpropose {
    if(rules.canPropose(msg.sender)) {
      _;
    }
  }

  modifier canvote (uint _proposalID) {
    if(rules.canVote(msg.sender, _proposalID)) {
      _;
    }
  }

  modifier haswon(uint _proposalID) {
    if(rules.hasWon(_proposalID)) {
      _;
    }
  }

  modifier onlyself() {
    if(msg.sender == address(this)) {
      _;
    }
  }
  
  /// @notice The contract fallback function
  function () payable public {}

  function newProposal(string _name, address _proxy, uint _debatePeriod, address _destination, uint _value, bytes _calldata) returns (uint proposalID) {
    proposalID = proposals.length;
    Proposal memory p;
    p.name = _name;
    p.destination = _destination;
    p.value = _value;
    p.proxy = _proxy;
    p.hash = sha3(_destination, _value, _calldata);
    p.debatePeriod = _debatePeriod * 1 days;
    p.created = now;
    p.from = msg.sender;
    proposals.push(p);
    ProposalCreated(proposalID, _destination, _value);
  }

  function vote(uint _proposalID, uint _position) canvote(_proposalID) returns (uint voterWeight) {
    voterWeight = rules.votingWeightOf(msg.sender, _proposalID);
    proposals[_proposalID].votes[msg.sender] = Vote({
      position: _position,
      weight: voterWeight,
      created: now
    });
    proposals[_proposalID].voters.push(msg.sender);
    proposals[_proposalID].positions[_position] += voterWeight;
    VoteCounted(_proposalID, _position, msg.sender);
  }

  function execute(uint _proposalID, bytes _calldata) haswon(_proposalID) {
    Proposal p = proposals[_proposalID];
    if(!p.executed && sha3(p.destination, p.value, _calldata) == p.hash) {
      p.executed = true;
      if(p.proxy != address(0)) {
        Proxy(p.proxy).forward_transaction(p.destination, p.value, _calldata);
      } else {
        if(!p.destination.call.value(p.value)(_calldata)){
          throw;
        }
      }

      ProposalExecuted(_proposalID, msg.sender);
    }
  }

  function changeRules(address _rules) onlyself {
    rules = Rules(_rules);
  }

  function destructSelf(address _destination) onlyself {
    selfdestruct(_destination);
  }


  function positionWeightOf(uint _proposalID, uint _position) constant returns (uint) {
    return proposals[_proposalID].positions[_position];
  }

  function voteOf(uint _proposalID, address _voter) constant returns (uint position, uint weight, uint created) {
    Vote v = proposals[_proposalID].votes[_voter];
    position = v.position;
    weight = v.weight;
    created = v.created;
  }

  function voterAddressOf(uint _proposalID, uint _voteID) constant returns (address) {
    return proposals[_proposalID].voters[_voteID];
  }

  function numVoters(uint _proposalID) constant returns (uint) {
    return proposals[_proposalID].voters.length;
  }

  function numProposals() constant returns (uint) {
    return proposals.length;
  }

  function hasVoted(uint _proposalID, address _voter) constant returns (bool) {
    if(proposals[_proposalID].votes[_voter].created > 0) {
      return true;
    }
  }

  function destinationOf(uint _proposalId) public constant returns (address) {
    return proposals[_proposalId].destination;
  }

  function proxyOf(uint _proposalId) public constant returns (address) {
    return proposals[_proposalId].proxy;
  }

  function valueOf(uint _proposalId) public constant returns (uint) {
    return proposals[_proposalId].value;
  }

  function hashOf(uint _proposalId) public constant returns (bytes32) {
    return proposals[_proposalId].hash;
  }

  function debatePeriodOf(uint _proposalId) public constant returns (uint) {
    return proposals[_proposalId].debatePeriod;
  }

  function createdOn(uint _proposalId) public constant returns (uint) {
    return proposals[_proposalId].created;
  }

  function createdBy(uint _proposalId) public constant returns (address) {
    return proposals[_proposalId].from;
  }

  struct Proposal {
    string name;
    address destination;
    address proxy;
    uint value;
    bytes32 hash;
    bool executed;
    uint debatePeriod;
    uint created;
    address from;
    mapping(uint => uint) positions;
    mapping(address => Vote) votes;
    address[] voters;
  }

  struct Vote {
    uint position;
    uint weight;
    uint created;
  }

  Proposal[] public proposals;
  Rules public rules;
}
