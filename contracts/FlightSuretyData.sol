pragma solidity >= 0.4.25;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {

    using SafeMath for uint256;

    struct Airline {
        bool isRegistered;
        bool hasFunded;
    }

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    uint airlineCount = 0;
    //Multi-party consensus values
    uint votesNeeded = 0;
    address[] approvalVotes;

    mapping(address => Airline) airlines;

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
        this.registerAirline(msg.sender);
        this.fund();
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            requireContractOwner
    {
        operational = mode;
    }

    /**
    * @dev Check if a airline is registered
    *
    * @return A bool that indicates if the user is registered
    */
    function isAirlineRegistered
                            (
                                address airlineAddress
                            )
                            private
                            view
                            returns(bool)
    {
        require(airlineAddress != address(0), "'airlineAddress' must be a valid address.");
        return airlines[airlineAddress].isRegistered;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    *   Enter a new airline up to four.  After four, 50% consesnus from airlines is required for entry
    *
    */
    function registerAirline
                            (
                                address airline
                            )
                            external
                            pure
                            requireContractOwner
    {
        require(!isAirlineRegistered(airline), "Airline is already registered");
        //only existing airlines may register a new airline until four are registered
        require(airlines[msg.sender].isRegistered, "Airlines must be registered prior to 4 registered airlines");

        //any airline can be added up until there are four, just so long as the caller is already registered
        if (airlineCount <= 4) {
    
            reallyRegisterAirline(airline);
        } else { //After four 50% consensys is required from registered airlines
            bool cannotVote = false;
    
            if(airlines[msg.sender].isRegistered != true) { //user has not funded the contract
                for(uint i = 0; i < approvalVotes.length; i++) {
                    //check for duplicate votes
                    if(approvalVotes[i] == msg.sender) {
                        cannotVote = true;
                        break;
                    }
                }
            }
            require(!cannotVote, "Caller is duplicate or has not funded");

            //until we reach the amount needed for consensys we just add the address to our list of approval voters
            //multiple address are required to call this contract
            if(approvalVotes.length < votesNeeded) {

                approvalVotes.push(msg.sender);

            } else { //we have enough votes let's add it to the airlines mapping
                reallyRegisterAirline(airline);

                //we need to recalculate and reset votes
                votesNeeded = SafeMath.div(airlineCount, 2);
                delete approvalVotes;
            }
        }
    }

    function reallyRegisterAirline(address airline) private {
        airlines[airline] = Airline({
                                    isRegistered: true,
                                    isFunded: false
                                });
        airlineCount ++;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (
                            )
                            public
                            payable
    {
        require(msg.value > 10 ether, "Caller has not sent enough funds to register");
        address(this).transfer(10 ether);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
    {
        fund();
    }


}

