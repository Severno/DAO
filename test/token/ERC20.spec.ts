import "@nomiclabs/hardhat-ethers";

import { BaseProvider } from "@ethersproject/providers/lib/base-provider";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import { expect } from "chai";
import hre from "hardhat";

const { ethers } = hre;

const name = "Corgy";
const symbol = "CRG";
const initialSupply = "1000";
const decimals = 18;
const bigNumberInitialSupply = ethers.utils.parseUnits(initialSupply, decimals);

let Token;
let token: Contract;
let provider: BaseProvider;
let owner: SignerWithAddress;
let addr1: SignerWithAddress;
let addr2: SignerWithAddress;
let addrs: SignerWithAddress[];

const before = async () => {
  provider = ethers.getDefaultProvider();

  [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

  Token = await ethers.getContractFactory("CRGToken");

  token = await Token.deploy(name, symbol, decimals);
};

describe("Token", function () {
  beforeEach(async function () {
    await before();
  });

  it("has a name", async () => {
    expect(await token.name()).to.equal(name);
  });

  it("has a symbol", async () => {
    expect(await token.symbol()).to.equal(symbol);
  });

  it("has 18 decimals", async () => {
    expect(await token.decimals()).to.equal(decimals);
  });

  describe("totalSupply", function () {
    it("returns the total amount of tokens", async () => {
      expect(await token.totalSupply()).to.equal(bigNumberInitialSupply);
    });
  });

  describe("balanceOf", function () {
    describe("when the requested account has no tokens", function () {
      it("returns zero", async function () {
        expect(await token.balanceOf(addr1.address)).to.be.equal("0");
      });
    });

    describe("when the requested account has some tokens", function () {
      it("returns the total amount of tokens", async function () {
        expect(await token.balanceOf(owner.address)).to.be.equal(
          bigNumberInitialSupply
        );
      });
    });
  });

  describe("Transfer", function () {
    it("should transfer between accounts", async function () {
      const transferAmount = ethers.utils.parseUnits("1", decimals);
      const ownerBalance = await token.balanceOf(owner.address);
      await token.transfer(addr1.address, transferAmount);

      expect(
        await token.balanceOf(owner.address),
        "balance is the same"
      ).to.be.equal(ownerBalance.sub(transferAmount));

      expect(
        await token.balanceOf(addr1.address),
        "balance is the same"
      ).to.be.equal(transferAmount);
    });

    it("should revert if there are insufficient funds", async function () {
      await expect(
        token.transfer(
          addr1.address,
          ethers.utils.parseUnits("1001.0", decimals)
        )
        // @ts-ignore
      ).to.be.revertedWith("ERC20: Transfer amount exceeds balance");
    });

    it("should emit Transfer", async () => {
      const from = owner.address;
      const to = addr1.address;
      const amount = ethers.utils.parseUnits("100", decimals);

      await expect(token.transfer(to, amount))
        // @ts-ignore
        .to.emit(token, "Transfer")
        .withArgs(from, to, amount);
    });
  });

  describe("Allowance", function () {
    it("'function approve' should emit Approval event", async () => {
      const amount = ethers.utils.parseUnits("10", decimals);

      await expect(token.connect(owner).approve(addr1.address, amount))
        // @ts-ignore
        .to.emit(token, "Approval")
        .withArgs(owner.address, addr1.address, amount);
    });

    it("should revert if there are insufficient allowance", async () => {
      const amount = ethers.utils.parseUnits("10", decimals);
      const smallAmount = ethers.utils.parseUnits("5", decimals);
      const ownerAddress = owner.address;
      const to = addr1.address;

      await token.approve(to, smallAmount);
      await token.transfer(to, amount);

      await expect(
        token.connect(addr1).transferFrom(ownerAddress, to, amount)
        // @ts-ignore
      ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });
  });
});
