pragma solidity ^0.4.3;

import "dapple/test.sol";
import "examples/HumanStandardToken.sol";
import "examples/HumanStandardTokenDispersal.sol";

contract HumanStandardTokenDispersalTest is Test {
  uint[] amounts;
  address[] accounts;

  function test_dispersal(){
    HumanStandardTokenDispersal dispersal = new HumanStandardTokenDispersal();
    amounts.push(uint(6));
    amounts.push(uint(6));
    amounts.push(uint(3));
    accounts.push(0x62E2F894964197A2458D8E8276e43450E9f5b885);
    accounts.push(0x4464eD250Ea774146A0fBbC1da0Ffa6a81514cA7);
    accounts.push(0x50B8B06AB0cbfb26EA867E9F5175593883e481eD);
    address tokenAddr = dispersal.createHumanStandardToken(
        accounts,
        amounts,
        "ConsenSysNorthToken",
        7,
        "CNT");
    assertTrue(bool(tokenAddr != address(0)));
    HumanStandardToken token = HumanStandardToken(tokenAddr);
    assertEq(token.balanceOf(0x62E2F894964197A2458D8E8276e43450E9f5b885), 6);
    assertEq(token.balanceOf(0x4464eD250Ea774146A0fBbC1da0Ffa6a81514cA7), 6);
    assertEq(token.balanceOf(0x50B8B06AB0cbfb26EA867E9F5175593883e481eD), 3);
  }
}
