pragma solidity ^0.6.0;
contract casaApuestas{
    address public anfitrion;
    enum Estado {Creada, Registrada, Terminada}
    mapping(uint => Carrera) public carreras; //carreras existentes
    mapping(uint => Caballo) public caballos; //caballos existentes
    uint public totalCarreras;
    mapping(uint => uint[]) public competencias; 

    struct Carrera{
        uint codigo;
        string nombre;
        Estado estadoCarrera;
        mapping(address => Apuesta) apuestas;
    }

    struct Caballo{
        uint codigo;
        string nombre;
    }

    struct Apuesta{
        uint monto;
        uint codCaballo;
    }

    constructor() public{
        anfitrion = msg.sender;
    }

    modifier isAnfitrion(){
        require(msg.sender == anfitrion, "El invocador debe ser el anfitrion");
        _;
    }

    modifier isNotAnfitrion(){
        require(msg.sender != anfitrion, "El invocador debe ser el anfitrion");
        _;
    }

    modifier estadoAct(uint _codCarrera, Estado _estado){
        require(carreras[_codCarrera].estadoCarrera == _estado, "La carrera no cumple con el estado requerido");
        _;
    }
    
    modifier tamanoMax(uint _codCarrera){
        require(competencias[_codCarrera].length < 5, "La carrera ya cuenta con 5 caballos");
        _;
    }

    modifier tamanoMin(uint _codCarrera){
        require(competencias[_codCarrera].length >= 2, "La carrera debe contar con al menos 2 caballos");
        _;
    }

    modifier caballoExiste(uint _codCaballo){
        require(bytes(caballos[_codCaballo].nombre).length != 0, "El caballo ingresado no existe");
        _;
    }

    modifier carreraExiste(uint _codCarrera){
        require(bytes(caballos[_codCarrera].nombre).length != 0, "La carrera ingresada no existe");
        _;
    }
    
    function crearCarrera(uint _codigo, string memory _nombre) public isAnfitrion{
        carreras[_codigo] = Carrera({codigo: _codigo, nombre: _nombre, estadoCarrera: Estado.Creada});
        totalCarreras += 1;
    }

    function registrarCaballo(uint _codigo, string memory _nombre) public isAnfitrion{
        caballos[_codigo] = Caballo(_codigo, _nombre);
    }

    function registrarEnCompetencia(uint _codCaballo, uint _codCarrera) public 
    isAnfitrion
    estadoAct(_codCarrera, Estado.Creada)
    tamanoMax(_codCarrera)
    caballoExiste(_codCaballo)
    carreraExiste(_codCarrera){
        // uint cantCaballos = competencias[_codCarrera].length;
        // for(uint i = 0; i < cantCaballos; i++){
        //     if(competencias[_codCarrera][i] == _codCaballo){
        //         return "Este caballo ya se encuentra registrado en esta carrera";
        //     }
        // }
        competencias[_codCarrera].push(_codCaballo);
        // return "Caballo registrado en la carrera";
    }

    function registrarCarrera(uint _codCarrera) public 
    isAnfitrion
    estadoAct(_codCarrera, Estado.Creada)
    carreraExiste(_codCarrera)
    tamanoMin(_codCarrera){
        carreras[_codCarrera].estadoCarrera = Estado.Registrada;
    }


}