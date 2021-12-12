import { getConfig } from "./../utils/networks";
import "@nomiclabs/hardhat-ethers";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import { Contract } from "ethers";

import { BaseProvider } from "@ethersproject/providers";
import { CRGToken } from "../typechain-types/CRGToken";
import { CRGToken__factory } from "../typechain-types/factories/CRGToken__factory";

import { expect } from "chai";
import hre from "hardhat";
import { DAO__factory } from "../typechain-types/factories/DAO__factory";
import { DAO } from "../typechain-types/DAO";
import CRGToken_json from "../artifacts/contracts/Token/CRGToken.sol/CRGToken.json";
import { id } from "ethers/lib/utils";

const { ethers } = hre;
const name = "Corgy";
const symbol = "CRG";
const initialSupply = "1000";
const decimals = 18;
const bigNumberInitialSupply = ethers.utils.parseUnits(initialSupply, decimals);

const requiredMessage = {
  tokenOwner: "DAO: You are not a token owner",
  nonExistedFunction: "DAO: The called function is not in the contract",
  proposalDoesNotExist: "DAO: Proposal doesn't exist",
};

let Token: CRGToken__factory;
let token: CRGToken;
let tokenAddress: string;
let tokenAbiInterface = new ethers.utils.Interface(CRGToken_json.abi);

const existedTokenFunctionName = "name";
let existedTokenFunctionAbi = [`function ${existedTokenFunctionName}()`];
let existedTokenFunction = new ethers.utils.Interface(
  existedTokenFunctionAbi
).encodeFunctionData(existedTokenFunctionName, []);

const nonExistedTokenFunctionName = "foo";
let nonExistedTokenFunctionAbi = [`function ${nonExistedTokenFunctionName}()`];
let nonExistedTokenFunction = new ethers.utils.Interface(
  nonExistedTokenFunctionAbi
).encodeFunctionData(nonExistedTokenFunctionName, []);

let DAO: DAO__factory;
let dao: DAO;
const proposalDescription = "Let's make DAO great again";
const proposalId = 0;
let proposalRecipient: string;

let provider: BaseProvider;
let owner: SignerWithAddress;
let alice: SignerWithAddress;
let bob: SignerWithAddress;
let ownerBalance;
let aliceBalance;
let bobBalance;

describe("Proposals", async function () {
  beforeEach(async function () {
    provider = ethers.getDefaultProvider();
    [owner, alice, bob] = await ethers.getSigners();

    Token = await ethers.getContractFactory("CRGToken");
    token = await Token.deploy(name, symbol, decimals);
    tokenAddress = token.address;
    proposalRecipient = tokenAddress;

    ownerBalance = ethers.utils.formatEther(
      await token.balanceOf(owner.address)
    );
    aliceBalance = ethers.utils.formatEther(
      await token.balanceOf(alice.address)
    );
    bobBalance = ethers.utils.formatEther(await token.balanceOf(bob.address));

    DAO = await ethers.getContractFactory("DAO");
    dao = await DAO.deploy(name, symbol, tokenAddress);
    console.log(`ex`, existedTokenFunction, nonExistedTokenFunction);
  });

  describe("newProposal", async function () {
    it("should revert if not tokenOwner", async function () {
      await expect(
        dao
          .connect(bob)
          .newProposal(
            proposalRecipient,
            proposalDescription,
            nonExistedTokenFunction
          )
      ).to.be.revertedWith(requiredMessage.tokenOwner);
    });
  });

  describe("executeProposal", async function () {
    console.log(`ex`, existedTokenFunction, nonExistedTokenFunction);
    it("should revert if function does not exist", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        nonExistedTokenFunction
      );

      await expect(dao.executeProposal(proposalId)).to.be.revertedWith(
        requiredMessage.nonExistedFunction
      );
    });

    it("should revert if proposal does not exist", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        nonExistedTokenFunction
      );

      await expect(dao.executeProposal(10)).to.be.revertedWith(
        requiredMessage.proposalDoesNotExist
      );
    });

    it("should emit 'ProposalExecutionSucceeded' if execution succeeded if function exist", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await expect(dao.executeProposal(proposalId))
        .to.emit(dao, "ProposalExecutionSucceeded")
        .withArgs(proposalId, proposalDescription, proposalRecipient);
    });
  });
});
