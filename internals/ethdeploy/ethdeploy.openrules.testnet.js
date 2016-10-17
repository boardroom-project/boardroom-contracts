const contracts = require('../../lib/classes.json');
const account = require('../../../account.json');
const Tx = require('ethereumjs-tx');
const ethUtil = require('ethereumjs-util');

module.exports = {
  output: {
    environment: 'testnet',
    path: './lib/environments.json',
  },
  entry: {
    testnet: contracts,
  },
  module: function(deploy, contracts, environment){
    deploy(contracts.OpenRules).then(function(openRulesInstance){
      deploy(contracts.BoardRoom, openRulesInstance.address).then(function(openBoard){
        console.log(openBoard);
      });
    });
  },
  config: {
    defaultAccount: 0,
    defaultGas: 3000000,
    environments: {
      testnet: {
        provider: {
          type: 'zero-client',
          getAccounts: function(cb) {
            // dont include keys anywhere inside or around repo
            cb(null, [account.address]);
          },
          signTransaction: function(rawTx, cb) {
            // dont include private key info anywhere around repo
            const privateKey = new Buffer(account.privateKey, 'hex');

            // tx construction
            const tx = new Tx(rawTx);
            tx.sign(privateKey);

            // callback with buffered serilized signed tx
            cb(null, ethUtil.bufferToHex(tx.serialize()));
          },
          'host': 'https://morden.infura.io',
          'port': 8545,
        },
        objects: {
          OpenBoardRoom: {
            class: 'BoardRoom',
            from: 0, // a custom account
            gas: 2900000, // some custom gas
          },
        },
      },
    },
  },
};
