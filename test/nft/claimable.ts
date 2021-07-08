import { ethers } from "hardhat";
import { assert } from "console";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'


describe('claimable', () => {
    let accounts: SignerWithAddress[],
        attacker: SignerWithAddress,
        MockLiquidityMigration: ContractFactory,
        MockStrategy: ContractFactory,
        ERC1155: ContractFactory,
        claimable: Contract,
        liquidityMigration: Contract,
        erc1155: Contract,
        strategy: Contract,
        initialURI = 'https://token-cdn-domain/{id}.json',
        state = [0, 1, 2], // 0 = pending, 1 = active, 2 = closed
        name = 'degen',
        decimals = 18

    before(async () => {
        accounts = await ethers.getSigners();
        attacker = accounts[10];

        MockLiquidityMigration = await ethers.getContractFactory("MockLiquidityMigration");
        liquidityMigration = await MockLiquidityMigration.deploy();

        ERC1155 = await ethers.getContractFactory("Root1155");
        erc1155 = await ERC1155.deploy(initialURI);
        
        MockStrategy = await ethers.getContractFactory("MockStrategy");
        strategy = await MockStrategy.deploy(name, decimals)

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
    })
    describe('stateChange', () => {
        describe('non-functional', () => {
            it('revert when not owner', async () => {
                await expect(claimable.connect(attacker).stateChange(state[1]))
                .to.be.revertedWith('Ownable: caller is not the owner')
            });
            it('revert when current state', async () => {
                await expect(claimable.stateChange(await claimable.state()))
                .to.be.revertedWith('Claimable#changeState: current')
            });
        });
        describe('functional', () => {
            beforeEach(async () => {
                console.log(await claimable.state())
                await claimable.stateChange(state[1])
            });
            it('state updated', async () => {
                expect(await claimable.state()).to.equal(state[1])
            });
        });
    });
    describe('updateMigration', () => {
        let changeTo: Contract;
        before(async () => {
            changeTo = await MockLiquidityMigration.deploy();
            console.log(await claimable.state())

        });
        describe('non-functional', () => {
            it('revert when not owner', async () => {
                await expect(claimable.connect(attacker).updateMigration(changeTo.address))
                .to.be.revertedWith('Ownable: caller is not the owner')
            });
            it('revert when current', async () => {
                await expect(claimable.updateMigration(liquidityMigration.address))
                .to.be.revertedWith('Claimable#UpdateMigration: exists')
            });
        });
        describe('functional', () => {
            before(async () => {
                await claimable.updateMigration(changeTo.address)
            });
            it('migration updated', async () => {
                expect(await claimable.migration()).to.equal(changeTo.address)
            });
        });
    });
    describe('updateCollection', () => {
        let changeTo: Contract;
        before(async () => {
            changeTo = await ERC1155.deploy(initialURI);
        });
        describe('non-functional', () => {
            it('revert when not owner', async () => {
                await expect(claimable.connect(attacker).updateCollection(changeTo.address))
                .to.be.revertedWith('Ownable: caller is not the owner')
            });
            it('revert when current', async () => {
                await expect(claimable.updateCollection(erc1155.address))
                .to.be.revertedWith('Claimable#UpdateCollection: exists')
            });
        });
        describe('functional', () => {
            before(async () => {
                await claimable.updateCollection(changeTo.address)
            });
            it('collection updated', async () => {
                expect(await claimable.collection()).to.equal(changeTo.address)
            });
        });
    });
    describe('claim', () => {
        describe('non-functional', () => {
            it('revert when incorrect state', async () => {
                console.log(await claimable.state())
                await expect(claimable.claim(strategy.address))
                .to.be.revertedWith('Claimable#onlyState: ONLY_STATE_ALLOWED')
            });
            // describe('reverts when no stake', () => {
            //     before(async () => {
            //         await claimable.stateChange(state[1])
            //     });
            //     it('revert when no stake', async () => {
            //         await expect(claimable.claim(strategy.address))
            //         .to.be.revertedWith('Claimable#onlyState: ONLY_STATE_ALLOWED')
            //     });
            // });
        });
    });
});