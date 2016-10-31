pragma solidity ^0.4.3;

import "examples/HumanStandardToken.sol";

contract HumanStandardTokenDispersal {
  event TokenCreated(address _token);

  function createHumanStandardToken (
      address[] _accounts,
      uint[] _accountAmounts,
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol
      ) returns (address) {
      uint totalSupply = 0;

      for (uint accountIndexSupply = 0; accountIndexSupply < _accounts.length; accountIndexSupply++) {
        totalSupply += _accountAmounts[accountIndexSupply];
      }

      HumanStandardToken newToken = new HumanStandardToken(totalSupply, _tokenName, _decimalUnits, _tokenSymbol);
      TokenCreated(address(newToken));

      for (uint accountIndex = 0; accountIndex < _accounts.length; accountIndex++) {
        newToken.transfer(_accounts[accountIndex], _accountAmounts[accountIndex]);
      }

      return address(newToken);
  }
}
