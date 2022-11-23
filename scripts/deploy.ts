import { ethers } from "hardhat";

async function main() {

  const QDNS = await ethers.getContractFactory("QDNS");

  const qdns = await QDNS.deploy();

  await qdns.deployed();

  console.log(`Deployed QDNS to: ${qdns.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
