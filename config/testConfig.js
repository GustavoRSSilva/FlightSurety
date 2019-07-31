
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0xffcf8fdee72ac11b5c542428b35eef5769c409f0",
        "0x22d491bde2303f2f43325b2108d26f1eaba1e32b",
        "0xe11ba2b4d45eaed5996cd0823791e0c93114882d",
        "0xd03ea8624c8c5987235048901fb614fdca89b117",
        "0x95ced938f7991cd0dfcb48f0a06a40fa1af46ebc",
        "0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9",
        "0x28a8746e75304c0780e011bed21c72cd78cd535e",
        "0xaca94ef8bd5ffee41947b4585a84bda5a3d3da6e",
        "0x1df62f291b2e969fb0849d99d9ce41e2f137006e"
    ];

    let owner = accounts[0];
    let firstAirline = accounts[1];
    // An account that never should be an Airline in all blockchain history
    // If that happen, restart de blockchain
    let neverAirline = accounts[accounts.length-3];
    let aNeverFunded = accounts[accounts.length-4];

    let flightSuretyData = await FlightSuretyData.deployed().then(instance => {return instance});
    let flightSuretyApp = await FlightSuretyApp.deployed().then(instance => {return instance});

    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        fundingValue: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp,
        neverAirline: neverAirline
    }
};

module.exports = {
    Config: Config
};