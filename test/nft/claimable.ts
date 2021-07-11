import { ethers } from "hardhat";
import { assert } from "console";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'


describe('claimable', () => {
    let accounts: SignerWithAddress[],
        attacker: SignerWithAddress,
        user: SignerWithAddress,
        MockLiquidityMigration: ContractFactory,
        MockStrategy: ContractFactory,
        ERC1155: ContractFactory,
        Claimable: ContractFactory,
        claimable: Contract,
        liquidityMigration: Contract,
        erc1155: Contract,
        strategy: Contract,
        initialURI = 'https://token-cdn-domain/{id}.json',
        state = [0, 1, 2], // 0 = pending, 1 = active, 2 = closed
        name = 'degen',
        decimals = 18,
        supply = 100,
        emptyAddress = "0x0000000000000000000000000000000000000000",
        stake = (10 * decimals),
        protocols = [1, 2, 3, 4, 5, 6, 7] // 1 = dpi, 2 = TS, 3=enz, 4=ind, 5=pie, 6= bask, 7=master

    before(async () => {
        accounts = await ethers.getSigners();
        user = accounts[0];
        attacker = accounts[10];
    
        MockLiquidityMigration = await ethers.getContractFactory("MockLiquidityMigration");
        ERC1155 = await ethers.getContractFactory("Root1155");
        MockStrategy = await ethers.getContractFactory("MockStrategy");
        Claimable = await ethers.getContractFactory("Claimable");
    });

    const initialize = async (name:string, tests:any) => {
        describe(name, () => {
            before(async () => {
                liquidityMigration = await MockLiquidityMigration.deploy();
                erc1155 = await ERC1155.deploy(initialURI);
                strategy = await MockStrategy.deploy(name, decimals)
                claimable = await Claimable.deploy(
                    liquidityMigration.address,
                    erc1155.address
                );
                strategy.mint(user.address, stake)
            });
            tests();
        });
    }
    initialize('deployed', () => {
        describe('validate set constructor', () => {
            it('collection valid', async () => {
                expect(await claimable.collection()).to.equal(erc1155.address);
            });
            it('migration valid', async () => {
                expect(await claimable.migration()).to.equal(liquidityMigration.address);
            });
        });
    })
    initialize('stateChange', () => {
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
                await claimable.stateChange(state[1])
            });
            it('state updated', async () => {
                expect(await claimable.state()).to.equal(state[1])
            });
        });
    });
    initialize('updateMigration', () => {
        let changeTo: Contract;
        before(async () => {
            changeTo = await MockLiquidityMigration.deploy();
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
    initialize('updateCollection', () => {
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
        initialize('non-functional', () => {
            it('revert when incorrect state', async () => {
                await expect(claimable.claim(strategy.address))
                .to.be.revertedWith('Claimable#onlyState: ONLY_STATE_ALLOWED')
            });
            describe('active state', () => {
                before(async () => {
                    await claimable.stateChange(state[1])
                });
                it('revert when empty address', async () => {
                    await expect(claimable.claim(emptyAddress))
                    .to.be.revertedWith('Claimable#claim: empty address')
                });
                it('revert when no stake', async () => {
                    await expect(claimable.claim(strategy.address))
                    .to.be.revertedWith('Claimable#claim: Has not staked')
                });
                // describe('has staked', () => {
                //     before(async () => {
                //         await strategy.approve(liquidityMigration.address, stake)
                //         await liquidityMigration.stake(strategy.address, (stake/(protocols.length-1)), protocols[0])
                //     });
                //     it('', () => {
                        
                //     });
                // });
            });
        });
        initialize('functional', () => {
            describe('approve migration', () => {
                before(async() => {
                    await strategy.approve(liquidityMigration.address, stake)
                });
                it('approval set', async () => {
                    expect(await strategy.allowance(user.address, liquidityMigration.address))
                    .to.equal(stake)
                });
                describe('stake', () => {
                    let staked: any[];
                    let protocol = protocols[0];
                    let amount = stake/(protocols.length-1);
                    before(async () => {
                        await liquidityMigration.stake(strategy.address, amount, protocol)
                        staked = await liquidityMigration.hasStaked(user.address, strategy.address)
                    });
                    it('staked bool', async () => {
                        expect(staked[0]).to.equal(true)
                    });
                    it('amount valid', async () => {
                        expect(staked[1]).to.equal(protocol)
                    });
                    describe('collection initialized', async () => {
                        before(async () => {
                            await erc1155.create(
                                claimable.address,
                                supply,
                                initialURI,
                                "0x"
                            )
                        });
                        it('claimable balance', async () => {
                            expect(await erc1155.balanceOf(claimable.address, protocol))
                            .to.equal(supply)
                        });
                        describe('update state', () => {
                            before(async () => {
                                await claimable.stateChange(state[1])
                            });
                            describe('claim', () => {
                                before(async () => {
                                    await claimable.claim(strategy.address)
                                });
                                it('user balance', async () => {
                                    expect(await erc1155.balanceOf(user.address, protocol))
                                    .to.equal(1)
                                });
                                it('claimable blanace', async () => {
                                    expect(await erc1155.balanceOf(claimable.address, protocol))
                                    .to.equal(supply-1)
                                });
                                it('claimed updated', async () => {
                                    expect(await claimable.claimed(user.address, protocol))
                                    .to.equal(true)
                                });
                            });
                        })
                    })
                });
            });
        });
    })
});