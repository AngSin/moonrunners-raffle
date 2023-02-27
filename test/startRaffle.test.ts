// import { deployMockContract } from "ethereum-waffle";
import { ethers } from "hardhat";
import { deployProxy } from "./utils";
import { Raffles } from "../typechain-types";
import { expect } from "chai";
import { BigNumber } from "ethers";

describe("startRaffle", () => {
  it("should start new raffle", async () => {
    const raffles = (await deployProxy("Raffles")) as Raffles;
    await raffles.startNewRaffle(1, 1);
    const blockNum = await ethers.provider.getBlockNumber();
    const timestamp = (await ethers.provider.getBlock(blockNum)).timestamp;
    expect((await raffles.raffles(0))[0]).to.eq(BigNumber.from("1")); // minimumTrophyId
    expect((await raffles.raffles(0))[1]).to.eq(BigNumber.from(timestamp)); // timestamp
    expect((await raffles.raffles(0))[2]).to.eq(BigNumber.from("1")); // duration
  });

  it("should not let non owner users start raffles", async () => {
    const raffles = (await deployProxy("Raffles")) as Raffles;
    const [_, otherAccount] = await ethers.getSigners();
    await expect(
      raffles.connect(otherAccount).startNewRaffle(1, 1)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
});
