var Marketplace= artifacts.require("./Marketplace.sol");
var BoredPetsNFT= artifacts.require("./BoredPetsNFT.sol");

module.exports = async function(deployer){
    await deployer.deploy(Marketplace);
    const marketplace= await Marketplace.deployed();
    await deployer.deploy(BoredPetsNFT,marketplace.address);
}