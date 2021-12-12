import { CRGToken } from "./../../typechain-types/CRGToken";
import { CRGToken__factory } from "./../../typechain-types/factories/CRGToken__factory";
import { Console } from "console";
import { DAO } from "./../../typechain-types/DAO";
import { DAO__factory } from "./../../typechain-types/factories/DAO__factory";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import Web3 from "web3";
import { ethers } from "ethers";
import { getConfig } from "../../utils/networks";
import { task } from "hardhat/config";

task("vote", "Do vote for proposal", async (args, hre) => {
  const [owner, addr1] = await hre.ethers.getSigners();
  const networkName = hre.network.name;
  const web3 = new Web3(Web3.givenProvider);
  console.log(`networkName`, networkName);
  const { tokenName, tokenAddress, tokenSymbol, tokenDecimals } =
    getConfig(networkName);

  let Token: CRGToken__factory;
  let token: CRGToken;
  if (networkName === "bsc_testnet") {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.attach(tokenAddress);
  } else {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.deploy(tokenName, tokenSymbol, tokenDecimals);
  }
});
