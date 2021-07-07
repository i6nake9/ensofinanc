import { ethers } from "hardhat";
import { Signers } from "../../types";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { Contract } from "ethers";

describe('claimable', () => {
    let accounts: SignerWithAddress[],
        claimable: Contract


    beforeEach(async () => {
        accounts = await ethers.getSigners();
    });
});