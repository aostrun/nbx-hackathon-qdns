import { ethers } from "hardhat";

async function main() {

  let [deployer] = await ethers.getSigners();

  const REGISTRY = await ethers.getContractFactory("MockContractRegistry");
  const PARAMS = await ethers.getContractFactory("QDNSParameters");
  const QDNS = await ethers.getContractFactory("QDNS");

  const registry = await REGISTRY.deploy();
  const params = await PARAMS.deploy();

  await registry.initialize([deployer.address], ["qdns.owner", "qdns.params"], [deployer.address, params.address]);

  await params.initialize(registry.address, [], [], [], [], [], [], [], []);

  await params.setUint("qdns.price", ethers.utils.parseEther("2"));
  await params.setUint("qdns.longAddressFee", ethers.utils.parseEther("1"));

  const qdns = await QDNS.deploy(registry.address);
  await qdns.deployed();

  let owner = await registry.mustGetAddress("qdns.owner");
  let currentPrice = await params.getUint("qdns.price");

  let price = await qdns.getPrice(ethers.utils.hexlify(ethers.utils.toUtf8Bytes("test.q")));

  console.log(`Price: ${price}`);

  console.log("ContractRegistry deployed to:", registry.address, `owner: ${owner}`);
  console.log(`Params deployed to: ${params.address}, current price: ${currentPrice}`);
  console.log(`Deployed QDNS to: ${qdns.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
