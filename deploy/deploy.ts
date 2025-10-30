import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;
  const provider = hre.ethers.provider;

  // Получаем актуальный nonce
  const nonce = await provider.getTransactionCount(deployer);

  const deployedRating = await deploy("FHECoinFlip", {
    from: deployer,
    log: true,
    gasLimit: 5_000_000,
    nonce, // устанавливаем текущий nonce
  });

  console.log("✅ FHECoinFlip deployed at:", deployedRating.address);
};

export default func;
func.id = "deploy_FHEFitnessTracker";
func.tags = ["FHECoinFlip"];
