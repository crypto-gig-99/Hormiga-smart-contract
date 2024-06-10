const { expect } = require("chai");
const { ethers } = require("hardhat");
const BigNumber  =  require("bignumber.js");

let Token;
let NativeToken;
let nftToken;
let nativeToken;
let owner;
let addr1;
let addr2;
let addrs;

// `beforeEach` will run before each test, re-deploying the contract every
// time. It receives a callback, which can be async.
beforeEach(async function () {
  // Get the ContractFactory and Signers here.
  Token = await ethers.getContractFactory("BreedNFT");
  NativeToken = await ethers.getContractFactory("NativeToken");
  [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

  // To deploy our contract, we just have to call Token.deploy() and await
  // for it to be deployed(), which happens once its transaction has been
  // mined.
  nativeToken = await NativeToken.deploy();
  nftToken = await Token.deploy(nativeToken.address);
});

describe("BreedingNFT ", function () {
  it("Should transfer tokens between accounts", async function () {
    
    await nativeToken.transfer(addr1.address, 50);
    const addr1Balance = await nativeToken.balanceOf(addr1.address);
    expect(addr1Balance).to.equal(50);

  });

  it("mint and breed the token", async function () {    

    await nativeToken.transfer(addr1.address, 50);
    const addr1Balance = await nativeToken.balanceOf(addr1.address);
    expect(addr1Balance).to.equal(50);    
    
    await nftToken.setWhitelist(owner.address, true);      
    let price = 2;
    await nativeToken.approve(nftToken.address, "20000000000000000000000000");      
    for (let index = 0; index < 6; index++) {
      await nftToken.buy(owner.address);      
    }

    await nftToken.breed(owner.address, [1, 2, 3, 4, 5, 6]);

    const nftBalance = await nftToken.balanceOf(owner.address);    

    console.log(nftBalance);
    
  });


});
