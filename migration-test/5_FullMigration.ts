import { ethers, network } from "hardhat";
import { expect } from "chai";
import { BigNumber, Event } from "ethers";
import { Signers } from "../types";
import { AcceptedProtocols, LiquidityMigrationBuilder } from "../src/liquiditymigration";
import { IERC20__factory } from "../typechain";
import Strategy from '@enso/contracts/artifacts/contracts/Strategy.sol/Strategy.json'
import { TokenSetEnvironmentBuilder } from "../src/tokenSets";
import { INITIAL_STATE } from "../src/constants";
import { EnsoBuilder, InitialState, StrategyItem, ITEM_CATEGORY, ESTIMATOR_CATEGORY } from "@enso/contracts";
import { WETH, SUSD } from "../src/constants";
import { setupStrategyItems, getBlockTime } from "../src/utils";
import deployments from "../deployments.json"

const ownerMultisig = '0xEE0e85c384F7370FF3eb551E92A71A4AFc1B259F'
const dpiPoolAddress = '0x1494ca1f11d487c2bbe4543e90080aeba4ba3c2b'
const indexCoopAdapterAddress = deployments.mainnet.IndexCoopAdapter
const adapters: string[] = [
    deployments.mainnet.TokenSetAdapter,
    deployments.mainnet.PieDaoAdapter,
    deployments.mainnet.IndexedAdapter,
    deployments.mainnet.IndexCoopAdapter,
    deployments.mainnet.DHedgeAdapter,
    deployments.mainnet.PowerPoolAdapter,
]

describe("MigrationCoordinator tests: ", function () {
  let signers: any,
    enso: any,
    indexCoopAdapter: any,
    dpiPool: any,
    dpiUnderlying: any,
    dpiStrategy: any,
    liquidityMigration: any,
    liquidityMigrationV2: any,
    migrationAdapter: any,
    migrationCoordinator: any,
    users: any;

  const dpi_setup = async function () {
    const TokenSetAdapter = await ethers.getContractFactory('TokenSetAdapter')
    indexCoopAdapter = TokenSetAdapter.attach(indexCoopAdapterAddress)
    dpiPool = IERC20__factory.connect(dpiPoolAddress, signers.default)
    dpiUnderlying = await indexCoopAdapter.outputTokens(dpiPoolAddress)
    dpiStrategy = new ethers.Contract(
      await deployStrategy(
        "DPI",
        "DPI",
        await setupStrategyItems(
          enso.platform.oracles.ensoOracle,
          enso.adapters.uniswap.contract.address,
          dpiPoolAddress,
          dpiUnderlying,
        ),
        INITIAL_STATE
      ),
      Strategy.abi,
      signers.default,
    );
    console.log("Strategy: ", dpiStrategy.address)
  };

  const deployStrategy = async (name: string, symbol: string, items: StrategyItem[], state: InitialState) => {
    const tx = await enso.platform.strategyFactory.createStrategy(
      signers.default.address,
      name,
      symbol,
      items,
      state,
      ethers.constants.AddressZero,
      "0x",
    );
    const receipt = await tx.wait();
    return receipt.events.find((ev: Event) => ev.event === "NewStrategy").args.strategy;
  };

  before(async function () {
    signers = {} as Signers;
    const allSigners = await ethers.getSigners();
    signers.default = allSigners[0];
    signers.secondary = allSigners[1];

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ownerMultisig],
    });
    signers.admin = await ethers.getSigner(ownerMultisig);

    const LiquidityMigration = await ethers.getContractFactory('LiquidityMigration')
    liquidityMigration = LiquidityMigration.attach('0x0092DECCA5E2f26466289011ad41465763BeA4cE')

    enso = await new EnsoBuilder(signers.admin).mainnet().build();
    // KNC not on Uniswap, use Chainlink
    await enso.platform.oracles.registries.chainlinkRegistry
      .connect(signers.admin)
      .addOracle(SUSD, WETH, "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", true); //sUSD
    await enso.platform.oracles.registries.chainlinkRegistry
      .connect(signers.admin)
      .addOracle(
        "0xdefa4e8a7bcba345f687a2f1456f5edd9ce97202",
        SUSD,
        "0xf8ff43e991a81e6ec886a3d281a2c6cc19ae70fc",
        false,
      ); //KNC
    await enso.platform.strategyFactory
      .connect(signers.admin)
      .addItemToRegistry(
        ITEM_CATEGORY.BASIC,
        ESTIMATOR_CATEGORY.CHAINLINK_ORACLE,
        "0xdefa4e8a7bcba345f687a2f1456f5edd9ce97202");

    await dpi_setup();

    console.log("Controller: ", enso.platform.controller.address)
    console.log("Router: ", enso.routers[0].contract.address)
    console.log("Oracle: ", enso.platform.oracles.ensoOracle.address)
  });

  it("Should deploy new liquidity migration contract", async function () {
    const LiquidityMigrationV2 = await ethers.getContractFactory('LiquidityMigrationV2')
    liquidityMigrationV2 = await LiquidityMigrationV2.connect(signers.admin).deploy(
      adapters,
      ethers.constants.MaxUint256,
      ethers.constants.MaxUint256
    )
    await liquidityMigrationV2.deployed()

    const MigrationAdapter = await ethers.getContractFactory('MigrationAdapter')
    migrationAdapter = await MigrationAdapter.connect(signers.admin).deploy(signers.admin.address)
    await migrationAdapter.deployed()

    const MigrationController = await ethers.getContractFactory('MigrationController')
    const migrationControllerImplementation = await MigrationController.connect(signers.admin).deploy(enso.platform.strategyFactory.address, liquidityMigrationV2.address, signers.admin.address)
    await migrationControllerImplementation.deployed()
    // Upgrade controller to new implementation
    await enso.platform.administration.controllerAdmin.connect(signers.admin).upgrade(
      enso.platform.controller.address,
      migrationControllerImplementation.address
    )
    // Update controller and generic router on LMV2
    await liquidityMigrationV2.connect(signers.admin).updateController(enso.platform.controller.address)
    await liquidityMigrationV2.connect(signers.admin).updateGenericRouter(enso.routers[0].contract.address)

    // Update generic router and leverage adapter on indexCoopAdapter
    await indexCoopAdapter.connect(signers.admin).updateGenericRouter(enso.routers[0].contract.address)
  })

  it("Should setup migration coordinator", async function () {
    // Deploy contract
    const MigrationCoordinator = await ethers.getContractFactory('MigrationCoordinator')
    migrationCoordinator = await MigrationCoordinator.connect(signers.admin).deploy(
      signers.admin.address,
      liquidityMigration.address,
      liquidityMigrationV2.address,
      migrationAdapter.address
    )
    await migrationCoordinator.deployed()
    // Update coordinator on LMV2
    await liquidityMigrationV2.connect(signers.admin).updateCoordinator(migrationCoordinator.address)
    // Transfer ownership of LiquidityMigrationV1
    await liquidityMigration.connect(signers.admin).transferOwnership(migrationCoordinator.address)
    // Initiate migration
    await migrationCoordinator.connect(signers.admin).initiateMigration(adapters)
  })

  it("Should migrate to new LiquidityMigration contract", async function () {
    const eventFilter = liquidityMigration.filters.Staked(null, null, null, null)
    const events = await liquidityMigration.queryFilter(eventFilter)
    console.log("Staked events: ", events.length)

    let stakedAdapters = events.map((ev: Event) => ev?.args?.adapter)
    stakedAdapters = stakedAdapters.filter((adapter: string, index: number) => stakedAdapters.indexOf(adapter) === index)

    let txCount = 0
    let gasUsed = ethers.BigNumber.from(0)
    for (let i = 0; i < stakedAdapters.length; i++) {
      console.log("Adapter: ", stakedAdapters[i])
      let stakedLPs = events.filter((ev: Event) => ev?.args?.adapter.toLowerCase() === stakedAdapters[i].toLowerCase())
                      .map((ev: Event) => ev?.args?.strategy)
      stakedLPs = stakedLPs.filter((lp: string, index: number) => stakedLPs.indexOf(lp) === index)
      console.log("Number of LPs: ", stakedLPs.length)

      for (let j = 0; j < stakedLPs.length; j++) {
          console.log("LP: ", stakedLPs[j])
          // Add all eligible LPs to this adapter's whitelist
          await migrationAdapter.connect(signers.admin).add(stakedLPs[j])

          let stakers = events.filter((ev: Event) => ev?.args?.strategy.toLowerCase() === stakedLPs[j].toLowerCase())
                                .filter((ev: Event) => ev?.args?.amount.gt(0))
                                .map((ev: Event) => ev?.args?.account)
          stakers = stakers.filter((account: string, index: number) => stakers.indexOf(account) === index)

          let remainder = stakers.length
          while (remainder > 0) {
            let users
            if (remainder > 150) {
              users = stakers.slice(0,150)

            } else {
              users = stakers
            }
            console.log("Users migrating: ", users.length)
            const tx = await migrationCoordinator
              .connect(signers.admin)
              .migrateLP(
                users,
                stakedLPs[j],
                stakedAdapters[i]
              )
            const receipt = await tx.wait()
            gasUsed = gasUsed.add(receipt.gasUsed)
            console.log('Migrate LP Gas Used: ', receipt.gasUsed.toString())
            txCount++
            stakers = stakers.slice(users.length, remainder)
            remainder = remainder - users.length
          }
      }
    }
    console.log("Total transactions: ", txCount)
    console.log("Total gas used: ", gasUsed.toString())
  });
});
