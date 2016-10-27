pragma solidity ^0.4.3;

contract OpenRegistry {
  function register(address _someMember) public {
    members.push(_someMember);
    isMember[_someMember] = true;
  }

  function numMembers() public constant returns (uint) {
    return members.length;
  }

  address[] public members;
  mapping(address => bool) public isMember;
}
