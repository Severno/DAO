import { getConfig } from "./../../utils/networks";
import { task } from "hardhat/config";

task("name", "Token name").setAction(async (taskArgs, hre) => {
  const networkName = hre.network.name;
  const { tokenName, tokenAddress, tokenSymbol, tokenDecimals } =
    getConfig(networkName);

  let Token;
  let token;
  if (networkName === "bsc_testnet") {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.attach(tokenAddress);
  } else {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.deploy(tokenName, tokenSymbol, tokenDecimals);
  }

  const name = await token.name();
  console.log(`Token name: ${name}`);
});

task("symbol", "Token symbol").setAction(async (taskArgs, hre) => {
  const networkName = hre.network.name;
  const { tokenName, tokenAddress, tokenSymbol, tokenDecimals } =
    getConfig(networkName);

  let Token;
  let token;
  if (networkName === "bsc_testnet") {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.attach(tokenAddress);
  } else {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.deploy(tokenName, tokenSymbol, tokenDecimals);
  }

  const symbol = await token.symbol();
  console.log(`Token symbol: ${symbol}`);
});

task("totalSupply", "Token totalSupply").setAction(async (taskArgs, hre) => {
  const networkName = hre.network.name;
  const { tokenName, tokenAddress, tokenSymbol, tokenDecimals } =
    getConfig(networkName);

  let Token;
  let token;
  if (networkName === "bsc_testnet") {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.attach(tokenAddress);
  } else {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.deploy(tokenName, tokenSymbol, tokenDecimals);
  }

  const totalSupply = await token.totalSupply();
  console.log(`Token totalSupply: ${totalSupply}`);
});

task("decimals", "Token decimals").setAction(async (taskArgs, hre) => {
  const networkName = hre.network.name;
  const { tokenName, tokenAddress, tokenSymbol, tokenDecimals } =
    getConfig(networkName);

  let Token;
  let token;
  if (networkName === "bsc_testnet") {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.attach(tokenAddress);
  } else {
    Token = await hre.ethers.getContractFactory("CRGToken");
    token = await Token.deploy(tokenName, tokenSymbol, tokenDecimals);
  }

  const decimals = await token.decimals();
  console.log(`Token name: ${decimals}`);
});
