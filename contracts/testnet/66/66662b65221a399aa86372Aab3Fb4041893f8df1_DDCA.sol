/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-27
*/

pragma solidity ^0.8.7;

contract DDCA {

    event Invested(address indexed traderaddress, uint amount, uint left);

    struct Rule {
        address[] protocols;
        uint left;
        uint[] invested;
    }

    mapping(address => Rule) internal trusteesData;
    address[] registeredAccounts;

    function addRule(address[] memory protocols) public payable {
        trusteesData[msg.sender] = Rule(protocols, msg.value, new uint[](0));
        trusteesData[msg.sender].invested.push(0);
        trusteesData[msg.sender].invested.push(0);
        trusteesData[msg.sender].invested.push(0);
        registeredAccounts.push(msg.sender);
    }

    function getRule(address adrs) public view returns(Rule memory rule) {
        return trusteesData[adrs];
    }

    function dca() public {
        uint amount = 10000000 gwei;
        for (uint8 index = 0; index < registeredAccounts.length; index++) {
            address adrs = registeredAccounts[index];
            address[] memory protocols = trusteesData[adrs].protocols;
            uint[] memory invested = trusteesData[adrs].invested;

            for (uint8 j = 0; j < 3; j++){
                require(trusteesData[adrs].left > amount);
                invested[j] += amount;
                trusteesData[adrs].left -= amount;
                payable(protocols[j]).transfer(amount);
                emit Invested(adrs, amount, trusteesData[adrs].left);
            }
            trusteesData[adrs].invested = invested;
        }
    }
}