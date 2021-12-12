import { BigNumber, utils } from "ethers";

import { DAO } from "../../typechain-types/DAO";
import { DAO__factory } from "../../typechain-types/factories/DAO__factory";
import { getConfig } from "../../utils/networks";
import { task } from "hardhat/config";

task("contractBalance", "Get contract balance", async (args, hre) => {
  const { ethers } = hre;
  const networkName = hre.network.name;
  const { tokenName, tokenAddress, tokenSymbol, tokenDecimals } =
    getConfig(networkName);
  const [owner, addr1, addr2] = await ethers.getSigners();
  const DAO: DAO__factory = await ethers.getContractFactory("DAO");
  const provider = await ethers.provider;
  // const dao: DAO = await DAO.deploy(tokenName, tokenSymbol);

  // await dao.makeDonation({ value: "10000" });
  // //   await ethers.c owner.sendTransaction(tx);
  // const balance = await (await provider.getBalance(dao.address)).toNumber();

  // console.log(
  //   "🚀 ~ file: contractBalance.ts ~ line 6 ~ task ~ owner, addr1, addr2",
  //   dao.address,
  //   await (await provider.getBalance(owner.address)).toString(),
  //   await (await provider.getBalance(addr1.address)).toString(),
  //   await (await provider.getBalance(addr2.address)).toString(),
  //   balance
  // );
});
