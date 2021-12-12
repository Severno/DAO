import { getConfig } from "./../../utils/networks";
import { task } from "hardhat/config";

task("balanceOf", "Account token balance")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs, hre) => {
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

    const balance = await token.balanceOf(taskArgs.account);
    console.log(
      `${taskArgs.account} account balance is ${hre.ethers.utils.formatUnits(
        balance,
        18
      )} tokens`
    );
  });
