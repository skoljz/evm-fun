import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";

const ONE_ETH = ethers.parseEther("1");
const HALF_ETH = ethers.parseEther("0.5");

async function deployFixture() {
  const [owner, user, user2] = await ethers.getSigners();

  const MockRouter = await ethers.getContractFactory("MockUniswapRouter");
  const mockRouter = await MockRouter.deploy();
  await mockRouter.waitForDeployment();

  const EvmFun = await ethers.getContractFactory("EvmFun");
  const evmFun = await EvmFun.deploy(await mockRouter.getAddress());
  await evmFun.waitForDeployment();

  return { evmFun, mockRouter, owner, user, user2 };
}

/**
 * @return created tokena address from createToken()
 */
async function createSale(
  evmFun: any,
  name = "PumpCoin",
  symbol = "PUMP",
  cap = ONE_ETH,
  supply = ONE_ETH
) {
  const tx = await evmFun.createToken(name, symbol, cap, supply);
  const rc = await tx.wait();
  const event = rc!.logs.find((l: any) => l.fragment?.name === "TokenCreated");
  return event.args.token as string;
}

describe("EvmFun", () => {
  describe("Deployment", () => {
    it("deploys successfully", async () => {
      const { evmFun } = await loadFixture(deployFixture);
      expect(await evmFun.getAddress()).to.be.properAddress;
    });
  });

  describe("Public sale", () => {
    it("allows users to buy the token and updates balances", async () => {
      const { evmFun, user } = await loadFixture(deployFixture);
      const token = await createSale(evmFun);

      await expect(
        evmFun.connect(user).buy(token, { value: HALF_ETH })
      ).to.changeEtherBalances(
        [user, evmFun],
        [HALF_ETH * BigInt(-1), HALF_ETH]
      );
    });

    it("calculates refund pool correctly when cap is reached", async () => {
      const { evmFun, user, user2 } = await loadFixture(deployFixture);
      const token = await createSale(evmFun);

      await evmFun.connect(user).buy(token, { value: HALF_ETH });
      await evmFun.connect(user2).buy(token, { value: HALF_ETH });

      const sale = await evmFun.sales(token);
      expect(sale.listed).to.be.true;
      expect(sale.refundPool).to.equal((ONE_ETH * 50n) / 100n);
    });

    it("allows user claim refund only once", async () => {
      const { evmFun, user } = await loadFixture(deployFixture);
      const token = await createSale(evmFun);

      await evmFun.connect(user).buy(token, { value: ONE_ETH });
      await evmFun.connect(user).claimRefund(token);

      await expect(
        evmFun.connect(user).claimRefund(token)
      ).to.be.revertedWith("Already refunded");
    });

    it("allows owner to withdraw unclaimed refund after deadline", async () => {
      const { evmFun, owner, user } = await loadFixture(deployFixture);
      const token = await createSale(evmFun);

      await evmFun.connect(user).buy(token, { value: ONE_ETH });
      const saleBefore = await evmFun.sales(token);

      // 7 days + 1 second
      await time.increase(7 * 24 * 60 * 60 + 1);

      await expect(
        evmFun.connect(owner).withdrawUnclaimedRefund(token)
      ).to.changeEtherBalance(owner, saleBefore.refundPool);
    });

    it("reverts buys after the token is listed", async () => {
      const { evmFun, user, user2 } = await loadFixture(deployFixture);
      const token = await createSale(evmFun);

      await evmFun.connect(user).buy(token, { value: ONE_ETH });

      await expect(
        evmFun.connect(user2).buy(token, { value: ethers.parseEther("0.1") })
      ).to.be.revertedWith("Already listed");
    });
  });
});
