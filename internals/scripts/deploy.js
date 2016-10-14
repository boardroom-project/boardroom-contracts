const deployer = require('ethdeploy');
const config = require('../ethdeploy/ethdeploy.openrules.testnet.js');

deployer(config, function(deployError, deployObject){
  console.log(deployError, deployObject);
});
