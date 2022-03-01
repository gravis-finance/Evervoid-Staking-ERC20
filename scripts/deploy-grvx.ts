import hre, { ethers, network } from "hardhat";

function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
    const GravisStakingFactory = await ethers.getContractFactory(
        "GravisStaking"
    );

    const constructorArgs: [string, string, string, string, string] = [
        process.env.GRVX_ADDRESS!,
        process.env.FUEL_ADDRESS!,
        process.env.REWARD_START!,
        process.env.FUEL_PER_GRVX_PER_YEAR!,
        process.env.LOCK_PERIOD!,
    ];

    const staking = await GravisStakingFactory.deploy(...constructorArgs);
    await staking.deployed();

    console.log("GravisStaking deployed to:", staking.address);

    if (network.name !== "localhost" && network.name !== "hardhat") {
        console.log("Sleeping before verification...");
        await sleep(20000);

        await hre.run("verify:verify", {
            address: staking.address,
            constructorArguments: constructorArgs,
        });
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
