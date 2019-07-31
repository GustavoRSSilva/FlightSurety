pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => uint) authorizedContracts;                    // register authorizedContracts

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;
    uint256 public constant FLIGHT_MAX_PRICE = 1 ether;
    uint256 public balance = 0;

    struct Airline {
        bool isRegistered;
        bool isFunded;
    }
    mapping(address => Airline) airlines;
    mapping(address => uint256) airlineFunds;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
        bool isInsured;
    }
    mapping(string => Flight) private flights;
    mapping(bytes32 => uint256) flightKeySurety;
    address[] airlinesEnables = new address[](0);

    event FlightRegistered(string indexed account);

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
    (
    )
    public
    {
        contractOwner = msg.sender;
        airlines[msg.sender] = Airline({isRegistered : true, isFunded : false});
        airlinesEnables.push(msg.sender);
    }

    // modifiers
    modifier requireIsOperational() { require(operational, "Contract is currently not operational"); _;}
    modifier requireContractOwner() {require(msg.sender == contractOwner, "Caller is not contract owner"); _;}
    modifier isCallerAuthorized() { require(authorizedContracts[msg.sender] == 1, "Unauthorized access (Caller)"); _;}
    modifier requireFlightSuretyPrice() { require(msg.value <= FLIGHT_MAX_PRICE, "Max price is 1 ether"); _; }

    // Utils
    function isOperational() external view returns (bool) { return operational; }
    function setOperatingStatus (bool mode) external requireContractOwner { operational = mode; }
    function authorizeCaller(address dataContract) external requireIsOperational requireContractOwner {
        authorizedContracts[dataContract] = 1;
    }
    function unauthorizeCaller(address dataContract) external requireIsOperational requireContractOwner {
        authorizedContracts[dataContract] = 0;
    }

    // airline
    function unregisterAirline (address airline) external requireIsOperational isCallerAuthorized {
        airlines[airline] = Airline({isRegistered : false, isFunded : false});
    }

    function registerAirline (address airline) external requireIsOperational isCallerAuthorized {
        airlines[airline] = Airline({isRegistered : true, isFunded : false});
        airlinesEnables.push(airline);
    }

    function getActiveAirlines() requireIsOperational isCallerAuthorized returns(address[])
    {
        return airlinesEnables;
    }

    function isAirline (address airline) external view requireIsOperational returns (bool) {
        return airlines[airline].isRegistered;
    }

    function isAirlineRegistred(address airline) external view requireIsOperational returns (bool) {
        return airlines[airline].isRegistered;
    }

    function isAirlineFunded(address airline) external view requireIsOperational returns (bool) {
        return airlines[airline].isFunded;
    }

    function updateAirlineFundState(address airline, bool newState) external requireIsOperational isCallerAuthorized {
        airlines[airline].isFunded = newState;
    }

    function setAirlineUnfunded(address airline) external requireIsOperational isCallerAuthorized {
        airlines[airline].isFunded = false;
    }

    function fundAirline (address airline) public 
    payable requireIsOperational isCallerAuthorized {
        uint256 currentAmount = airlineFunds[airline];
        uint256 newTotal = currentAmount.add(msg.value);

        airlineFunds[airline] = 0;
        airline.transfer(newTotal);

        airlines[airline].isFunded = true;
    }

    // fligth
    function buy (address buyer, string flightID) external payable 
        requireIsOperational requireFlightSuretyPrice isCallerAuthorized {
        bytes32 key = keccak256(abi.encodePacked(buyer, flightID));
        require(!flights[flightID].isInsured, "Flight already isured");
        require(flightKeySurety[key] <= 0, "Surety already bought by passenger");
        flightKeySurety[key] = msg.value;
    }

    function flightSuretyInfo(bytes32 key) external view requireIsOperational isCallerAuthorized returns(uint256) {
        return flightKeySurety[key];
    }

    function creditInsurees (address passenger, string flight) external payable isCallerAuthorized requireIsOperational {
        bytes32 key = keccak256(abi.encodePacked(passenger, flight));
        uint256 currentFund = flightKeySurety[key];
        require(currentFund > 0, "There is no value to refund");
        
        uint256 amountToCredit = currentFund.mul(15).div(10);
        flightKeySurety[key] = amountToCredit;
    }

    function withdraw (string flight, uint256 amount) external isCallerAuthorized requireIsOperational {

        bytes32 key = keccak256(abi.encodePacked(msg.sender, flight));
        uint256 value = flightKeySurety[key];

        require(value >= amount, "No value to withdraw");

        flightKeySurety[key] = 0;
        msg.sender.transfer(amount);
        flightKeySurety[key] = value.sub(amount);
    }

    function registerFlight (address airline, string flightId, uint256 timestamp) external isCallerAuthorized requireIsOperational {

        require(airlines[airline].isRegistered, "Airline does not exists");
        flights[flightId] = Flight({
            isRegistered: true,
            statusCode: 0,
            updatedTimestamp: timestamp,
            airline: airline,
            isInsured: false
        });

        emit FlightRegistered(flightId);
    }

    function getFlightKey (address airline, string memory flight, uint256 timestamp) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }
    
    // fallback
        function()
    external
    payable
    requireIsOperational
    isCallerAuthorized
    {
        fundAirline(msg.sender);
    }
}