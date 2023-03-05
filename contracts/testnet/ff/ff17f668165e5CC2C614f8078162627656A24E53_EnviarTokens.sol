// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importar el segundo smart contract
import "./TransferirTokens.sol";

contract EnviarTokens {
    
    // Dirección del segundo smart contract
    address public transferirTokensContractAddress;
    
    // Constructor que recibe la dirección del segundo smart contract
    constructor(address _transferirTokensContractAddress) {
        transferirTokensContractAddress = _transferirTokensContractAddress;
    }
    
    // Función para llamar al segundo smart contract y transferir tokens
    function enviar(address _to, uint256 _amount) public {
        // Crear instancia del segundo smart contract
        TransferirTokens transferirTokens = TransferirTokens(transferirTokensContractAddress);
        
        // Llamar a la función del segundo smart contract para transferir los tokens
        transferirTokens.transferir(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importar el contrato del token ERC20
import "./ERC20.sol";

contract TransferirTokens {
    
    // Dirección del contrato del token ERC20
    address public tokenContractAddress;
    
    // Constructor que recibe la dirección del contrato del token ERC20
    constructor(address _tokenContractAddress) {
        tokenContractAddress = _tokenContractAddress;
    }
    
    // Función para transferir tokens a una dirección
    function transferir(address _to, uint256 _amount) public {
        // Crear instancia del contrato del token ERC20
        ERC20 token = ERC20(tokenContractAddress);
        
        // Transferir tokens desde el contrato actual a la dirección especificada
        token.transfer(_to, _amount);
    }
}