var BoredPetsNFT = artifacts.require("BoredPetsNFT");
var Marketplace= artifacts.require("Marketplace");

async function logNFTLists(marketplace){
    let listedNFTs= await marketplace.getListedNFTs.call()
    const accountAddress= '0x7a56cF48f1C181DF53A34Ef4b24C2d2c93f2f7aE' //deployer address
    let myNFTs= await marketplace.getMyListedNFTs.call({from: accountAddress})
    let myListedNFTs = await marketplace.getMyListedNFTs.call({from: accountAddress})
    console.log(`listedNFTs: ${listedNFTs.length}`)
    console.log(`myNFTs: ${myNFTs.length}`)
    console.log(`myListedNFTs: ${myListedNFTs.length}\n`)
}

const main = async(cb) => {
    try {
        const boredPets = await BoredPetsNFT.deployed()
        const marketplace= await Marketplace.deployed()

        console.log('Mint and List 3 NFTs')
        let listingFee= await marketplace.getListingFee()
        listingFee= listingFee.toString()
        let txn1= await boredPets.mint("URI1")
        let tokenId1 = txn1.logs[2].args[0].toNumber()
        await marketplace.listNFT(boredPets.address, tokenId1, 1, {value: listingFee})
        console.log(`Minted and listed ${tokenId1}`)
        let txn2 = await boredPets.mint("URI1")
        let tokenId2 = txn2.logs[2].args[0].toNumber()
        await marketplace.listNFT(boredPets.address, tokenId2, 1, {value: listingFee})
        console.log(`Minted and listed ${tokenId2}`)
        let txn3 = await boredPets.mint("URI1")
        let tokenId3 = txn3.logs[2].args[0].toNumber()
        await marketplace.listNFT(boredPets.address, tokenId3, 1, {value: listingFee})
        console.log(`Minted and listed ${tokenId3}`)
        await logNFTLists(marketplace)

        console.log('BUY 2 NFTs')
        await marketplace.buyNFT(boredPets.address, tokenId1, {value: 1})
        await marketplace.buyNFT(boredPets.address, tokenId2, {value: 1})
        await logNFTLists(marketplace)

        console.log('RESELL 1 NFT')
        await marketplace.relistNFT(boredPets.address, tokenId2, 1, {value: listingFee})
        await logNFTLists(marketplace)
    } catch(err){
        console.log("Doh!",err)
    }
    cb();
}

module.exports = main;