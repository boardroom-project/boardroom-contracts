import "dapple/test.sol";
import "BoardRoom.sol";
import "examples/CuratorRule.sol";
import "examples/OpenRegistry.sol";
import "OwnedProxy.sol";

contract MemberProxy {
  function newProposal(address _board, string _name, address _proxy, uint _debatePeriod, address _destination, uint _value, bytes _calldata) returns (uint proposalID) {
    return BoardRoom(_board).newProposal(_name, _proxy, _debatePeriod, _destination, _value, _calldata);
  }
  function vote(address _board, uint _proposalID, uint _position) returns (uint voteWeight) {
    return BoardRoom(_board).vote(_proposalID, _position);
  }
  function execute(address _board, uint _proposalID, bytes _calldata) {
    return BoardRoom(_board).execute(_proposalID, _calldata);
  }
}

contract CuratorRuleBoardRoomTest is Test {
  OpenRegistry registry;
  OwnedProxy proxy;
  CuratorRule rules;
  BoardRoom board;
  MemberProxy member1;

  function setUp() {
    member1 = new MemberProxy();
    registry = new OpenRegistry();
    registry.register(address(member1));
    rules = new CuratorRule(address(registry));
    board = new BoardRoom(address(rules));
  }

  function test_openRegistry() {
    assertTrue(registry.isMember(address(member1)));
    assertEq(registry.members(0), address(member1));
  }

  function test_CuratorRules() {
    assertTrue(rules.canPropose(address(member1)));
    assertEq(rules.votingWeightOf(address(member1), 0), 1);
  }

  function test_curatorDoesVeto() {
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));
    if (proxy.send(600)){
    }

    address destinationAccount = address(new MemberProxy());
    MemberProxy member1 = new MemberProxy();
    registry.register(address(member1));
    rules.addCurator(address(member1));

    MemberProxy member2 = new MemberProxy();
    registry.register(address(member2));
    MemberProxy member3 = new MemberProxy();
    registry.register(address(member3));
    MemberProxy member4 = new MemberProxy();
    registry.register(address(member4));
    assertEq(member1.newProposal(address(board), "Does Jet Fuel Melt Steel Beams?", address(proxy), 30, destinationAccount, 400, ""), 0);

    member1.vote(address(board), 0, 0);
    member2.vote(address(board), 0, 1);
    member3.vote(address(board), 0, 1);
    member4.vote(address(board), 0, 1);
    assertEq(board.numVoters(0), 4);
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
    member1.execute(address(board), 0, "");
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
  }

  function test_curatorDoesNotVeto() {
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));
    if (proxy.send(600)){
    }

    address destinationAccount = address(new MemberProxy());
    MemberProxy member1 = new MemberProxy();
    registry.register(address(member1));
    rules.addCurator(address(member1));
    MemberProxy member2 = new MemberProxy();
    registry.register(address(member2));
    MemberProxy member3 = new MemberProxy();
    registry.register(address(member3));
    MemberProxy member4 = new MemberProxy();
    registry.register(address(member4));
    assertEq(member1.newProposal(address(board), "Does Jet Fuel Melt Steel Beams?", address(proxy), 30, destinationAccount, 400, ""), 0);

    member1.vote(address(board), 0, 1);
    member2.vote(address(board), 0, 0);
    member3.vote(address(board), 0, 1);
    member4.vote(address(board), 0, 1);
    assertEq(board.numVoters(0), 4);
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
    member1.execute(address(board), 0, "");
    assertEq(proxy.balance, 200);
    assertEq(destinationAccount.balance, 400);
  }

}
