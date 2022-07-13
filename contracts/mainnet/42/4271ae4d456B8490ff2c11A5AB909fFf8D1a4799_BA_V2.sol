/**
 *Submitted for verification at snowtrace.io on 2022-07-12
*/

// SPDX-License-Identifier: MIT

//prueba2_BA

pragma solidity ^0.8.0;


//interfaces

interface IERC20 {

function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function allowance(address owner, address spender) external view returns (uint256);
function transfer(address to, uint256 amount) external returns (bool);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address from,address to,uint256 amount) external returns (bool);

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

}


interface IUniswapV2Router {

 function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
 function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

}



interface IUniswapV2Pair {

  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;

}



//------------------------------------------------------------------------------------------------------------------------




contract BA_V2 {

//State variables (creo que esta ya no es necesaria con "Ownable")

address _propietario_del_contrato = 0x9ee777789D4294EDebC907BE580B8b7Bf675A66B;



//funcion para cambiar de propietario (creo que esto ya no es necesario con "Ownable")

function CambiarPropietario(address _nuevo_propietario) public returns(address){
    require(msg.sender == _propietario_del_contrato, "you are not the owner, fuck you");
    _propietario_del_contrato = address(_nuevo_propietario);
    return _propietario_del_contrato;
}


//funciones para swapear (swap DUO)

       //Esta funcion es simplemente la interfaz de swapeo estandar de uniswap (EVM)
function SwapInterfaz(address _router, address _tokenIn, address _tokenOut, uint _amount) private {
    IERC20(_tokenIn).approve(_router, _amount);
	address[] memory path;
	path = new address[](2);
	path[0] = _tokenIn;
	path[1] = _tokenOut;
	uint deadline = block.timestamp + 300;
	IUniswapV2Router(_router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
}

       //Esta funcion es para ahora si efectuar el swapeo en si, con la ayuda de la funcion anterior y de las interfazes. Notese que esta no es la forma mas eficiente en temas de gas, pero es la que se usara ahora.
function SwapDual(address _router1, address _router2, address _token1, address _token2, uint _amount) external {
    require(msg.sender == _propietario_del_contrato, "you are not the owner, fuck you");
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    SwapInterfaz(_router1,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    SwapInterfaz(_router2,_token2, _token1,tradeableAmount);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made x");
    }



//funciones de calldata()

        //Esta funcion solamente es una conexion de la segunda y tercera funcion, sirve para saber las cantidades
function getAmountOutMin(address _router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router(_router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}

        //Esta funcion sirve para efectivamente saber las cantidades finales, y se apalanca en la data ya proporcionada por la funcion anterior y las interfazes
function DataDualSwap(address _router1, address _router2, address _token1, address _token2, uint _amount) external view returns(uint){
        require(msg.sender == _propietario_del_contrato, "you are not the owner, fuck you");
        uint256 amount_primer_dex = getAmountOutMin(_router1, _token1, _token2, _amount);
	    uint256 amount_segundo_dex = getAmountOutMin(_router2, _token2, _token1, amount_primer_dex);
	    return amount_segundo_dex;
    }

        //Esta funcion es lo mismo que la anterior, sino que ahora con 3 dexes, para el cambio triple
function DataTriSwap(address _router1, address _router2, address _router3, address _token1, address _token2, address _token3, uint256 _amount) external view returns (uint256) {
		require(msg.sender == _propietario_del_contrato, "you are not the owner, fuck you");
        uint amount_primer_dex = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint amount_segundo_dex = getAmountOutMin(_router2, _token2, _token3, amount_primer_dex);
		uint amount_tercer_dex = getAmountOutMin(_router3, _token3, _token1, amount_segundo_dex);
		return amount_tercer_dex;
	}



//funciones de recuperacion y vision de tokens (opcional)

          //Esta funcion sirve simplemente para saber cuanto balance de un token especifico tenemos en la wallet que nosotros determinemos
function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		require(msg.sender == _propietario_del_contrato, "you are not the owner, fuck you");
        uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}
	      //No estoy muy seguro, pero creo que esta funcion sirve para algun tipo de recuperacion de las gas fees.
function recoverEth() external {
		require(msg.sender == _propietario_del_contrato, "you are not the owner, fuck you");
        payable(msg.sender).transfer(address(this).balance);
	}
          //Esta funcion sirve para recuperar los tokens desde la wallet que esta interactuando con el contrato a otra wallet externa.
function recoverTokens(address tokenAddress) external {
		require(msg.sender == _propietario_del_contrato, "you are not the owner, fuck you");
        IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}



}