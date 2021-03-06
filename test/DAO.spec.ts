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
let dao: DAO & Contract;
const proposalDescription = "Let's make DAO great again";
const proposalId = 0;
let proposalRecipient: string;
let votingDeadline: number;
const minQuorum = BigNumber.from(32);

let provider: BaseProvider;
let owner: SignerWithAddress;
let alice: SignerWithAddress;
let bob: SignerWithAddress;
let ownerBalance: string;
let aliceBalance: string;
let bobBalance: string;

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
    dao = await DAO.deploy(tokenAddress, minQuorum);

    votingDeadline = (await ethers.provider.getBlock(1)).timestamp + 864 * 3;
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

    it("should emit 'ProposalCreated'", async function () {
      await expect(
        dao.newProposal(
          proposalRecipient,
          proposalDescription,
          existedTokenFunction
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
  });

  describe("executeProposal", async function () {
    it("should revert if function does not exist", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        nonExistedTokenFunction
      );

      const amount = ethers.utils.parseUnits("500", decimals);

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await dao.vote(proposalId);

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
      const amount = ethers.utils.parseUnits("500", decimals);

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await dao.vote(proposalId);

      await expect(dao.executeProposal(proposalId))
        .to.emit(dao, "ProposalExecutionSucceeded")
        .withArgs(proposalId, proposalDescription, proposalRecipient);
    });
  });

  describe("vote", async function () {
    it("revert if proposal expired", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await ethers.provider.send("evm_increaseTime", [259200]);

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await expect(dao.vote(proposalId)).to.be.revertedWith(
        "DAO: You're trying to call proposal that's is outdated"
      );
    });

    it("should emit 'Voted'", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await expect(dao.vote(proposalId))
        .to.emit(dao, "Voted")
        .withArgs(proposalId, owner.address);
    });

    it("should emit 'Voted' after transfer", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await token.transfer(alice.address, bigAmount);

      await token.connect(alice).approve(dao.address, bigAmount);

      await dao.connect(alice).deposit(amount);

      await expect(dao.connect(alice).vote(proposalId))
        .to.emit(dao, "Voted")
        .withArgs(proposalId, alice.address);
    });

    it("should revert if not have enough token balance on DAO", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await expect(dao.connect(alice).vote(proposalId)).to.be.revertedWith(
        "DAO: You have not enought tokens deposited for voting"
      );
    });

    it("should change voter balance and increase DAO balance", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await dao.vote(proposalId);

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
  });
  describe("unVote", async function () {
    it("should revert if not a voter", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await expect(
        dao.unVote(proposalId),
        "DAO balance should be 0"
      ).to.be.revertedWith("DAO: You're not a voter");
    });
  });
  describe("getProposal", async function () {
    it("should get proposal info", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await dao.vote(proposalId);

      const [descr, votingResult, sum] = await dao.getProposal(proposalId);

      expect(
        [descr, votingResult, sum],
        "getProposal() should return description, open status and voters sum"
      ).to.deep.equal([proposalDescription, true, amount]);
    });

    it("should revert if proposal doesn't exist", async () => {
      await expect(dao.getProposal(0)).to.be.revertedWith(
        "DAO: Proposal doesn't exist"
      );
    });
  });

  describe("withdraw", async function () {
    it("should withdraw tokens from contract to user", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      const ownerBalance = await token.balanceOf(owner.address);

      console.log(await token.balanceOf(owner.address));

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      let tokenOwnerBalanceBeforeWithdrawal = await token.balanceOf(
        owner.address
      );

      expect(tokenOwnerBalanceBeforeWithdrawal).to.be.equal(
        ownerBalance.sub(amount)
      );

      await dao.withdraw(amount);
      expect(await token.balanceOf(owner.address)).to.be.equal(ownerBalance);

      const daoBalance = await token.balanceOf(dao.address);
      expect(daoBalance).to.be.equal(ethers.utils.parseEther("0"));
    });

    it("delegated tokens should not be able to withdraw before end of vote", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await dao.delegate(proposalId, alice.address);

      await expect(dao.withdraw(amount)).to.be.revertedWith(
        "DAO: Can't withdraw before end of vote"
      );
    });
    it("delegated tokens should be able to withdraw after end of vote", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await dao.delegate(proposalId, alice.address);

      await ethers.provider.send("evm_increaseTime", [359200]);

      await expect(dao.withdraw(amount))
        .to.emit(dao, "Withdraw")
        .withArgs(owner.address, amount);
    });
  });

  describe("deposit", async function () {
    it("should deposit tokens to DAO contract", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      const ownerBalance = await token.balanceOf(owner.address);

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      expect(ownerBalance.sub(amount)).to.be.equal(
        await token.balanceOf(owner.address)
      );

      const daoBalance = await token.balanceOf(dao.address);
      expect(daoBalance).to.be.equal(amount);
    });

    it("get balance", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      const ownerBalance = await token.balanceOf(owner.address);

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      expect(ownerBalance.sub(amount)).to.be.equal(
        await token.balanceOf(owner.address)
      );

      await dao.getVoterDaoBalance();
    });
  });

  describe("delegate", async function () {
    it("can vote delegated votes", async () => {
      await dao.newProposal(
        proposalRecipient,
        proposalDescription,
        existedTokenFunction
      );

      const ownerBalance = await token.balanceOf(owner.address);

      await token.approve(dao.address, amount);

      await dao.deposit(amount);

      await dao.delegate(proposalId, bob.address);

      await dao.connect(bob).vote(proposalId);

      expect(await dao.getProposalBalance(proposalId)).to.be.equal(amount);

      const daoBalance = await token.balanceOf(dao.address);
      expect(daoBalance).to.be.equal(amount);
    });
  });
});
