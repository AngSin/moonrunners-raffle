import { deployContract, deployProxy } from "./utils";
import { Raffles, Runners, Trophies } from "../typechain-types";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { deployMockContract } from "@ethereum-waffle/mock-contract";
import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";

describe("enterRaffle", () => {
  it("should not let user enter raffle if non was started", async () => {
    const raffles = (await deployProxy("Raffles")) as Raffles;
    await expect(raffles.enterRaffle(0, 1)).to.be.revertedWithPanic();
  });

  it("should not let user enter raffle if the raffle ended", async () => {
    const [owner] = await ethers.getSigners();
    const raffles = (await deployProxy("Raffles")) as Raffles;
    const trophiesABI =
      require("../artifacts/contracts/Trophies.sol/Trophies.json").abi;
    const trophies = await deployMockContract(owner, trophiesABI);
    await raffles.setTrophiesContract(trophies.address);
    await raffles.startNewRaffle(1, 1);
    const moreThanRaffleDuration = 2;
    await time.increase(moreThanRaffleDuration);
    await expect(raffles.enterRaffle(0, 1)).to.be.revertedWith(
      "Raffle is not active!"
    );
  });

  it("should not let user enter raffle if the user does not have the minimum needed trophy for the raffle", async () => {
    const raffles = (await deployProxy("Raffles")) as Raffles;
    const trophies = (await deployProxy("Trophies")) as Trophies;
    await raffles.setTrophiesContract(trophies.address);
    await raffles.startNewRaffle(3, 3600);
    expect((await raffles.raffles(0))[0]).to.eq(BigNumber.from("3")); // minimumTrophyId
    await expect(raffles.enterRaffle(0, 4)).to.be.revertedWith(
      "You do not have the minimum trophy needed to participate in this raffle!"
    );
  });

  it("should not let user enter raffle if the user does not have minimum runners staked for the raffle", async () => {
    const [owner] = await ethers.getSigners();
    const raffles = (await deployProxy("Raffles")) as Raffles;
    const trophies = (await deployProxy("Trophies")) as Trophies;
    const runners = (await deployContract("Runners")) as Runners;
    await trophies.setRunnersContract(runners.address);
    await trophies.airdropTrophy(2, owner.address);
    await runners.setApprovalForAll(trophies.address, true);
    await trophies.connect(owner).stake([1, 2, 3, 4]);
    await raffles.setTrophiesContract(trophies.address);
    await raffles.startNewRaffle(2, 3600);
    await expect(raffles.enterRaffle(0, 2)).to.be.revertedWith(
      "You do not have enough staked to enter this raffle!"
    );
  });

  it("should let user enter raffle ", async () => {
    const [owner] = await ethers.getSigners();
    const raffles = (await deployProxy("Raffles")) as Raffles;
    const trophies = (await deployProxy("Trophies")) as Trophies;
    const runners = (await deployContract("Runners")) as Runners;
    await trophies.setRunnersContract(runners.address);
    await trophies.airdropTrophy(3, owner.address);
    await runners.setApprovalForAll(trophies.address, true);
    await trophies.connect(owner).stake([1, 2, 3, 4, 5]);
    await raffles.setTrophiesContract(trophies.address);
    await raffles.startNewRaffle(2, 3600);
    await raffles.enterRaffle(0, 3);
    expect((await raffles.getRaffle(0))[0]).to.eql([owner.address]);
    await expect(raffles.enterRaffle(0, 3)).to.be.revertedWith(
      "You have already entered this raffle!"
    );

    await raffles.setWinners(0, [owner.address]);
    expect((await raffles.getRaffle(0))[1]).to.eql([owner.address]);
  });
});
