import { ethers } from "hardhat";
import { Signers } from "../../types";

describe('claimable', () => {
    
    beforeEach(async () => {
        this.signers = {} as Signers;
        this.Token = await ethers.getContractFactory("Token");
    });
});