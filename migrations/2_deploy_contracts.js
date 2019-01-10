var Relay=artifacts.require("Relay");
var RLP=artifacts.require("RLP");
module.exports = function(deployer) {
  deployer.deploy(Relay);
  deployer.deploy(RLP);
};
