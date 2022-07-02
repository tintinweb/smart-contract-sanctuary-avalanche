/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
//Creacion del token ERC-20 kamikaze en la blockchain de ethereum (luego lo pasamos a otra), este token tiene objetivos de especulacion.

pragma solidity ^0.8.14;






//El contrato siguiente no se registra en el codigo realmente, simplemente es una guia o una platilla para ERC20 tokens, 
//osea para que el codigo posterior que escribo mas abajo, sepa que hacer y por donde irse. Esta linea de codigo representa
//la IERC20, osea la interfaz del token estandar ERC20, Simplemente es una guia.


abstract contract IERC20 {

function name() public view virtual returns (string memory);
function symbol() public view virtual returns (string memory);
function decimals() public view virtual returns (uint8);
function totalSupply() public view virtual returns (uint256);
function balanceOf(address _owner) public view virtual returns (uint256 balance);
function transfer(address _to, uint256 _value) public virtual returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
function approve(address _spender, uint256 _value) public virtual returns (bool success);
function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);


event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}






//El codigo siguiente representa la que significa la propiedad del token.

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(){

        owner = msg.sender;

    }

    function transferOwnership(address _to) public {

        require(msg.sender == owner);
        newOwner = _to;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address (0);

    }

}






//El siguiente contrato representa el token en si mismo. Notese que coloque despues de "is" algunos contextos. Estos contextos
//representan las lineas de codigo que cree previamente. IERC20 representa la guia para que la EVM reconozca que este
//es un token ERC20 y siga los pasos correctos en el codigo posterior. El contexto Owned, representa la definicion de propiedad
//del token, con todas sus variables.


contract KamikazeToken is IERC20, Owned {
    
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public  _totalSupply;
    address public _minter;

    mapping(address => uint) balances;

    constructor(){

        _symbol = 'KAZE';
        _name = 'Kamikaze coin';
        _decimal = 18;
        _totalSupply = 1000000000000000000000000000000; //un trillon de tokens (decimal al punto 18)
        _minter = 0x707b69123f1cBe5A61ca83eaD946494711064D7d;


        balances[_minter] = _totalSupply;
        emit Transfer(address(0), _minter , _totalSupply);

    }


    function name() public view virtual override returns (string memory) {
       return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;  
    }

    function balanceOf(address _owner) public view virtual override returns (uint256 balance) {
        return balances[_owner];
    }


   function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool success){

        require(balances[_from] >= _value);
        balances[_from] -= _value;   //lo mismo que decir      balances[_from] -  _value
        balances[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    function transfer(address _to, uint256 _value) public virtual override returns (bool success) {
        return transferFrom(msg.sender, _to,_value); 
    }


    function approve(address _spender, uint256 _value) public view virtual override returns (bool success){
        return true;
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256 remaining){
        return 0;
    }

//En la siguiente variable realize unos cambios a lo estipulado en el tutorial que vi en youtube. Tal parece que el codigo ha 
//cambiado un poco con la actualizacion 0.8.14 (el video es 0.8.5). en fin, me salio un mensaje de error y con ayuda de la 
//plantilla de github, vi esta variable escrita de forma distinta en ERC20PresentMinterPauser. Asi que la cambie y el error salio.
//El error era que estaba como "public return (bool) {" y tenia que ser "public virtual {" 

//Ademas, tambien quite el "return true" al final de estas dos ultimas funciones. En los docs de zeppelin
// aparecen sin eso, asi que las borre.



    function mint(uint amount) public virtual {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalSupply += amount;
       
    }

//el mismo error que arriba.

    function confiscate(address target, uint amount) public virtual {
        require(msg.sender == _minter);
        if(balances[target] >= amount) {
            balances[target] -=amount;
            _totalSupply -= amount;
        }

        else {
            _totalSupply -= balances[target];
            balances[target] = 0;
        }

        
    }


    
    
}