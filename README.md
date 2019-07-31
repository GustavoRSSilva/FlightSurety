# FlightSurety

<table>
<tr><td>Business Logic</td><td>Flight delay insurance for passengers</td></tr>
<tr><td>Multi-party</td><td>Managed as a collaboration between airlines</td></tr>
<tr><td>Payable</td><td>Passengers purchase insurance prior to flight</td></tr>
<tr><td>Payout</td><td>If the flight is delayed due to an airline fault they get 1.5X what they paid for insurance</td></tr>
<tr><td>Oracles</td><td>Provide flight status information from multiple APIs</td></tr>
</table>

### Project Requirements
<tr><td></td><td></td></tr>
<table>
  <tr><td>Separation of Concerns</td>
    <td>      
      <li>`FlightSuretyData` contract for persistence</li>
      <li>`FlightSuretyApp` for app logic and oracles</li>
      <li>Dapp client for triggering oracle calls</li>
      <li>Server app for simulating oracles</li>
    </td></tr>
  <tr><td>Airlines</td>
    <td>
      <li>Register first airline when contract is deployed</li>
      <li>Only existing airline may register a new airline up to four</li>
      <li>Registration of fifth and subsequent airlines require at least 50% consensus from registered airlines</li>
      <li>Airline can be registered, but does not participate until it submits 10 ether in funding</li>
    </td></tr>
  <tr><td>Passengers</td>
    <td>
      <li>Passengers may pay up to 1 Ether to purchase insurance</li>
      <li>Flight numbers and timestamps are fixed for the purpose of the project and can be defined in the Dapp client</li>
      <li>If the flight is delayed due to airline fault, passenger receives credit for 1.5X the amount they paid</li>
      <li>Funds are transfered from contract to the passenger wallet only when they initiate a withdraw</li>
    </td></tr>
  <tr><td>Oracles</td>
    <td>
      <li>Oracles are implemented as a server app in node.js</li>
      <li>Upon startup, 20+ oracles are registered and their assigned indexes are persisted in memory</li>
      <li>Client dapp is used to trigger request to update flight status generating `OracleRequest` event that is captured by server</li>
      <li>Server will loop through all registered oracles, identify the oracles for which the request applies, and respond by calling into app logic contract with the appropriate status code.</li>
    </td></tr>
  <tr><td>General</td>
    <td>
      <li>Contracts must have operational status control</li>
      <li>Functions must fail fast. use `require()` at the start of functions</li>
      <li>Scaffolding is require but feel free to replace it with your own</li>
      <li>Have Fun</li>
    </td></tr>
</table>  

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)
