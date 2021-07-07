import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

describe('claimable', () => {
    let accounts: SignerWithAddress[],
        claimable: Contract,
        liquidityMigration: Contract,
        token: Contract

    beforeEach(async () => {
        accounts = await ethers.getSigners();

        it('liquidityMigration deploy', async () => {
            let MockLiquidityMigration = await ethers.getContractFactory("MockLiquidityMigration");
            liquidityMigration = await MockLiquidityMigration.deploy();
        });
        it('ERC1155 deploy', async () => {
            let ERC1155 = await ethers.getContractFactory("Root1155");
            token = await ERC1155.deploy();
        });
        it('claimable deploy', async () => {
            let Claimable = await ethers.getContractFactory("Claimable");
            claimable = await Claimable.deploy();
        });
        console.log('Liquidity Migration', liquidityMigration);
    });
});