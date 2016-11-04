pragma solidity ^0.4.3;

import "Rules.sol";
import "examples/StandardTokenFreezer.sol";
import "BoardRoom.sol";

contract LiquidDemocracyRules is Rules {
  modifier boardConfigured (address _board) {
    if (isConfigured[_board]) {
      _;
    } else {
        throw;
    }
  }

  modifier bondPosted (address _board, uint _proposalID) {
    if (bonds[_board][_proposalID] >= minimumBondRequired) {
      _;
    } else {
        throw;
    }
  }

  function LiquidDemocracyRules (address _freezer, address[] _curators, uint _minimumBondRequired) public {
    token = StandardTokenFreezer(_freezer);
    curators[address(this)] = _curators;
    minimumBondRequired = _minimumBondRequired;
    startBlock = block.number;
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

  function addCurator (address _curator) boardConfigured(msg.sender) public {
      curators[msg.sender].push(_curator);
      isCurator[msg.sender][_curator] = true;
  }

  function removeCurator (address _curator) boardConfigured(msg.sender) public {
      isCurator[msg.sender][_curator] = false;

      for(uint i = 0; i < curators[msg.sender].length; i++){
          if (curators[msg.sender][i] == _curator) {
              delete curators[msg.sender][i];
          }
      }
  }

  function resignAsCurator(address _board) boardConfigured(_board) public {
      isCurator[_board][msg.sender] = false;

      for(uint i = 0; i < curators[msg.sender].length; i++){
          if (curators[_board][i] == msg.sender) {
              delete curators[_board][i];
          }
      }
  }
  function depositBond(address _board, uint _proposalID) payable {
    bonds[_board][_proposalID] += msg.value;
    balance[_board] += msg.value;
  }
  function delegateVote(address _board, address _delegate, uint _proposalID) bondPosted(_board, _proposalID) public returns (bool) {
    BoardRoom board = BoardRoom(_board);
    uint created = board.createdOn(_proposalID);
    uint debatePeriod = board.debatePeriodOf(_proposalID);

    if(votingWeightOf(msg.sender, _proposalID) > 0
      && now < (created + debatePeriod)
      && token.frozenUntil(msg.sender) > (created + debatePeriod)
      && board.hasVoted(_proposalID, msg.sender) == false
      && delegated[_board][_proposalID][msg.sender] == false) {
      delegated[_board][_proposalID][msg.sender] = true;
      delegatedTo[_board][_proposalID][msg.sender] = _delegate;
      delegatedWeight[_board][_proposalID][_delegate] += token.balanceOf(msg.sender);
      return true;
    }
    return  false;
  }

  function hasWon (uint _proposalID) boardConfigured(msg.sender) bondPosted(msg.sender, _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);

    uint nay = board.positionWeightOf(_proposalID, 0);
    uint yea = board.positionWeightOf(_proposalID, 1);

    for(uint i = 0; i < curators[msg.sender].length; i++){
      var (position, weight, created) = board.voteOf(_proposalID, curators[msg.sender][i]);
      if (position == 0 && curators[msg.sender][i] != address(0x0)){
        return false;
      }
    }

    uint quorum = StandardToken(token.token()).totalSupply();
    uint divisor = 20;

    if (block.number > startBlock + 5000) {
      divisor = 40;
    }

    if (block.number > startBlock + 10000) {
      divisor = 60;
    }

    if((yea + nay) > quorum / divisor && yea > nay) {
      return true;
    }
  }

  function canVote (address _sender, uint _proposalID) boardConfigured(msg.sender) bondPosted(msg.sender, _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);

    uint created = board.createdOn(_proposalID);
    uint debatePeriod = board.debatePeriodOf(_proposalID);
    return true;
    if(votingWeightOf(_sender, _proposalID) > 0
      && now < (created + debatePeriod)
      && token.frozenUntil(_sender) > (created + debatePeriod)
      && delegated[msg.sender][_proposalID][_sender] == false
      && board.hasVoted(_proposalID, _sender) == false) {
      return true;
    }
  }

  function canPropose (address _sender) boardConfigured(msg.sender) public constant returns (bool) {
    if(token.balanceOf(_sender) > 0) {
      return true;
    }
  }

  function widthrawBondFunds(address _destination) payable {
    if (balance[msg.sender] > 0) {
      uint balanceToSend = balance[msg.sender];
      balance[msg.sender] = 0;

      if (!_destination.send(balanceToSend)) {
        throw;
      }
    }
  }

  function votingWeightOf (address _sender, uint _proposalID) public constant returns (uint) {
    if (delegated[msg.sender][_proposalID][_sender] == false) {
      return token.balanceOf(_sender) + delegatedWeight[msg.sender][_proposalID][_sender] ;
    }
  }

  StandardTokenFreezer public token;
  mapping(address => bool) public isConfigured;

  uint public minimumBondRequired;
  uint public startBlock;
  mapping(address => uint) public balance;
  mapping(address => mapping(uint => uint)) public bonds;

  mapping(address => mapping(uint => mapping(address => bool))) public delegated;
  mapping(address => mapping(uint => mapping(address => address))) public delegatedTo;
  mapping(address => mapping(uint => mapping(address => uint))) public delegatedWeight;

  mapping(address => address[]) public curators;
  mapping(address => mapping(address => bool)) public isCurator;
}
