import { getConfig } from "././../../utils/networks";
import { task } from "hardhat/config";

task("allowance", "Allowance for account")
  .addParam("owner", "TokenOwner address")
  .addParam("spender", "Spender account address")
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

    const allowance = await token.allowance(taskArgs.owner, taskArgs.spender);
    console.log(
      `Owner: ${taskArgs.owner}\nSpender: ${taskArgs.spender}\nAllowance: ${allowance}`
    );
  });
