// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Coffee
 * @dev Contrato inteligente para recibir donaciones de café, equivalentes a 1 dolar aproximadamente.
 */

contract Coffee {
    //dueño del contrato
    address payable owner;

    /**
     * @dev Crea un nuevo contrato y establece al creador como el propietario.
     */
    constructor() {
        owner = payable(address(uint160(msg.sender)));
    }

    /**
     * @dev Registro de eventos de una nueva donación.
     */
    event NewCoffee(
        uint256 indexed timestamp,
        string donatorName,
        string message,
        uint8 rating
    );

    /**
     * @dev ratingIndex posición del indice de cofeeLog, coffeeQTY: cantidad de cafés donados (contador)
     */

    uint8 ratingIndex = 0;
    uint256 coffeeQTY = 0;

    /**
     * @dev Estructura para almacenar información de las donaciones.
     */
    struct Coffee {
        uint256 timestamp;
        string name;
        string message;
        uint8 rating;
    }

    /**
     * @dev Array para almacenar los últimos 5 registros de donaciones.
     */

    Coffee[5] coffeeLog;

    /**
     * @dev Devuelve los últimos 5 registros de donaciones.
     * @return Los registros de donaciones.
     */
    function getCoffeeLog() public view returns (Coffee[5] memory) {
        return coffeeLog;
    }

    /**
     * @dev Devuelve la cantidad total de donaciones recibidas.
     * @return La cantidad total de donaciones.
     */
    function getCoffeeQTY() public view returns (uint256) {
        return coffeeQTY;
    }

    /**
     * @dev Función para realizar una donación de café.
     * @param _name Nombre del donador.
     * @param _message Mensaje de agradecimiento del donador.
     * @param _rating Calificación de la calidad del café (1-5).
     * @param _amount Cantidad donada
     */
    function donateCoffee(
        string memory _name,
        string memory _message,
        uint8 _rating,
        uint256 _amount
    ) public payable {
        require(
            msg.value >= _amount,
            "Please send the quantity of a cofffee or a little more :) "
        );
        if (ratingIndex > 4) {
            ratingIndex = 0;
        }
        coffeeLog[ratingIndex] = Coffee(
            block.timestamp,
            _name,
            _message,
            _rating
        );
        (bool success, ) = owner.call{value: msg.value}("");
        require(success == true, "Donation unsucessfull :( )");
        coffeeQTY = coffeeQTY + 1;
        emit NewCoffee(block.timestamp, _name, _message, _rating);
        ratingIndex = ratingIndex + 1;
    }
}