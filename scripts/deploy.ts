import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("deploying contracts with the account:", deployer.address);

  const UNISWAP_ROUTER = process.env.UNISWAP_ROUTER
  const EvmFum = await ethers.getContractFactory("EvmFun");
  const evmFun = await EvmFum.deploy(UNISWAP_ROUTER as string);
  await evmFun.waitForDeployment();
  console.log("evm-fun deployed to:", await evmFun.getAddress());

  const tokenAddress = await evmFun.createToken("PumpCoin", "PUMP", ethers.parseEther("10"), ethers.parseEther("10"));
  console.log("PumpToken created at:", tokenAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 