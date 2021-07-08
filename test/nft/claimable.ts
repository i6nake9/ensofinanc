import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { assert } from "console";
import { expect } from "chai";


describe('claimable', () => {
    let accounts: SignerWithAddress[],
        attacker: SignerWithAddress,
        claimable: Contract,
        liquidityMigration: Contract,
        erc1155: Contract,
        initialURI = 'https://token-cdn-domain/{id}.json',
        state = [0, 1, 2] // 0 = pending, 1 = active, 2 = closed

    before(async () => {
        accounts = await ethers.getSigners();
        attacker = accounts[10];

        let MockLiquidityMigration = await ethers.getContractFactory("MockLiquidityMigration");
        liquidityMigration = await MockLiquidityMigration.deploy();

        let ERC1155 = await ethers.getContractFactory("Root1155");
        erc1155 = await ERC1155.deploy(initialURI);
        
        let Claimable = await ethers.getContractFactory("Claimable");
        claimable = await Claimable.deploy(
            liquidityMigration.address,
            erc1155.address
        );
    });
    describe('deployed', () => {
        describe('validate set constructor', () => {
            it('collection valid', async () => {
                expect(await claimable.collection()).to.equal(erc1155.address);
            });
            it('migration valid', async () => {
                expect(await claimable.migration()).to.equal(liquidityMigration.address);
            });
        });
        describe('stateChange', () => {
            describe('non-functional', () => {
                it('not from owner', async () => {
                    await expect(claimable.connect(attacker).stateChange(state[1]))
                    .to.be.revertedWith('Ownable: caller is not the owner')
                });
            });
        });
    });
});