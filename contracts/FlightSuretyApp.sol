pragma solidity ^0.4.24;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyApp {
    // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    using SafeMath for uint256;
    // Account used to deploy contract
    address private contractOwner;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // structs
    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Data Contract
    FlightSuretyData appData;
    uint256 airlineCount = 0;
    uint256 airlineVotingThreshold;
    uint256 AIRLINE_FUND = 10;
    mapping(address => address[]) airlineConsensus;

    // oracle
    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    constructor (address dataContractAddress) public  {
        contractOwner = msg.sender;
        appData = FlightSuretyData(dataContractAddress);
        airlineCount = 1; // Owner is an Airline
    }

    // TODO give back airline fund change

    // events
    event AirlineRegistered(address airline, uint256 airlineCount, uint votes);
    event AirlineUnregistered(address airline);
    event AirlineFunded(address airline);

    event AirlineUnregistered(address airline, bool fundState);
    event FlightSurety(address passenger, string flightID);
    event FlightInsured(address passenger, string flight);

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);
    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // modifiers
    modifier requireIsOperational() {
        require(appData.isOperational(), "Contract is currently not operational"); _;
    }

    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner"); _;
    }

    modifier requireNotContract() {
        require(msg.sender == tx.origin, "Contract now allowed");
        _;
    }

    modifier requireIsAirline(address airline) {
        require(appData.isAirline(airline), "Address is not an Airline");
        _;
    }

    modifier requireAirlineNotFunded(address airline) {
        require(!appData.isAirlineFunded(airline), "Airline already funded");
        _;
    }

    modifier requireAirlineFund() {
        require(msg.value >= AIRLINE_FUND, "Fund not enough");
        _;
    }

    modifier returnFundChange() {
        _;
        uint _price = AIRLINE_FUND;
        uint amountToReturn = msg.value - _price;
        msg.sender.transfer(amountToReturn);
    }

//region Utils
    function isOperational() public view returns(bool) { return appData.isOperational(); }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex (address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }
//endregion

//region Airline
    function getAirlineCount() external view returns (uint) { return airlineCount; }

    function unregisterAirline(address airline) external requireContractOwner {
        if(airlineConsensus[airline].length > 0) {
            delete airlineConsensus[airline];
        }
        appData.unregisterAirline(airline);
        emit AirlineUnregistered(airline);
    }

    function getVotesCount(address airline) external view returns (uint256) {
        return airlineConsensus[airline].length;
    }

    function registerAirline (address airline) external requireIsOperational requireIsAirline(msg.sender) {
        require(appData.isAirlineFunded(msg.sender), "Airline Caller not funded");

        if(airlineCount < airlineVotingThreshold) {
            appData.registerAirline(airline);
            airlineCount = airlineCount.add(1);

            emit AirlineRegistered(airline, airlineCount, 0);

            return;
        }

       // need consensus (half of registred airline  to approve)
       // count consensus
       bool isDuplicate = false;
       for(uint c=0; c<airlineConsensus[airline].length; c++) {
           if(airlineConsensus[airline][c] == msg.sender) {
               isDuplicate = true;
               break;
           }
       }
       require(!isDuplicate, "Registred Airline already voted for this new Consesus");

       airlineConsensus[airline].push(msg.sender);

       // check if can register airlinbe
       if(airlineConsensus[airline].length >= airlineCount.div(2)) {
           appData.registerAirline(airline);

           // register airline
           airlineCount = airlineCount.add(1);

           emit AirlineRegistered(airline, airlineCount, airlineConsensus[airline].length);
       }
    }

    function fundAirline() external payable requireIsAirline(msg.sender)
        requireAirlineNotFunded(msg.sender) /*returnFundChange TODO*/ {
        //require(msg.value >= AIRLINE_FUND, "Not enough to Fund yourself");

        appData.fundAirline(msg.sender);

        emit AirlineFunded(msg.sender);
    }

    function getActiveAirlines() external view returns(address[]) {
        return appData.getActiveAirlines();
    }
//endregion

//region Flight
    function registerFlight () external pure {}

    function processFlightStatus (address airline, string memory flight, uint256 timestamp, uint8 statusCode)
    internal pure {}

    function fetchFlightStatus(address airline, string flight, uint256 timestamp) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    function buyFlightSurety(address passenger, string flight) external payable requireIsOperational {
        appData.buy.value(msg.value)(passenger, flight);
        emit FlightSurety(passenger, flight);
    }

    function getFlightKey (address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function flightSuretyInfo(address passenger, string flighID) external view returns(uint256) {
        bytes32 key = keccak256(abi.encodePacked(passenger, flighID));

        return appData.flightSuretyInfo(key);
    }

    function creditInsurees(address passenger, string flight) external payable {
        appData.creditInsurees(passenger, flight);
        emit FlightInsured(passenger, flight);
    }

    function registerFlight(address airline, string flightId, uint256 timestamp) external {
        appData.registerFlight(airline, flightId, timestamp);
    }
//endregion

// region ORACLE

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse (uint8 index, address airline, string flight, uint256 timestamp, uint8 statusCode) external {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
            (oracles[msg.sender].indexes[1] == index) ||
            (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request");

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);

        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
          processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    // Register an oracle with the contract
    function registerOracle () external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes () view external returns(uint8[3] memory) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }
//endregion
}

contract FlightSuretyData {
    function isOperational() external view returns(bool); // ok
    //region Airline
    function isAirline(address airline) external view returns(bool); // ok
    function isAirlineRegistered(address airline) external view returns (bool);
    function registerAirline(address airline) external;
    function unregisterAirline(address airline) external;
    function isAirlineFunded(address airline) external view returns (bool);
    function updateAirlineFundState(address airline, bool newState) external;
    function fundAirline(address owner) public;
    function getActiveAirlines() returns(address[]);
    //endregion

    function buy (address buyer, string flightID) external payable;
    function flightSuretyInfo(bytes32 key) external view returns(uint256);
    function creditInsurees(address passenger, string flight) external payable;
    function registerFlight(address airline, string flightId, uint256 timestamp) external;
}
