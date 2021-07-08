import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
// @ts-ignore
import { expectEvent, expectRevert } from "@openzeppelin/test-helpers";
import { assert } from "console";
import { expect } from "chai";


describe('claimable', () => {
    let accounts: SignerWithAddress[],
        attacker: SignerWithAddress,
        claimable: Contract,
        liquidityMigration: Contract,
        erc1155: Contract,
        initialURI = 'https://token-cdn-domain/{id}.json'


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
        console.log(claimable.address)
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
        // describe('stateChange', async () => {
        //     let state = await claimable.State(); // 0 = pending, 1 = active, 2 = closed
        //     describe('non-functional', () => {
        //         it('not from owner', async () => {
        //             await claimable.connect(attacker).stateChange(state[1]);
        //         });
        //         it('current state exists', () => {
        //             describe('from owner', () => {
        //                 before(async () => {
        //                     await claimable.stateChange(state[1])
        //                 });
        //                 it('reverts', async () => {
        //                     // assert.
        //                 });
        //             })
        //         });
        //     });
        //     describe('functional', () => {
        //         describe('from owner', () => {
        //             before(async () => {
        //                 // await claimable.stateCha;
        //             });
        //             it('state updated', async () => {
                        
        //             });
        //         });
        //     });
        // });
    });
});