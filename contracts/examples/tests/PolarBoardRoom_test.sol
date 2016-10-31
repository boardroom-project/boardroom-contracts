pragma solidity ^0.4.3;


import "dapple/test.sol";
import "BoardRoom.sol";
import "OwnedProxy.sol";

import "examples/HumanStandardTokenFactory.sol";
import "examples/StandardToken.sol";
import "examples/StandardTokenFreezer.sol";
import "examples/TokenFreezerRules.sol";

contract BoardMemberProxy {
  /// @notice The contract fallback function
  function () payable public {}

  function createHumanStandardToken(address _factory, uint256 _initialAmount, string _name, uint8 _decimals, string _symbol) returns (address) {
    return HumanStandardTokenFactory(_factory).createHumanStandardToken(_initialAmount, _name, _decimals, _symbol);
  }

  function approve(address _token, address _spender, uint256 _value) returns (bool success) {
    return StandardToken(_token).approve(_spender, _value);
  }

  function freezeAllowance(address _freezer, uint _daysToThaw) returns (uint amountFrozen) {
    return StandardTokenFreezer(_freezer).freezeAllowance(_daysToThaw);
  }

  function newProposal(address _board, string _name, address _proxy, uint _debatePeriod, address _destination, uint _value, bytes _calldata) returns (uint proposalID) {
    return BoardRoom(_board).newProposal(_name, _proxy, _debatePeriod, _destination, _value, _calldata);
  }

  function vote(address _board, uint _proposalID, uint _position) returns (uint voteWeight) {
    return BoardRoom(_board).vote(_proposalID, _position);
  }

  function transfer(address _token, address _to, uint256 _value) returns (bool success) {
    return StandardToken(_token).transfer(_to, _value);
  }

  function execute(address _board, uint _proposalID, bytes _calldata) {
    return BoardRoom(_board).execute(_proposalID, _calldata);
  }
}

contract PolarBoardRoomTests is Test {
  BoardMemberProxy member1;
  BoardMemberProxy member2;
  BoardMemberProxy member3;
  BoardMemberProxy member4;
  BoardMemberProxy member5;
  BoardMemberProxy member6;
  BoardMemberProxy destinationAccount;
  HumanStandardTokenFactory tokenFactory;
  address humanToken;
  StandardToken token;
  StandardTokenFreezer freezer;
  TokenFreezerRules rules;
  BoardRoom board;
  OwnedProxy proxy;

  function setUp(){
    member1 = new BoardMemberProxy();
    member2 = new BoardMemberProxy();
    member3 = new BoardMemberProxy();
    member4 = new BoardMemberProxy();
    member5 = new BoardMemberProxy();
    member6 = new BoardMemberProxy();
    destinationAccount = new BoardMemberProxy();
    tokenFactory = new HumanStandardTokenFactory();
    humanToken = member1.createHumanStandardToken(address(tokenFactory), 5000, "Some Token", 8, "SST");
    token = StandardToken(humanToken);
    freezer = new StandardTokenFreezer(address(token));
    rules = new TokenFreezerRules(address(freezer));
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));

    if (!proxy.send(1000)) {
      throw;
    }
  }

  function test_polarBoardInstance() {
    // setup member 1
    assertTrue(member1.approve(address(token), address(freezer), 500));
    assertEq(member1.freezeAllowance(address(freezer), 60), 500);
    assertEq(freezer.balanceOf(address(member1)), 500);

    // setup member 2
    assertTrue(member1.transfer(address(token), address(member2), 500));
    assertTrue(member2.approve(address(token), address(freezer), 500));
    assertEq(member2.freezeAllowance(address(freezer), 60), 500);
    assertEq(freezer.balanceOf(address(member1)), 500);

    // setup member 3
    assertTrue(member1.transfer(address(token), address(member3), 500));
    assertTrue(member3.approve(address(token), address(freezer), 500));
    assertEq(member3.freezeAllowance(address(freezer), 60), 500);
    assertEq(freezer.balanceOf(address(member1)), 500);

    // setup member 4
    assertTrue(member1.transfer(address(token), address(member4), 500));
    assertTrue(member4.approve(address(token), address(freezer), 500));
    assertEq(member4.freezeAllowance(address(freezer), 60), 500);
    assertEq(freezer.balanceOf(address(member1)), 500);

    // setup member 5
    assertTrue(member1.transfer(address(token), address(member5), 500));
    assertTrue(member5.approve(address(token), address(freezer), 500));
    assertEq(member5.freezeAllowance(address(freezer), 60), 500);
    assertEq(freezer.balanceOf(address(member1)), 500);

    // setup member 6
    //assertTrue(member1.transfer(address(token), address(member6), 500));
    //assertTrue(member6.approve(address(token), address(freezer), 500));
    //assertEq(member6.freezeAllowance(address(freezer), 60), 500);
    //assertEq(freezer.balanceOf(address(member1)), 500);

    assertEq(member3.newProposal(address(board),
    "Some new Proposal", address(proxy),
     30, address(destinationAccount), 600, ""), 0);
    assertEq(board.numProposals(), 1);
    assertEq(member1.vote(address(board), 0, 1), 500);
    assertEq(board.numVoters(0), 1);
    assertEq(member2.vote(address(board), 0, 0), 500);
    assertEq(member3.vote(address(board), 0, 1), 500);
    assertEq(board.numVoters(0), 3);
    assertEq(member4.vote(address(board), 0, 1), 500);
    assertEq(member5.vote(address(board), 0, 0), 500);
    assertEq(board.numVoters(0), 5);

    assertEq(destinationAccount.balance, 0);
    assertEq(proxy.balance, 1000);
    member5.execute(address(board), 0, "");
    assertEq(proxy.balance, 400);
    var (p1_name, p1_destination, p1_proxy, p1_value, p1_validityHash, p1_executed, p1_debatePeriod, p1_created, p1_from) = board.proposals(0);
    assertTrue(p1_executed);
    assertEq(destinationAccount.balance, 600);
  }

  /*
  function test_spamApproveAndFreeze() {
  }

  function test_spamFreeze() {
  }

  function test_invalidProposalBytecode() {
  }

  function test_doubleVotingFor() {
  }

  function test_doubleVotingAgainst() {
  }

  function test_invalidProposalDuration() {
  }

  function test_invalidProposalValue() {
  }

  function test_spamVoting() {
  }

  function test_forAgainst() {
  }

  function test_againstFor() {
  }

  function test_invalidSuicide() {
  }

  function test_voteSpammingAgainst() {
  }

  function test_voteSpammingFor(){
  }

  function test_validProposalExecution() {
  }

  function test_invalidProposalExecution() {
  }

  function test_validProxyOwnershipTransfer() {
  }

  function test_invalidProxyOwnershipTransfer() {
  }

  function test_validRuleChange() {
  }

  function test_invalidRuleChange() {
  }

  function test_validBoardFundTransfer() {
  }

  function test_validProxyFundTransfer() {
  }*/
}
