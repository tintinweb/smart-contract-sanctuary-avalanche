// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoCats {
    struct Cat {
        uint256 id;
        address owner;
        string color;
        string rarity;
        uint256 weight;
    }
    
    Cat[] public cats;
    mapping(address => uint256[]) public ownerCats;
    mapping(uint256 => uint256) public catIndex;
    uint256 public nextId = 1;
    address public owner;
    uint256 public contractBalance;
    
    constructor() {
        owner = msg.sender;
    }
    
    function buyCat(string memory _color, string memory _rarity) public payable {
        require(msg.value >= 1 ether, "Insufficient ether sent");
        Cat memory newCat = Cat({
            id: nextId,
            owner: msg.sender,
            color: _color,
            rarity: _rarity,
            weight: 0
        });
        cats.push(newCat);
        ownerCats[msg.sender].push(nextId);
        catIndex[nextId] = cats.length - 1;
        nextId++;
        contractBalance += msg.value;
    }
    
    function buyColor(uint256 _catId, string memory _color) public payable {
        require(msg.sender == cats[catIndex[_catId]].owner, "Only the cat owner can modify color");
        require(msg.value >= 1 ether, "Insufficient ether sent");
        cats[catIndex[_catId]].color = _color;
        contractBalance += msg.value;
    }
    
    function buyRarity(uint256 _catId, string memory _rarity) public payable {
        require(msg.sender == cats[catIndex[_catId]].owner, "Only the cat owner can modify rarity");
        require(msg.value >= 1 ether, "Insufficient ether sent");
        cats[catIndex[_catId]].rarity = _rarity;
        contractBalance += msg.value;
    }
    
    function buyFood(uint256 _catId, uint256 _amount) public payable {
        require(msg.value >= _amount * 1 ether, "Insufficient ether sent");
        cats[catIndex[_catId]].weight += _amount;
        contractBalance += msg.value;
    }
    
    function getCatList() public view returns (Cat[] memory) {
        Cat[] memory result = new Cat[](cats.length);
        for (uint256 i = 0; i < cats.length; i++) {
            result[i] = cats[i];
        }
        sortCats(result);
        return result;
    }
    
    function sortCats(Cat[] memory _cats) internal pure {
        uint256 n = _cats.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (_cats[j].weight < _cats[j+1].weight) {
                    Cat memory temp = _cats[j];
                    _cats[j] = _cats[j+1];
                    _cats[j+1] = temp;
                }
            }
        }
    }
    
    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "Only the contract owner can withdraw");
        require(_amount <= contractBalance, "Insufficient balance");
        payable(owner).transfer(_amount);
        contractBalance -= _amount;
    }
    
    function distribute(uint256 _amount) public {
        require(msg.sender == owner, "Only the contract owner can distribute");
        require(_amount <= contractBalance, "Insufficient balance");
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < cats.length; i++) {
        totalWeight += cats[i].weight;
        }
        for (uint256 i = 0; i < cats.length; i++) {
        uint256 share = cats[i].weight * _amount / totalWeight;
        payable(cats[i].owner).transfer(share);
        }
        contractBalance -= _amount;
        }
    }




// Explicação:
// 
// - A estrutura `Cat` armazena as informações de cada gato.
// - O array `cats` armazena todos os gatos existentes.
// - O mapeamento `ownerCats` armazena os IDs dos gatos de cada dono.
// - O mapeamento `catIndex` armazena o índice de cada gato no array `cats`.
// - A variável `nextId` armazena o próximo ID a ser usado para um novo gato.
// - A variável `owner` armazena o endereço do proprietário do contrato.
// - A variável `contractBalance` armazena o saldo atual do contrato.
// - O construtor define o proprietário do contrato como o endereço que fez o deploy do contrato.
// - A função `buyCat` permite que um endereço compre um novo gato pagando pelo menos 1 ether. O novo gato é adicionado ao array `cats` e ao mapeamento `ownerCats`.
// - As funções `buyColor` e `buyRarity` permitem que o dono de um gato modifique sua cor e raridade pagando pelo menos 1 ether.
// - A função `buyFood` permite que o dono de um gato compre comida para aumentar seu peso. Cada unidade de comida custa 1 ether.
// - A função `getCatList` retorna uma lista de todos os gatos, ordenados pelo peso de cada gato em ordem decrescente.
// - A função `sortCats` é usada internamente para ordenar a lista de gatos por peso.
// - A função `withdraw` permite que o proprietário do contrato retire uma quantia especificada de ether do saldo do contrato.
// - A função `distribute` permite que o proprietário do contrato distribua uma quantia especificada de ether entre os donos de gatos, com cada dono recebendo uma proporção correspondente ao peso de seu gato.
//