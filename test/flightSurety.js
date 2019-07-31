var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var mCount = 1;
var aCount = 1;
var fCount = 1;
let airline2;
let airline3;
let airline4;
let airline5;
let airlineNeveRegistered;
let p1, p2, p3, p4, p5;

contract('Flight Surety Tests', async (accounts) => {

    // You should use .call() to execute constant/view/pure functions that don't modify state variables

    var config;
    before('setup contract', async () => {
        config = await Test.Config(accounts);
        console.log('flightSurety.js flightSuretyData', config.flightSuretyData.address);
        console.log('flightSurety.js flightSuretyApp', config.flightSuretyApp.address);

        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);

        // register first airline (owner)
        console.log('owner is Airline?', await config.flightSuretyData.isAirline.call(config.owner));

        airline2 = accounts[20];
        airline3 = accounts[21];
        airline4 = accounts[22];
        airline5 = accounts[23];
        airline5 = accounts[23];

        p1 = accounts[30];
        p2 = accounts[31];
        p3 = accounts[32];
        p4 = accounts[33];
        p5 = accounts[34];
        p5 = accounts[35];
        
        airlineNeveRegistered = config.neverAirline;
    });

    /****************************************************************************************/
    /* Operations and Settings                                                              */
    /****************************************************************************************/

    it(`(multiparty${mCount++}) has correct initial isOperational() value`, async function () {

        // Get operating status
        let status = false;
        try {
            status = await config.flightSuretyData.isOperational();
        } catch (e) {
            console.log('mult1', e);
        }
        assert.equal(status, true, "Incorrect initial operating status value");

    });

    it(`(multiparty${mCount++}) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

        // Ensure that access is denied for non-Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false, {from: accounts[accounts.length - 2]});
        } catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

    });

    it(`(multiparty${mCount++}) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

        // Ensure that access is allowed for Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false);
        } catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
    });

    it(`(multiparty${mCount++}) can block access to functions using requireIsOperational when operating status is false`, async function () {
        await config.flightSuretyData.setOperatingStatus(false);

        let reverted = false;
        try {
            let account = accounts[39];
            await config.flightSuretyApp.authorizeCaller(account);
        } catch (e) {
            reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");
        await config.flightSuretyData.setOperatingStatus(true);
    });

    it(`(airline${aCount++}) cannot register an Airline using registerAirline() if it is not funded`, async function () {
        // ARRANGE
        let result = true;

        // ACT
        try {
            await config.flightSuretyApp.registerAirline(config.neverAirline);
        } catch (e) {}

        try {
            result = await config.flightSuretyData.isAirline(config.neverAirline);
        } catch (e) {
           // console.log('(airline1) isAirline error', e);
        }

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");
    });

    it(`(airline${aCount++}) can be funded`, async function () {
        let airline = config.owner;
        
        await fundAirline(config,airline, 10, true);
        
        let result = await getFundStatus(config, airline);
        assert.equal(result, true, "Airline not funded");
    });

    it(`(airline${aCount++}) can register 2th, 3th and 4th Airlines`, async function () {
        // fund previous airlines
        await registerAirline(config, airline2, config.owner);
        await registerAirline(config, airline3, config.owner);
        await registerAirline(config, airline4, config.owner);

        assert.equal(await isAirline(config, airline2), true, 'Airline 2 not registered');
        assert.equal(await isAirline(config, airline3), true, 'Airline 3 not registered');
        assert.equal(await isAirline(config, airline4), true, 'Airline 4 not registered');
    });

    it(`(airline${aCount++}) can fund 2th, 3th and 4th Airlines`, async function () {
        // fund previous airlines
        await fundAirline(config, airline2, 10, false);
        await fundAirline(config, airline3, 10, false);
        await fundAirline(config, airline4, 10, false);

        assert.equal(await getFundStatus(config, airline2), true, 'Airline 2 not funded');
        assert.equal(await getFundStatus(config, airline3), true, 'Airline 3 not funded');
        assert.equal(await getFundStatus(config, airline4), true, 'Airline 4 not funded');
    });

/*
    it(`(airline${aCount++}) 5th do not have enough votes, so it can't be registered`, async function () {
        // unregister so we can reproduce all
        await unregisterAirline(config, airline5);
        
        // here 1-5 airlines (always 5 airline registered, maximum) is registred, so 3 votes is necessary to register 
        await registerAirline(config, airline5, config.owner);
        // await registerAirline(config, airline5, airline2);
        // await registerAirline(config, airline5, airline3);
        // await registerAirline(config, airline5, airline4);
        
        let result = false;
        try {
            result = await config.flightSuretyData.isAirline(airline5);
        } catch (e) {
            //console.log('(airline1) isAirline error', e);
        }
        assert.equal(result, false, "Airline 5 not registred by votting");
    });

    it(`(airline${aCount++}) 5th have enough votes, so it can be registered`, async function () {
        // unregister so we can reproduce all
        await unregisterAirline(config, airline5);
        
        await fundAirline(config, config.owner);

        await registerAirline(config, airline2, config.owner);
        await registerAirline(config, airline3, config.owner);
        await registerAirline(config, airline4, config.owner);
        await fundAirline(config, airline2);
        await fundAirline(config, airline3);
        await fundAirline(config, airline4);

        await registerAirline(config, airline5, config.owner);
        await registerAirline(config, airline5, airline2, true);
        await registerAirline(config, airline5, airline3, true);
        await registerAirline(config, airline5, airline4, true);
        
        assert.equal(await isAirline(config, airline5), false, 'Airline 5 not registered');
    });
*/

    it(`(flight${fCount++}) passenger can't pay more then 1 ether for a surety flight`, async function () {
        let flightID = "NotThatExpensive";
        let v = 1000000000;

        await buySurety(config, p1, flightID, v);

        let result = await config.flightSuretyApp.flightSuretyInfo.call(p1, flightID, {"from": p1});
        assert.equal(result, v, "Surety not purchased");
    });

    it(`(flight${fCount++}) passenger can't buy twice a surety for a flight`, async function () {
        let flightID = "NotThatExpensive";
        let v = 1000000000;

        let ok = false;
        try {
            await buySurety(config, p1, flightID, v);
        } catch(e) {
            ok = true;
        }

        assert.equal(ok, true, "Can't buy same surety more then once");

    });

});

async function buySurety(config, buyer, flightID, value) {
    await config.flightSuretyApp.buyFlightSurety(buyer, flightID, { from: buyer, value: value});
}

async function isAirline(config, airline) {
    return await config.flightSuretyData.isAirline.call(airline, 
        {from: config.flightSuretyApp.address});
}

async function registerAirline(config, airline, registerer, debug) {
    try {
        await config.flightSuretyApp.registerAirline(airline, {from: registerer});
    } catch (e) {
        if(debug)
            console.log('registerAirline error', e);
    }
}

async function unregisterAirline(config, airline) {
    try {
        await config.flightSuretyApp.unregisterAirline(airline);
    } catch (e) {
        console.log('unregisterAirline', e);
    }
}

async function fundAirline(config, airline, fundingValue, debug) {
    try {
        await config.flightSuretyApp.fundAirline({from: airline});
    } catch (e) {
        if (debug)
            console.log('airline fundAirline error', e);
    }
}

async function getFundStatus(config, airline) {
    return await config.flightSuretyData.isAirlineFunded.call(airline, 
        {from: config.flightSuretyApp.address});
}