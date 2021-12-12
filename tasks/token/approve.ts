import { getConfig } from "./.././../../utils/networks";
import { task } from "hardhat/config";

task("approve", "Approve token")
  .addParam("spender", "Spender account address")
  .addParam("amount", "Amount of tokens")
  .setAction(async (taskArgs, hre) => {
    const [owner] = await hre.ethers.getSigners();

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

    await token
      .connect(owner)
      .approve(
        taskArgs.spender,
        hre.ethers.utils.parseUnits(taskArgs.amount, 18)
      );
  });
