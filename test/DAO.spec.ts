import { getConfig } from "./../utils/networks";
import "@nomiclabs/hardhat-ethers";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import { BigNumber, Contract } from "ethers";

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
const amount = ethers.utils.parseUnits("10", decimals);
const bigAmount = ethers.utils.parseUnits("20", decimals);

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
const votingDeadline: number = Number(new Date(Date.now() + 86400000 * 3));
const minQuorum = BigNumber.from(32);

let provider: BaseProvider;
let owner: SignerWithAddress;
let alice: SignerWithAddress;
let bob: SignerWithAddress;
let ownerBalance: string;
let aliceBalance: string;
let bobBalance: string;

console.log(`votingDeadline`, votingDeadline);

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
    dao = await DAO.deploy(name, symbol, tokenAddress, minQuorum);
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
            nonExistedTokenFunction,
            votingDeadline
          )
      ).to.be.revertedWith(requiredMessage.tokenOwner);
    });

    it("should emit 'ProposalCreated'", async function () {
      await expect(
        dao.newProposal(
          proposalRecipient,
          proposalDescription,
          existedTokenFunction,
          votingDeadline
        )
      )
        .to.emit(dao, "ProposalCreated")
        .withArgs(
          proposalRecipient,
          owner.address,
          existedTokenFunction,
          proposalId
        );
    });

    it("should return proposalId", async function () {
      const _proposalId = await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );

      console.log(`_proposalId`, _proposalId);

      // expect(
      //   ethers.utils.formatUnits(
      //     await
      //   )
      // ).to.be.equal(proposalId);
    });
  });

  describe("executeProposal", async function () {
    it("should revert if function does not exist", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        nonExistedTokenFunction,
        votingDeadline
      );

      await expect(dao.executeProposal(proposalId)).to.be.revertedWith(
        requiredMessage.nonExistedFunction
      );
    });

    it("should revert if proposal does not exist", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        nonExistedTokenFunction,
        votingDeadline
      );

      await expect(dao.executeProposal(10)).to.be.revertedWith(
        requiredMessage.proposalDoesNotExist
      );
    });

    it("should emit 'ProposalExecutionSucceeded' if execution succeeded if function exist", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );
      console.log(
        `ethers.utils.parseUnits("500", decimals)`,
        ethers.utils.formatEther(ethers.utils.parseUnits("500", decimals))
      );
      await token.approve(
        dao.address,
        ethers.utils.parseUnits("500", decimals)
      );

      await dao.vote(proposalId, {
        value: ethers.utils.parseUnits("500", decimals),
      });

      const tx = await dao.executeProposal(proposalId);

      let receipt = await tx.wait();

      receipt.events
        ?.filter((x) => {
          return x.event == "ProposalExecutionSucceeded";
        })
        .forEach((x) => {
          x?.args?.forEach((y) => {
            console.log(y);
          });
        });
      await expect(dao.executeProposal(proposalId))
        .to.emit(dao, "ProposalExecutionSucceeded")
        .withArgs(proposalId, proposalDescription, proposalRecipient);
    });
  });

  describe("vote", async function () {
    it("should emit 'Voted'", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );

      await token.approve(dao.address, amount);

      await expect(dao.vote(proposalId, { value: amount }))
        .to.emit(dao, "Voted")
        .withArgs(proposalId, owner.address, amount);
    });

    it("should emit 'Voted' after transfer", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );

      await token.transfer(alice.address, bigAmount);

      await token.connect(alice).approve(dao.address, bigAmount);

      await expect(dao.connect(alice).vote(proposalId, { value: amount }))
        .to.emit(dao, "Voted")
        .withArgs(proposalId, alice.address, amount);
    });

    it("should revert if not a token owner", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );

      await expect(dao.connect(alice).vote(proposalId)).to.be.revertedWith(
        "DAO: You are not a token owner"
      );
    });

    it("should revert if sender doesn't have enough token balance", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );

      await token.transfer(alice.address, amount);

      await expect(
        dao.connect(alice).vote(proposalId, { value: bigAmount })
      ).to.be.revertedWith(
        "DAO: You don't have enough balance to make the transaction"
      );
    });

    it("should change voter balance and increase DAO balance", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );

      await token.approve(dao.address, amount);

      await dao.vote(proposalId, { value: amount });

      const subBalance = ethers.utils.parseEther(ownerBalance).sub(amount);

      expect(
        ethers.utils.formatEther(await token.balanceOf(owner.address)),
        "Token owner balance is incorrect"
      ).to.be.equal(ethers.utils.formatEther(subBalance));

      expect(
        await token.balanceOf(dao.address),
        "DAO balance is incorrect"
      ).to.be.equal(amount);
    });
    it("test allowance", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction,
        votingDeadline
      );

      const ownBalanceBefore = ethers.utils.formatEther(
        await token.balanceOf(owner.address)
      );

      const tx = await dao.approveSomething();

      let receipt = await tx.wait();

      receipt.events
        ?.filter((x) => {
          return x.event == "Allow";
        })
        .forEach((x) => {
          x?.args?.forEach((y) => {
            console.log(y);
          });
        });

      const transactionHash = receipt!.events![0].transactionHash;

      provider.getTransaction(transactionHash).then(function (transaction) {
        console.log(transaction);
      });

      console.log(receipt.events);
      // console.log(tx1);

      // const ownBalanceAfter = ethers.utils.formatEther(
      //   await token.balanceOf(owner.address)
      // );

      // console.log(`ownBalance`, ownBalanceAfter, ownBalanceBefore);

      // const subBalance = ethers.utils.parseEther(ownerBalance).sub(amount);
    });
  });
});
