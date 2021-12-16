import "@nomiclabs/hardhat-ethers";

import { DAO, DAO__factory } from "../typechain-types";

import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const DAO: DAO__factory = await ethers.getContractFactory("DAO");
  const dao: DAO = await DAO.deploy(
    "0xaC60eeeD4adcea750Da61560e30Fa13607125f9d",
    32
  );

  console.log("DAO address:", dao.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
